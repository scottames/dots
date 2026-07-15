import { describe, expect, test } from "bun:test";

import { collectGithubReleases } from "./renovate-release-notes-collection.mjs";
import {
  githubUpdate,
  normalizedGithubRelease,
  rawGithubRelease,
} from "./renovate-release-notes-test-fixtures.js";

describe("collectGithubReleases validation and consistency", () => {
  test("treats a missing range bound as unsupported without scanning", async () => {
    let scans = 0;
    const update = { ...githubUpdate("one/repo", "1.3"), fromVersion: null };
    const collection = await collectGithubReleases(
      {
        async get() {
          return rawGithubRelease({ id: 13, tag_name: "1.3" });
        },
        async getReleasePage() {
          scans += 1;
        },
      },
      [update],
    );

    expect(scans).toBe(0);
    expect(collection.results[0].reason).toBe("unsupported-range");
  });

  test("normalizes nullable release text to empty strings", async () => {
    const update = {
      ...githubUpdate("one/repo", "release-1"),
      fromVersion: null,
    };
    const collection = await collectGithubReleases(
      {
        async get() {
          return rawGithubRelease({
            tag_name: "release-1",
            name: null,
            body: null,
          });
        },
      },
      [update],
    );

    expect(collection.results[0].releases[0]).toEqual({
      ...normalizedGithubRelease({ tag_name: "release-1" }),
      name: "",
      body: "",
    });
  });

  test.each([
    ["object", null],
    ["id", rawGithubRelease({ id: undefined })],
    ["tag", rawGithubRelease({ tag_name: "" })],
    ["HTML URL", rawGithubRelease({ html_url: "http://evil.example/release" })],
    ["draft", rawGithubRelease({ draft: "false" })],
    ["prerelease", rawGithubRelease({ prerelease: null })],
    ["publication timestamp", rawGithubRelease({ published_at: "yesterday" })],
    ["ISO publication timestamp", rawGithubRelease({ published_at: "1" })],
    ["name", rawGithubRelease({ name: 123 })],
    ["body", rawGithubRelease({ body: {} })],
  ])("rejects a malformed exact release %s field", async (_field, release) => {
    await expect(
      collectGithubReleases(
        {
          async get() {
            return release;
          },
        },
        [{ ...githubUpdate("one/repo", "release-1"), fromVersion: null }],
      ),
    ).rejects.toThrow(TypeError);
  });

  test("rejects malformed required fields from a list page", async () => {
    await expect(
      collectGithubReleases(
        scanApi(() => ({
          releases: [rawGithubRelease({ id: undefined })],
          link: null,
        })),
        [{ ...githubUpdate("one/repo", "1.3"), fromVersion: "1.0" }],
      ),
    ).rejects.toThrow("malformed GitHub release id");
  });

  test("does not render draft or unpublished exact targets", async () => {
    for (const overrides of [{ draft: true }, { published_at: null }]) {
      const collection = await collectGithubReleases(
        {
          async get() {
            return rawGithubRelease(overrides);
          },
        },
        [{ ...githubUpdate("one/repo", "v2.95.0"), fromVersion: null }],
      );

      expect(collection.results[0].outcome).toBe("unavailable");
      expect(collection.results[0].releases).toEqual([]);
    }
  });

  test("keeps a published explicit prerelease target when its range is unsupported", async () => {
    const update = {
      ...githubUpdate("one/repo", "2.0.0-beta.1"),
      fromVersion: "1.0.0",
    };
    const collection = await collectGithubReleases(
      {
        async get() {
          return rawGithubRelease({
            tag_name: "2.0.0-beta.1",
            prerelease: true,
          });
        },
      },
      [update],
    );

    expect(collection.results[0].outcome).toBe("target-only-found");
    expect(collection.results[0].reason).toBe("unsupported-range");
    expect(collection.results[0].releases).toHaveLength(1);
  });

  test("falls back to the exact target for a range version collision", async () => {
    const update = { ...githubUpdate("one/repo", "1.3"), fromVersion: "1.0" };
    const collection = await collectGithubReleases(
      scanApi(() => ({
        releases: [
          rawGithubRelease({ id: 12, tag_name: "1.2" }),
          rawGithubRelease({ id: 112, tag_name: "v01.002" }),
        ],
        link: null,
      })),
      [update],
    );

    expect(collection.results[0].outcome).toBe("target-only-found");
    expect(collection.results[0].reason).toBe("version-collision");
    expect(
      collection.results[0].releases.map(({ tagName }) => tagName),
    ).toEqual(["1.3"]);
  });

  test("falls back when exact and scanned targets collide by version", async () => {
    const update = { ...githubUpdate("one/repo", "1.3"), fromVersion: "1.0" };
    const api = {
      async get() {
        return rawGithubRelease({ id: 13, tag_name: "1.3" });
      },
      async getReleasePage() {
        return {
          releases: [rawGithubRelease({ id: 113, tag_name: "v01.003" })],
          link: null,
        };
      },
    };

    const collection = await collectGithubReleases(api, [update]);

    expect(collection.results[0].outcome).toBe("target-only-found");
    expect(collection.results[0].reason).toBe("version-collision");
    expect(collection.results[0].releases.map(({ id }) => id)).toEqual([13]);
  });

  test.each([
    ["tag", { tag_name: "v1.3" }],
    ["draft state", { draft: true }],
    ["prerelease state", { prerelease: true }],
    ["publication timestamp", { published_at: "2026-07-02T12:00:00Z" }],
  ])(
    "falls back to the exact target when its scanned %s disagrees",
    async (_field, overrides) => {
      const exact = rawGithubRelease({ id: 13, tag_name: "1.3" });
      const api = {
        async get() {
          return exact;
        },
        async getReleasePage() {
          return {
            releases: [
              rawGithubRelease({ id: 13, tag_name: "1.3", ...overrides }),
              rawGithubRelease({ id: 12, tag_name: "1.2" }),
            ],
            link: null,
          };
        },
      };
      const update = {
        ...githubUpdate("one/repo", "1.3"),
        fromVersion: "1.0",
      };

      const collection = await collectGithubReleases(api, [update]);

      expect(collection.results[0]).toEqual({
        update,
        outcome: "target-only-found",
        reason: "target-consistency-mismatch",
        releases: [normalizedGithubRelease({ id: 13, tag_name: "1.3" })],
      });
    },
  );

  test("falls back to the exact response when the scanned range misses the target", async () => {
    const update = { ...githubUpdate("one/repo", "1.3"), fromVersion: "1.0" };
    const api = {
      async get() {
        return rawGithubRelease({ id: 99, tag_name: "1.3" });
      },
      async getReleasePage() {
        return {
          releases: [rawGithubRelease({ id: 12, tag_name: "1.2" })],
          link: null,
        };
      },
    };

    const collection = await collectGithubReleases(api, [update]);

    expect(collection.results[0].outcome).toBe("target-only-found");
    expect(collection.results[0].reason).toBe("target-missing");
    expect(collection.results[0].releases.map(({ id }) => id)).toEqual([99]);
  });
});

function scanApi(getReleasePage) {
  return {
    async get() {
      return rawGithubRelease({ id: 13, tag_name: "1.3" });
    },
    getReleasePage,
  };
}
