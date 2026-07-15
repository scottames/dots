import { describe, expect, test } from "bun:test";

import {
  formatRunSummary,
  runForPullRequest,
} from "./renovate-release-notes-comment.mjs";
import {
  rawGithubRelease,
  renovateBody,
} from "./renovate-release-notes-test-fixtures.js";

describe("runForPullRequest success paths", () => {
  test("does not write comments or fetch releases for non-Renovate PRs", async () => {
    const calls = [];
    const api = {
      async get(path) {
        calls.push(["get", path]);
        return { user: { login: "octocat" }, body: renovateBody };
      },
      async getAll(path) {
        calls.push(["getAll", path]);
        return [];
      },
      async post(path) {
        calls.push(["post", path]);
      },
      async patch(path) {
        calls.push(["patch", path]);
      },
      async delete(path) {
        calls.push(["delete", path]);
      },
    };

    const result = await runForPullRequest(api, 123);

    expect(result).toEqual({ status: "skipped" });
    expect(calls).toEqual([["get", "/pulls/123"]]);
  });

  test("returns complete package and comment coverage statistics", async () => {
    const bodies = [];
    const api = {
      async get(path) {
        if (path === "/pulls/123") {
          return {
            user: { login: "renovate[bot]" },
            body: `| Package | Update | Change |
|---|---|---|
| [aqua:cli/cli](https://redirect.github.com/cli/cli) | minor | \`1.0.0\` → \`2.0.0\` |
| [aqua:missing/release](https://redirect.github.com/missing/release) | patch | \`1.0.0\` → \`1.0.1\` |
| [aqua:limited/release](https://redirect.github.com/limited/release) | patch | \`1.0.0\` → \`1.0.1\` |
| [crate:serde](https://crates.io/crates/serde) | patch | \`1.0.0\` → \`1.0.1\` |`,
          };
        }
        if (path.includes("/repos/cli/cli/")) {
          return rawGithubRelease({
            tag_name: decodeURIComponent(path.split("/").at(-1)),
          });
        }
        const error = new Error("not found");
        error.status = 404;
        throw error;
      },
      async getAll() {
        return [];
      },
      async post(_path, body) {
        bodies.push(body.body);
      },
      async patch() {},
      async delete() {},
    };

    const result = await runForPullRequest(api, 123, {
      maxCommentChars: 1000,
      maxReleaseRequests: 4,
    });

    expect(result).toEqual({
      status: "updated",
      comments: 1,
      stats: {
        parsedUpdates: 4,
        githubBacked: 3,
        outcomeCounts: {
          "range-found": 0,
          "target-only-found": 1,
          unavailable: 1,
          "request-limited": 1,
          "non-github": 1,
        },
        selectedReleaseEntries: 1,
        continuationSections: 0,
        terminalRepositoryScans: 0,
        releaseRequests: 4,
        commentChars: [expect.any(Number)],
        outcomePackages: {
          "range-found": [],
          "target-only-found": ["aqua:cli/cli"],
          unavailable: ["aqua:missing/release"],
          "request-limited": ["aqua:limited/release"],
          "non-github": ["crate:serde"],
        },
        fallbackReasons: [
          {
            packageName: "aqua:cli/cli",
            reason: "range-request-limit",
          },
        ],
      },
    });
    expect(bodies).toHaveLength(1);
  });

  test("preserves an oversized newline-free release through posted comments", async () => {
    const postedBodies = [];
    const releaseBody = "0123456789".repeat(120);
    const api = {
      async get(path) {
        if (path === "/pulls/123") {
          return {
            user: { login: "renovate[bot]" },
            body: renovateBody,
          };
        }
        return {
          ...rawGithubRelease(),
          body: releaseBody,
          tag_name: decodeURIComponent(path.split("/").at(-1)),
        };
      },
      async getReleasePage() {
        return {
          releases: [
            {
              ...rawGithubRelease(),
              body: releaseBody,
              tag_name: "2.95.0",
            },
          ],
          link: null,
        };
      },
      async getAll() {
        return [];
      },
      async post(_path, body) {
        postedBodies.push(body.body);
      },
      async patch() {},
      async delete() {},
    };

    const result = await runForPullRequest(api, 123, {
      maxCommentChars: 500,
    });
    const packageContents = postedBodies.flatMap((body) =>
      [
        ...body.matchAll(
          /<details>\n<summary>[^\n]+<\/summary>\n\n([\s\S]*?)\n\n<\/details>/g,
        ),
      ].map((match) => match[1]),
    );
    const renderedReleaseBody =
      /\[Compare Source]\([^\n]+\)\n\n([\s\S]*)$/.exec(
        packageContents.join(""),
      )?.[1];

    expect(renderedReleaseBody).toBe(releaseBody);
    expect(postedBodies.every((body) => body.length <= 500)).toBe(true);
    expect(result.stats.continuationSections).toBe(packageContents.length - 1);
    expect(result.stats.selectedReleaseEntries).toBe(1);
    expect(result.stats.terminalRepositoryScans).toBe(1);
    expect(result.stats.releaseRequests).toBe(2);
    expect(result.stats.commentChars).toEqual(
      postedBodies.map((body) => body.length),
    );
  });
});

describe("formatRunSummary", () => {
  test("separates outcome, release, continuation, scan, request, and comment units", () => {
    const summary = formatRunSummary({
      comments: 2,
      stats: {
        parsedUpdates: 5,
        githubBacked: 4,
        outcomeCounts: {
          "range-found": 1,
          "target-only-found": 1,
          unavailable: 1,
          "request-limited": 1,
          "non-github": 1,
        },
        selectedReleaseEntries: 4,
        continuationSections: 2,
        terminalRepositoryScans: 3,
        releaseRequests: 9,
        commentChars: [842, 731],
        outcomePackages: {
          "range-found": ["aqua:sst/opencode"],
          "target-only-found": ["aqua:cli/cli"],
          unavailable: ["aqua:missing/release"],
          "request-limited": ["aqua:limited/release"],
          "non-github": ["crate:serde"],
        },
        fallbackReasons: [
          {
            packageName: "aqua:cli/cli",
            reason: "unsupported-range",
          },
        ],
      },
    });

    expect(summary).toBe(`Renovate release notes summary
Parsed updates: 5 (4 GitHub-backed)
Package outcomes: range-found=1, target-only-found=1, unavailable=1, request-limited=1, non-github=1 (total=5)
Selected release entries: 4
Continuation sections: 2
Terminal repository scans: 3
Actual release requests: 9
Comments: 2 (842, 731 chars)
range-found packages: aqua:sst/opencode
target-only-found packages: aqua:cli/cli
unavailable packages: aqua:missing/release
request-limited packages: aqua:limited/release
non-github packages: crate:serde
Successful fallback reasons: aqua:cli/cli: unsupported-range`);
  });
});
