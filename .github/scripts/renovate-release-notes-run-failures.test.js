import { describe, expect, test } from "bun:test";

import {
  createGitHubApi,
  runForPullRequest,
} from "./renovate-release-notes-comment.mjs";
import {
  rawGithubRelease,
  renovateBody,
} from "./renovate-release-notes-test-fixtures.js";

describe("runForPullRequest failure paths", () => {
  test("rejects 51-comment output before comment writes", async () => {
    const writes = [];
    const rows = Array.from(
      { length: 51 },
      (_, index) =>
        `| [package-${index}](https://redirect.github.com/cli/cli) | patch | \`old-${index}\` → \`release-${index}\` |`,
    ).join("\n");
    let releaseId = 0;
    const api = {
      async get(path) {
        if (path === "/pulls/123") {
          return {
            user: { login: "renovate[bot]" },
            body: `| Package | Update | Change |
|---|---|---|
${rows}`,
          };
        }
        const tag = decodeURIComponent(path.split("/").at(-1));
        releaseId += 1;
        return rawGithubRelease({
          id: releaseId,
          tag_name: tag,
          html_url: `https://github.com/cli/cli/releases/tag/${tag}`,
          body: "x".repeat(60),
        });
      },
      async getAll() {
        return [];
      },
      async post(...args) {
        writes.push(["post", ...args]);
      },
      async patch(...args) {
        writes.push(["patch", ...args]);
      },
      async delete(...args) {
        writes.push(["delete", ...args]);
      },
    };

    await expect(
      runForPullRequest(api, 123, {
        maxCommentChars: 600,
        maxComments: 50,
      }),
    ).rejects.toThrow("release notes require 51 comments, limit is 50");
    expect(writes).toEqual([]);
  });

  test.each([
    [
      "malformed JSON",
      () => new Response("not-json", { status: 200 }),
      SyntaxError,
    ],
    [
      "network failure",
      () => {
        throw new TypeError("network unavailable");
      },
      "network unavailable",
    ],
    ["403", () => new Response("forbidden", { status: 403 }), "failed: 403"],
    ["429", () => new Response("limited", { status: 429 }), "failed: 429"],
    ["5xx", () => new Response("unavailable", { status: 503 }), "failed: 503"],
  ])(
    "propagates %s release failures before comment writes",
    async (_name, fail, expected) => {
      const requests = [];
      const api = createGitHubApi({
        token: "token",
        repository: "owner/repo",
        async fetchImpl(url, init) {
          requests.push([url, init.method]);
          if (url.endsWith("/pulls/123")) {
            return Response.json({
              user: { login: "renovate[bot]" },
              body: renovateBody,
            });
          }
          return fail();
        },
      });

      await expect(runForPullRequest(api, 123)).rejects.toThrow(expected);
      expect(requests.every(([, method]) => method === "GET")).toBe(true);
      expect(requests.some(([url]) => url.includes("/issues/"))).toBe(false);
    },
  );

  test("propagates malformed release fields before comment writes", async () => {
    const writes = [];
    const api = {
      async get(path) {
        if (path === "/pulls/123") {
          return {
            user: { login: "renovate[bot]" },
            body: renovateBody,
          };
        }
        return rawGithubRelease({ published_at: "invalid" });
      },
      async getAll() {
        throw new Error("comment listing must not begin");
      },
      async post(...args) {
        writes.push(args);
      },
      async patch(...args) {
        writes.push(args);
      },
      async delete(...args) {
        writes.push(args);
      },
    };

    await expect(runForPullRequest(api, 123)).rejects.toThrow(
      "malformed GitHub release publication timestamp",
    );
    expect(writes).toEqual([]);
  });

  test("rejects an exact release whose tag differs from the requested candidate before comment writes", async () => {
    const writes = [];
    const api = {
      async get(path) {
        if (path === "/pulls/123") {
          return {
            user: { login: "renovate[bot]" },
            body: renovateBody,
          };
        }
        return rawGithubRelease({ tag_name: "v9.9.9" });
      },
      async getAll() {
        throw new Error("comment listing must not begin");
      },
      async post(...args) {
        writes.push(["post", ...args]);
      },
      async patch(...args) {
        writes.push(["patch", ...args]);
      },
      async delete(...args) {
        writes.push(["delete", ...args]);
      },
    };

    await expect(runForPullRequest(api, 123)).rejects.toThrow(
      "exact GitHub release tag does not match requested tag",
    );
    expect(writes).toEqual([]);
  });

  test("aborts before every comment operation when release page two fails fatally", async () => {
    const scans = [];
    const commentOperations = [];
    const api = {
      async get(path) {
        if (path === "/pulls/123") {
          return {
            user: { login: "renovate[bot]" },
            body: `| Package | Update | Change |
|---|---|---|
| [one/repo](https://redirect.github.com/one/repo) | minor | \`1.0\` → \`1.3\` |`,
          };
        }
        return rawGithubRelease({ id: 13, tag_name: "1.3" });
      },
      async getReleasePage(path) {
        scans.push(path);
        if (path.endsWith("page=1")) {
          return {
            releases: [rawGithubRelease({ id: 13, tag_name: "1.3" })],
            link: '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next"',
          };
        }
        const error = new Error("release page unavailable");
        error.status = 503;
        throw error;
      },
      async getAll(...args) {
        commentOperations.push(["getAll", ...args]);
        return [];
      },
      async post(...args) {
        commentOperations.push(["post", ...args]);
      },
      async patch(...args) {
        commentOperations.push(["patch", ...args]);
      },
      async delete(...args) {
        commentOperations.push(["delete", ...args]);
      },
    };

    await expect(runForPullRequest(api, 123)).rejects.toThrow(
      "release page unavailable",
    );
    expect(scans).toEqual([
      "/repos/one/repo/releases?per_page=100&page=1",
      "/repos/one/repo/releases?per_page=100&page=2",
    ]);
    expect(commentOperations).toEqual([]);
  });
});
