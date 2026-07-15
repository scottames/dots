import { describe, expect, test } from "bun:test";

import { collectGithubReleases } from "./renovate-release-notes-collection.mjs";
import { parseRenovateUpdates } from "./renovate-release-notes-lib.mjs";
import {
  githubUpdate,
  normalizedGithubRelease,
  rawGithubRelease,
  renovateBody,
} from "./renovate-release-notes-test-fixtures.js";

describe("collectGithubReleases exact targets and request budget", () => {
  test("tries the supplied exact tag before its distinct lowercase-v alternate", async () => {
    const paths = [];
    const api = {
      async get(path) {
        paths.push(path);
        if (path.endsWith("/2.95.0")) {
          throw notFound();
        }
        return rawGithubRelease();
      },
    };
    const update = parseRenovateUpdates(renovateBody)[0];
    update.fromVersion = null;

    const collection = await collectGithubReleases(api, [update]);

    expect(paths).toEqual([
      "/repos/cli/cli/releases/tags/2.95.0",
      "/repos/cli/cli/releases/tags/v2.95.0",
    ]);
    expect(collection.releaseRequests).toBe(2);
    expect(collection.terminalRepositoryScans).toBe(0);
    expect(collection.results).toEqual([
      {
        update,
        outcome: "target-only-found",
        reason: "unsupported-range",
        releases: [normalizedGithubRelease()],
      },
    ]);
  });

  test("reports request-limited when one request remains after the first exact 404", async () => {
    const paths = [];
    const api = {
      async get(path) {
        paths.push(path);
        throw notFound();
      },
    };
    const update = githubUpdate("one/repo", "1.0.0");

    const collection = await collectGithubReleases(api, [update], {
      maxReleaseRequests: 1,
    });

    expect(paths).toEqual(["/repos/one/repo/releases/tags/1.0.0"]);
    expect(collection.releaseRequests).toBe(1);
    expect(collection.results).toEqual([
      {
        update,
        outcome: "request-limited",
        reason: "exact-request-limit",
        releases: [],
      },
    ]);
  });

  test("resolves all exact targets before stopping without starting a scan", async () => {
    const paths = [];
    const api = {
      async get(path) {
        paths.push(path);
        return rawGithubRelease({
          id: paths.length,
          tag_name: path.split("/").at(-1),
        });
      },
      async getReleasePage() {
        throw new Error("range scan must not begin");
      },
    };
    const updates = [
      githubUpdate("one/repo", "1.0.0"),
      githubUpdate("two/repo", "2.0.0"),
      githubUpdate("three/repo", "3.0.0"),
    ];

    const collection = await collectGithubReleases(api, updates, {
      maxReleaseRequests: 2,
    });

    expect(paths).toEqual([
      "/repos/one/repo/releases/tags/1.0.0",
      "/repos/two/repo/releases/tags/2.0.0",
    ]);
    expect(collection.terminalRepositoryScans).toBe(0);
    expect(collection.results.map(({ outcome }) => outcome)).toEqual([
      "target-only-found",
      "target-only-found",
      "request-limited",
    ]);
    expect(collection.results.map(({ reason }) => reason)).toEqual([
      "range-request-limit",
      "range-request-limit",
      "exact-request-limit",
    ]);
  });

  test("caches exact successes and 404s separately by repository and tag", async () => {
    const paths = [];
    const api = {
      async get(path) {
        paths.push(path);
        if (path.includes("missing/repo")) {
          throw notFound();
        }
        return rawGithubRelease({ tag_name: "release-1" });
      },
    };
    const updates = [
      { ...githubUpdate("one/repo", "release-1"), fromVersion: null },
      { ...githubUpdate("one/repo", "release-1"), fromVersion: null },
      { ...githubUpdate("missing/repo", "release-2"), fromVersion: null },
      { ...githubUpdate("missing/repo", "release-2"), fromVersion: null },
    ];

    const collection = await collectGithubReleases(api, updates);

    expect(paths).toEqual([
      "/repos/one/repo/releases/tags/release-1",
      "/repos/missing/repo/releases/tags/release-2",
      "/repos/missing/repo/releases/tags/vrelease-2",
    ]);
    expect(collection.releaseRequests).toBe(3);
    expect(collection.results.map(({ outcome }) => outcome)).toEqual([
      "target-only-found",
      "target-only-found",
      "unavailable",
      "unavailable",
    ]);
  });

  test("reports request-limited when a cached alternate has an unverified preferred tag", async () => {
    const paths = [];
    const api = {
      async get(path) {
        paths.push(path);
        return rawGithubRelease({
          tag_name: decodeURIComponent(path.split("/").at(-1)),
        });
      },
    };
    const updates = [
      { ...githubUpdate("one/repo", "v1.0"), fromVersion: null },
      { ...githubUpdate("one/repo", "1.0"), fromVersion: null },
    ];

    const collection = await collectGithubReleases(api, updates, {
      maxReleaseRequests: 1,
    });

    expect(paths).toEqual(["/repos/one/repo/releases/tags/v1.0"]);
    expect(collection.releaseRequests).toBe(1);
    expect(collection.results.map(({ outcome }) => outcome)).toEqual([
      "target-only-found",
      "request-limited",
    ]);
    expect(collection.results[1].reason).toBe("exact-request-limit");
    expect(collection.results[1].releases).toEqual([]);
  });

  test("uses a cached alternate after the preferred tag has a cached 404", async () => {
    const paths = [];
    const api = {
      async get(path) {
        paths.push(path);
        if (path.endsWith("/1.0")) {
          throw notFound();
        }
        return rawGithubRelease({ tag_name: "v1.0" });
      },
    };
    const updates = [
      { ...githubUpdate("one/repo", "1.0"), fromVersion: null },
      { ...githubUpdate("one/repo", "1.0"), fromVersion: null },
    ];

    const collection = await collectGithubReleases(api, updates, {
      maxReleaseRequests: 2,
    });

    expect(paths).toEqual([
      "/repos/one/repo/releases/tags/1.0",
      "/repos/one/repo/releases/tags/v1.0",
    ]);
    expect(collection.releaseRequests).toBe(2);
    expect(collection.results.map(({ outcome }) => outcome)).toEqual([
      "target-only-found",
      "target-only-found",
    ]);
    expect(collection.results[1].releases[0].tagName).toBe("v1.0");
  });

  test("does not spend release requests for non-GitHub rows", async () => {
    const update = {
      ...githubUpdate(null, "1.0.0"),
      skipReason: "non-github-source",
    };

    const collection = await collectGithubReleases({}, [update]);

    expect(collection.releaseRequests).toBe(0);
    expect(collection.results).toEqual([
      {
        update,
        outcome: "non-github",
        reason: "non-github-source",
        releases: [],
      },
    ]);
  });

  test("defaults a boolean maxReleaseRequests option instead of coercing it", async () => {
    const paths = [];
    const update = { ...githubUpdate("one/repo", "1.0"), fromVersion: null };
    const collection = await collectGithubReleases(
      {
        async get(path) {
          paths.push(path);
          if (path.endsWith("/1.0")) {
            throw notFound();
          }
          return rawGithubRelease({ tag_name: "v1.0" });
        },
      },
      [update],
      { maxReleaseRequests: true },
    );

    expect(paths).toEqual([
      "/repos/one/repo/releases/tags/1.0",
      "/repos/one/repo/releases/tags/v1.0",
    ]);
    expect(collection.results[0].outcome).toBe("target-only-found");
  });
});

function notFound() {
  const error = new Error("not found");
  error.status = 404;
  return error;
}
