import { describe, expect, test } from "bun:test";

import { collectGithubReleases } from "./renovate-release-notes-collection.mjs";
import {
  githubUpdate,
  normalizedGithubRelease,
  rawGithubRelease,
} from "./renovate-release-notes-test-fixtures.js";

describe("collectGithubReleases range and repository scheduling", () => {
  test("selects a complete two-page range in descending order", async () => {
    const paths = [];
    const target = rawGithubRelease({ id: 13, tag_name: "1.3" });
    const unrelated = Array.from({ length: 98 }, (_, index) =>
      rawGithubRelease({ id: 1000 + index, tag_name: `9.${index}` }),
    );
    const api = {
      async get(path) {
        paths.push(path);
        return target;
      },
      async getReleasePage(path) {
        paths.push(path);
        if (path.endsWith("page=1")) {
          return {
            releases: [
              rawGithubRelease({ id: 12, tag_name: "1.2" }),
              ...unrelated,
              target,
            ],
            link: '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next"',
          };
        }
        return {
          releases: [rawGithubRelease({ id: 11, tag_name: "1.1" })],
          link: null,
        };
      },
    };
    const update = {
      ...githubUpdate("one/repo", "1.3"),
      fromVersion: "1.0",
    };

    const collection = await collectGithubReleases(api, [update]);

    expect(paths).toEqual([
      "/repos/one/repo/releases/tags/1.3",
      "/repos/one/repo/releases?per_page=100&page=1",
      "/repos/one/repo/releases?per_page=100&page=2",
    ]);
    expect(collection.releaseRequests).toBe(3);
    expect(collection.terminalRepositoryScans).toBe(1);
    expect(collection.results[0]).toEqual({
      update,
      outcome: "range-found",
      reason: null,
      releases: [13, 12, 11].map((id) =>
        normalizedGithubRelease({ id, tag_name: `1.${id - 10}` }),
      ),
    });
    expect(
      collection.results[0].releases.map(({ tagName }) => tagName),
    ).toEqual(["1.3", "1.2", "1.1"]);
  });

  test("reuses one terminal scan for overlapping rows in the same repository", async () => {
    const scans = [];
    const api = {
      async get(path) {
        const tag = path.split("/").at(-1);
        return rawGithubRelease({
          id: 10 + Number(tag.replace("1.", "")),
          tag_name: tag,
        });
      },
      async getReleasePage(path) {
        scans.push(path);
        return {
          releases: [
            rawGithubRelease({ id: 13, tag_name: "1.3" }),
            rawGithubRelease({ id: 12, tag_name: "1.2" }),
            rawGithubRelease({ id: 11, tag_name: "1.1" }),
          ],
          link: null,
        };
      },
    };
    const updates = [
      { ...githubUpdate("one/repo", "1.3"), fromVersion: "1.0" },
      { ...githubUpdate("one/repo", "1.2"), fromVersion: "1.1" },
    ];

    const collection = await collectGithubReleases(api, updates);

    expect(scans).toEqual(["/repos/one/repo/releases?per_page=100&page=1"]);
    expect(collection.terminalRepositoryScans).toBe(1);
    expect(collection.results.map(({ outcome }) => outcome)).toEqual([
      "range-found",
      "range-found",
    ]);
    expect(
      collection.results.map(({ releases }) =>
        releases.map(({ tagName }) => tagName),
      ),
    ).toEqual([["1.3", "1.2", "1.1"], ["1.2"]]);
  });

  test("scans repositories in first table appearance order after exact targets", async () => {
    const paths = [];
    const api = {
      async get(path) {
        paths.push(path);
        const tag = path.split("/").at(-1);
        return rawGithubRelease({ id: tag === "1.1" ? 11 : 22, tag_name: tag });
      },
      async getReleasePage(path) {
        paths.push(path);
        const first = path.includes("/first/repo/");
        return {
          releases: [
            rawGithubRelease({
              id: first ? 11 : 22,
              tag_name: first ? "1.1" : "2.2",
            }),
          ],
          link: null,
        };
      },
    };
    const updates = [
      { ...githubUpdate("first/repo", "1.1"), fromVersion: "1.0" },
      { ...githubUpdate("second/repo", "2.2"), fromVersion: "2.1" },
    ];

    await collectGithubReleases(api, updates);

    expect(paths).toEqual([
      "/repos/first/repo/releases/tags/1.1",
      "/repos/second/repo/releases/tags/2.2",
      "/repos/first/repo/releases?per_page=100&page=1",
      "/repos/second/repo/releases?per_page=100&page=1",
    ]);
  });

  test("caches a terminal list 404 fallback for every row in the repository", async () => {
    let scans = 0;
    const api = {
      async get(path) {
        const tag = path.split("/").at(-1);
        return rawGithubRelease({ id: tag === "1.3" ? 13 : 12, tag_name: tag });
      },
      async getReleasePage() {
        scans += 1;
        const error = new Error("not found");
        error.status = 404;
        throw error;
      },
    };
    const updates = [
      { ...githubUpdate("one/repo", "1.3"), fromVersion: "1.0" },
      { ...githubUpdate("one/repo", "1.2"), fromVersion: "1.0" },
    ];

    const collection = await collectGithubReleases(api, updates);

    expect(scans).toBe(1);
    expect(collection.terminalRepositoryScans).toBe(1);
    expect(collection.results.map(({ reason }) => reason)).toEqual([
      "list-not-found",
      "list-not-found",
    ]);
    expect(
      collection.results.every(({ releases }) => releases.length === 1),
    ).toBe(true);
  });

  test("reuses one repeated-ID scan fallback for every row in the repository", async () => {
    const scans = [];
    const repeated = rawGithubRelease({ id: 11, tag_name: "1.1" });
    const api = {
      async get(path) {
        const tag = decodeURIComponent(path.split("/").at(-1));
        return rawGithubRelease({
          id: tag === "1.3" ? 13 : 12,
          tag_name: tag,
        });
      },
      async getReleasePage(path) {
        scans.push(path);
        return path.endsWith("page=1")
          ? {
              releases: [
                rawGithubRelease({ id: 13, tag_name: "1.3" }),
                repeated,
              ],
              link: '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next"',
            }
          : { releases: [repeated], link: null };
      },
    };
    const updates = [
      { ...githubUpdate("one/repo", "1.3"), fromVersion: "1.0" },
      { ...githubUpdate("one/repo", "1.2"), fromVersion: "1.0" },
    ];

    const collection = await collectGithubReleases(api, updates);

    expect(scans).toEqual([
      "/repos/one/repo/releases?per_page=100&page=1",
      "/repos/one/repo/releases?per_page=100&page=2",
    ]);
    expect(collection.terminalRepositoryScans).toBe(1);
    expect(collection.results.map(({ reason }) => reason)).toEqual([
      "repeated-release-id",
      "repeated-release-id",
    ]);
    expect(
      collection.results.map(({ releases }) => releases.map(({ id }) => id)),
    ).toEqual([[13], [12]]);
  });
});
