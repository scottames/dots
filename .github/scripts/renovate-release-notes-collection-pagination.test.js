import { describe, expect, test } from "bun:test";

import { collectGithubReleases } from "./renovate-release-notes-collection.mjs";
import {
  githubUpdate,
  normalizedGithubRelease,
  rawGithubRelease,
} from "./renovate-release-notes-test-fixtures.js";

describe("collectGithubReleases pagination", () => {
  test("follows a valid next link from a short page and accepts terminal relations", async () => {
    const scans = [];
    const collection = await collectPages((path) => {
      scans.push(path);
      return path.endsWith("page=1")
        ? {
            releases: [rawGithubRelease({ id: 13, tag_name: "1.3" })],
            link: '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next", <https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="last"',
          }
        : {
            releases: [rawGithubRelease({ id: 12, tag_name: "1.2" })],
            link: '<https://api.github.com/repos/one/repo/releases?per_page=100&page=1>; rel="prev", <https://api.github.com/repos/one/repo/releases?per_page=100&page=1>; rel="first"',
          };
    });
    const result = collection.results[0];
    expect(scans).toEqual([
      "/repos/one/repo/releases?per_page=100&page=1",
      "/repos/one/repo/releases?per_page=100&page=2",
    ]);
    expect(result.outcome).toBe("range-found");
    expect(result.reason).toBeNull();
    expect(result.releases.map(({ id }) => id)).toEqual([13, 12]);
  });

  test("falls back when terminal relations claim a later last page", async () => {
    const update = { ...githubUpdate("one/repo", "1.3"), fromVersion: "1.0" };
    const collection = await collectPages(
      () => ({
        releases: [rawGithubRelease({ id: 13, tag_name: "1.3" })],
        link: '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="last"',
      }),
      update,
    );
    expect(collection.results[0]).toEqual({
      update,
      outcome: "target-only-found",
      reason: "invalid-next-link",
      releases: [normalizedGithubRelease({ id: 13, tag_name: "1.3" })],
    });
  });

  test("falls back when a next link skips the sequential page", async () => {
    const collection = await collectPages(() => ({
      releases: [rawGithubRelease({ id: 13, tag_name: "1.3" })],
      link: '<https://api.github.com/repos/one/repo/releases?per_page=100&page=3>; rel="next"',
    }));
    expect(collection.results[0]).toEqual({
      update: expect.any(Object),
      outcome: "target-only-found",
      reason: "invalid-next-link",
      releases: [normalizedGithubRelease({ id: 13, tag_name: "1.3" })],
    });
  });

  test("accepts a terminal header without last when it reaches a previously declared last page", async () => {
    let page = 0;
    const collection = await collectPages(() => {
      page += 1;
      return page === 1
        ? {
            releases: fullReleasePage(1),
            link: '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next", <https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="last"',
          }
        : {
            releases: [rawGithubRelease({ id: 13, tag_name: "1.3" })],
            link: '<https://api.github.com/repos/one/repo/releases?per_page=100&page=1>; rel="prev", <https://api.github.com/repos/one/repo/releases?per_page=100&page=1>; rel="first"',
          };
    });
    expect(collection.results[0].reason).toBeNull();
  });

  test("falls back when Link headers contradict a declared last page", async () => {
    let page = 0;
    const collection = await collectPages(() => {
      page += 1;
      return page === 1
        ? {
            releases: fullReleasePage(1),
            link: '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next", <https://api.github.com/repos/one/repo/releases?per_page=100&page=3>; rel="last"',
          }
        : {
            releases: fullReleasePage(2),
            link: '<https://api.github.com/repos/one/repo/releases?per_page=100&page=3>; rel="next", <https://api.github.com/repos/one/repo/releases?per_page=100&page=4>; rel="last"',
          };
    });
    expect(page).toBe(2);
    expect(collection.results[0].reason).toBe("invalid-next-link");
  });

  test.each([
    [
      "a header without next or last",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=1>; rel="prev", <https://api.github.com/repos/one/repo/releases?per_page=100&page=1>; rel="first"',
    ],
    ["a null Link header", null],
  ])(
    "falls back before a declared last page on %s",
    async (_name, terminalLink) => {
      let page = 0;
      const collection = await collectPages(() => {
        page += 1;
        return page === 1
          ? {
              releases: fullReleasePage(1),
              link: '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next", <https://api.github.com/repos/one/repo/releases?per_page=100&page=3>; rel="last"',
            }
          : {
              releases: [rawGithubRelease({ id: 13, tag_name: "1.3" })],
              link: terminalLink,
            };
      });
      expect(page).toBe(2);
      expect(collection.results[0].reason).toBe("invalid-next-link");
    },
  );

  test("retains only the complete exact target when the range budget is exhausted", async () => {
    const target = rawGithubRelease({ id: 13, tag_name: "1.3" });
    const scans = [];
    const api = {
      async get() {
        return target;
      },
      async getReleasePage(path) {
        scans.push(path);
        return {
          releases: fullReleasePage(1, [
            rawGithubRelease({ id: 12, tag_name: "1.2" }),
          ]),
          link: '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next"',
        };
      },
    };
    const update = { ...githubUpdate("one/repo", "1.3"), fromVersion: "1.0" };
    const collection = await collectGithubReleases(api, [update], {
      maxReleaseRequests: 2,
    });
    expect(scans).toHaveLength(1);
    expect(collection.releaseRequests).toBe(2);
    expect(collection.results[0]).toEqual({
      update,
      outcome: "target-only-found",
      reason: "range-request-limit",
      releases: [normalizedGithubRelease({ id: 13, tag_name: "1.3" })],
    });
  });

  test("falls back after the private 20-page repository cap", async () => {
    let scans = 0;
    const api = {
      async get() {
        return rawGithubRelease({ id: 13, tag_name: "1.3" });
      },
      async getReleasePage() {
        scans += 1;
        return {
          releases: fullReleasePage(scans),
          link: `<https://api.github.com/repos/one/repo/releases?per_page=100&page=${scans + 1}>; rel="next"`,
        };
      },
    };
    const update = { ...githubUpdate("one/repo", "1.3"), fromVersion: "1.0" };
    const collection = await collectGithubReleases(api, [update]);
    expect(scans).toBe(20);
    expect(collection.results[0].outcome).toBe("target-only-found");
    expect(collection.results[0].reason).toBe("page-cap");
    expect(collection.results[0].releases).toHaveLength(1);
  });

  test("falls back for a repeated page without retrying it", async () => {
    let scans = 0;
    const collection = await collectPages(() => {
      scans += 1;
      return {
        releases: fullReleasePage(1),
        link: '<https://api.github.com/repos/one/repo/releases?per_page=100&page=1>; rel="next"',
      };
    });
    expect(scans).toBe(1);
    expect(collection.results[0].reason).toBe("repeated-page");
  });

  test("falls back for a release ID repeated across pages", async () => {
    let page = 0;
    const repeated = rawGithubRelease({ id: 1200, tag_name: "1.2" });
    const collection = await collectPages(() => {
      page += 1;
      return page === 1
        ? {
            releases: fullReleasePage(1, [repeated]),
            link: '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next"',
          }
        : { releases: [repeated], link: null };
    });
    const result = collection.results[0];
    expect(result.reason).toBe("repeated-release-id");
    expect(result.releases.map(({ tagName }) => tagName)).toEqual(["1.3"]);
  });

  test.each([
    ["malformed", "not a link"],
    [
      "off-origin",
      '<https://evil.example/repos/one/repo/releases?per_page=100&page=2>; rel="next"',
    ],
    [
      "non-increasing",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=0>; rel="next"',
    ],
    [
      "duplicate-page",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2&page=3>; rel="next"',
    ],
    [
      "duplicate-per-page",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&per_page=50&page=2>; rel="next"',
    ],
  ])("falls back for a %s next link", async (_name, link) => {
    const collection = await collectPages(() => ({
      releases: fullReleasePage(1),
      link,
    }));
    expect(collection.results[0].reason).toBe("invalid-next-link");
  });

  test.each([
    ["empty", "", "invalid-next-link"],
    ["malformed", "not a link", "invalid-next-link"],
    [
      "off-origin",
      '<https://evil.example/repos/one/repo/releases?per_page=100&page=2>; rel="next"',
      "invalid-next-link",
    ],
    [
      "wrong-endpoint",
      '<https://api.github.com/repos/one/repo/issues?per_page=100&page=2>; rel="next"',
      "invalid-next-link",
    ],
    [
      "wrong-per-page",
      '<https://api.github.com/repos/one/repo/releases?per_page=50&page=2>; rel="next"',
      "invalid-next-link",
    ],
    [
      "extra-query-parameter",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2&after=cursor>; rel="next"',
      "invalid-next-link",
    ],
    [
      "non-increasing",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=1>; rel="next"',
      "repeated-page",
    ],
  ])(
    "falls back for a present %s next link on a short page",
    async (_name, link, reason = "invalid-next-link") => {
      const collection = await collectPages(() => ({
        releases: [rawGithubRelease({ id: 13, tag_name: "1.3" })],
        link,
      }));
      expect(collection.results[0].outcome).toBe("target-only-found");
      expect(collection.results[0].reason).toBe(reason);
      expect(collection.results[0].releases.map(({ id }) => id)).toEqual([13]);
    },
  );
});

function fullReleasePage(page, releases = []) {
  return [
    ...releases,
    ...Array.from({ length: 100 - releases.length }, (_, index) =>
      rawGithubRelease({
        id: page * 10000 + index,
        tag_name: `9.${page}.${index}`,
      }),
    ),
  ];
}
function scanApi(getReleasePage) {
  return {
    async get() {
      return rawGithubRelease({ id: 13, tag_name: "1.3" });
    },
    getReleasePage,
  };
}
function collectPages(getReleasePage, update) {
  update ??= { ...githubUpdate("one/repo", "1.3"), fromVersion: "1.0" };
  return collectGithubReleases(scanApi(getReleasePage), [update]);
}
