import { expect, test } from "bun:test";

import { collectGithubReleases } from "./renovate-release-notes-collection.mjs";
import {
  githubUpdate,
  rawGithubRelease,
} from "./renovate-release-notes-test-fixtures.js";

test("falls back when the numeric repository path changes across pages", async () => {
  const target = rawGithubRelease({ id: 13, tag_name: "1.3" });
  let page = 0;
  const api = {
    async get() {
      return target;
    },
    async getReleasePage() {
      page += 1;
      return page === 1
        ? {
            releases: Array.from({ length: 100 }, (_, index) =>
              rawGithubRelease({
                id: 10000 + index,
                tag_name: `9.1.${index}`,
              }),
            ),
            link: '<https://api.github.com/repositories/975734319/releases?per_page=100&page=2>; rel="next", <https://api.github.com/repositories/975734319/releases?per_page=100&page=2>; rel="last"',
          }
        : {
            releases: [target],
            link: '<https://api.github.com/repositories/1078528927/releases?per_page=100&page=1>; rel="prev", <https://api.github.com/repositories/1078528927/releases?per_page=100&page=1>; rel="first"',
          };
    },
  };
  const update = { ...githubUpdate("one/repo", "1.3"), fromVersion: "1.0" };

  const collection = await collectGithubReleases(api, [update]);

  expect(page).toBe(2);
  expect(collection.results[0].reason).toBe("invalid-next-link");
});

test("collects a range across canonical numeric repository pages", async () => {
  const target = rawGithubRelease({ id: 13, tag_name: "1.3" });
  const intermediate = rawGithubRelease({ id: 12, tag_name: "1.2" });
  let page = 0;
  const api = {
    async get() {
      return target;
    },
    async getReleasePage() {
      page += 1;
      return page === 1
        ? {
            releases: Array.from({ length: 100 }, (_, index) =>
              rawGithubRelease({
                id: 10000 + index,
                tag_name: `9.1.${index}`,
              }),
            ),
            link: '<https://api.github.com/repositories/975734319/releases?per_page=100&page=2>; rel="next", <https://api.github.com/repositories/975734319/releases?per_page=100&page=2>; rel="last"',
          }
        : {
            releases: [target, intermediate],
            link: '<https://api.github.com/repositories/975734319/releases?per_page=100&page=1>; rel="prev", <https://api.github.com/repositories/975734319/releases?per_page=100&page=1>; rel="first"',
          };
    },
  };
  const update = { ...githubUpdate("one/repo", "1.3"), fromVersion: "1.0" };

  const collection = await collectGithubReleases(api, [update]);

  expect(page).toBe(2);
  expect(collection.results[0].outcome).toBe("range-found");
  expect(collection.results[0].releases.map(({ tagName }) => tagName)).toEqual([
    "1.3",
    "1.2",
  ]);
});
