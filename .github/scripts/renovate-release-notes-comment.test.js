import { describe, expect, test } from "bun:test";

import {
  collectGithubReleases,
  createGitHubApi,
  formatRunSummary,
  isRenovatePullRequest,
  parseRenovateUpdates,
  runForPullRequest,
  upsertCommentBodies,
} from "./renovate-release-notes-comment.mjs";

const renovateBody = `This PR contains the following updates:

| Package | Update | Change |
|---|---|---|
| [aqua:cli/cli](https://redirect.github.com/cli/cli) | minor | \`2.94.0\` → \`2.95.0\` |
`;

describe("collectGithubReleases", () => {
  test("fetches releases from the updated package repository", async () => {
    const paths = [];
    const releases = await collectGithubReleases(
      apiWithReleasePaths(paths),
      parseRenovateUpdates(renovateBody),
    );

    expect(paths).toEqual(["/repos/cli/cli/releases/tags/2.95.0"]);
    expect(releases.get("cli/cli@2.95.0").tagName).toBe("v2.95.0");
  });

  test("rejects malformed release responses", async () => {
    const api = {
      async get() {
        return null;
      },
    };

    await expect(
      collectGithubReleases(api, [githubUpdate("one/repo", "1.0.0")]),
    ).rejects.toThrow(TypeError);
  });

  test("rejects malformed JSON release responses", async () => {
    const api = createGitHubApi({
      token: "token",
      repository: "owner/repo",
      async fetchImpl() {
        return new Response("not-json", { status: 200 });
      },
    });

    await expect(
      collectGithubReleases(api, [githubUpdate("one/repo", "1.0.0")]),
    ).rejects.toThrow(SyntaxError);
  });

  test("falls back to v-prefixed release tags after a 404", async () => {
    const paths = [];
    const api = {
      async get(path) {
        paths.push(path);
        if (path.endsWith("/2.95.0")) {
          const error = new Error("not found");
          error.status = 404;
          throw error;
        }
        return githubRelease();
      },
    };

    const releases = await collectGithubReleases(
      api,
      parseRenovateUpdates(renovateBody),
    );

    expect(paths).toEqual([
      "/repos/cli/cli/releases/tags/2.95.0",
      "/repos/cli/cli/releases/tags/v2.95.0",
    ]);
    expect(releases.get("cli/cli@2.95.0").tagName).toBe("v2.95.0");
  });

  test("aborts collection after a non-404 release lookup error", async () => {
    const paths = [];
    const api = {
      async get(path) {
        paths.push(path);
        if (path.includes("/repos/one/repo/")) {
          const error = new Error("service unavailable");
          error.status = 503;
          throw error;
        }
        return githubRelease();
      },
    };

    await expect(
      collectGithubReleases(api, [
        githubUpdate("one/repo", "1.0.0"),
        githubUpdate("two/repo", "2.0.0"),
      ]),
    ).rejects.toThrow("service unavailable");
    expect(paths).toEqual(["/repos/one/repo/releases/tags/1.0.0"]);
  });

  test("aborts collection after a statusless release lookup error", async () => {
    const api = {
      async get() {
        throw new TypeError("network unavailable");
      },
    };

    await expect(
      collectGithubReleases(api, [githubUpdate("one/repo", "1.0.0")]),
    ).rejects.toThrow("network unavailable");
  });

  test("deduplicates release lookups and marks updates beyond the lookup cap", async () => {
    const paths = [];
    const updates = [
      githubUpdate("one/repo", "1.0.0"),
      githubUpdate("one/repo", "1.0.0"),
      githubUpdate("two/repo", "2.0.0"),
      githubUpdate("two/repo", "2.0.0"),
    ];

    await collectGithubReleases(apiWithReleasePaths(paths), updates, {
      maxReleaseLookups: 1,
    });

    expect(paths).toHaveLength(1);
    expect(updates[2].skipReason).toBe("github-release-lookup-limit");
    expect(updates[3].skipReason).toBe("github-release-lookup-limit");
  });
});

describe("isRenovatePullRequest", () => {
  test("accepts Renovate bot identities only", () => {
    expect(isRenovatePullRequest({ user: { login: "app/renovate" } })).toBe(
      true,
    );
    expect(isRenovatePullRequest({ user: { login: "renovate[bot]" } })).toBe(
      true,
    );
    expect(
      isRenovatePullRequest({
        user: { login: "octocat" },
        head: { ref: "renovate/spoofed" },
      }),
    ).toBe(false);
  });
});

describe("upsertCommentBodies", () => {
  test("ignores marker comments not authored by github-actions bot", async () => {
    const calls = [];
    const api = apiWithComments(calls, [
      {
        id: 1,
        body: "<!-- renovate-release-notes-comment:v1 part=1 total=1 -->\nold",
        user: { login: "octocat" },
      },
    ]);

    await upsertCommentBodies(api, 123, ["new body"]);

    expect(calls).toEqual([
      ["post", "/issues/123/comments", { body: "new body" }],
    ]);
  });

  test("updates changed owned comments and leaves identical owned comments alone", async () => {
    const calls = [];
    const api = apiWithComments(calls, [
      ownedComment(1, 1, 2, "old body"),
      ownedComment(2, 2, 2, "body two"),
    ]);

    await upsertCommentBodies(api, 123, [
      "<!-- renovate-release-notes-comment:v1 part=1 total=2 -->\nnew body",
      "<!-- renovate-release-notes-comment:v1 part=2 total=2 -->\nbody two",
    ]);

    expect(calls).toEqual([
      [
        "patch",
        "/issues/comments/1",
        {
          body: "<!-- renovate-release-notes-comment:v1 part=1 total=2 -->\nnew body",
        },
      ],
    ]);
  });

  test("creates missing owned parts and deletes stale owned extra parts", async () => {
    const calls = [];
    const api = apiWithComments(calls, [ownedComment(3, 3, 3, "stale")]);

    await upsertCommentBodies(api, 123, [
      "<!-- renovate-release-notes-comment:v1 part=1 total=2 -->\none",
      "<!-- renovate-release-notes-comment:v1 part=2 total=2 -->\ntwo",
    ]);

    expect(calls).toEqual([
      ["post", "/issues/123/comments", { body: markerBody(1, 2, "one") }],
      ["post", "/issues/123/comments", { body: markerBody(2, 2, "two") }],
      ["delete", "/issues/comments/3"],
    ]);
  });

  test("rejects excessive comment mutations before the first write", async () => {
    const calls = [];
    const comments = Array.from({ length: 51 }, (_, index) =>
      ownedComment(index + 1, index + 1, 51, "old"),
    );
    const api = apiWithComments(calls, comments);

    await expect(
      upsertCommentBodies(api, 123, [markerBody(1, 1, "new")], {
        maxMutations: 50,
      }),
    ).rejects.toThrow("comment update requires 51 mutations, limit is 50");
    expect(calls).toEqual([]);
  });
});

describe("createGitHubApi", () => {
  test("follows paginated comment responses", async () => {
    const requested = [];
    const api = createGitHubApi({
      token: "token",
      repository: "owner/repo",
      async fetchImpl(url) {
        requested.push(url);
        const isFirst = !url.includes("page=2");
        return new Response(
          JSON.stringify(isFirst ? [{ id: 1 }] : [{ id: 2 }]),
          {
            status: 200,
            headers: isFirst
              ? {
                  link: '<https://api.github.com/repos/owner/repo/issues/1/comments?page=2>; rel="next"',
                }
              : {},
          },
        );
      },
    });

    const comments = await api.getAll("/issues/1/comments", { per_page: 100 });

    expect(comments).toEqual([{ id: 1 }, { id: 2 }]);
    expect(requested).toHaveLength(2);
  });
});

describe("runForPullRequest", () => {
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
          return githubRelease();
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
      maxReleaseLookups: 2,
    });

    expect(result).toEqual({
      status: "updated",
      comments: 1,
      stats: {
        parsedUpdates: 4,
        githubBacked: 3,
        releasesFound: 1,
        nonGithub: 1,
        unavailable: 1,
        lookupLimited: 1,
        releaseSectionsSplit: 0,
        commentChars: [expect.any(Number)],
        foundPackages: ["aqua:cli/cli"],
        nonGithubPackages: ["crate:serde"],
        unavailablePackages: ["aqua:missing/release"],
        lookupLimitedPackages: ["aqua:limited/release"],
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
          ...githubRelease(),
          body: releaseBody,
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
    const releaseParts = postedBodies.flatMap((body) =>
      [
        ...body.matchAll(
          /\[Compare Source]\([^\n]+\)\n\n([\s\S]*?)\n\n<\/details>/g,
        ),
      ].map((match) => match[1]),
    );

    expect(releaseParts.join("")).toBe(releaseBody);
    expect(postedBodies.every((body) => body.length <= 500)).toBe(true);
    expect(result.stats.releaseSectionsSplit).toBe(releaseParts.length - 1);
    expect(result.stats.commentChars).toEqual(
      postedBodies.map((body) => body.length),
    );
  });
});

describe("formatRunSummary", () => {
  test("logs counts, comment sizes, and every package category", () => {
    const summary = formatRunSummary({
      comments: 1,
      stats: {
        parsedUpdates: 3,
        githubBacked: 2,
        releasesFound: 1,
        nonGithub: 1,
        unavailable: 1,
        lookupLimited: 0,
        releaseSectionsSplit: 0,
        commentChars: [842],
        foundPackages: ["aqua:cli/cli"],
        nonGithubPackages: ["crate:serde"],
        unavailablePackages: ["aqua:missing/release"],
        lookupLimitedPackages: [],
      },
    });

    expect(summary).toBe(`Renovate release notes summary
Parsed updates: 3 (2 GitHub-backed)
Releases found: 1
Skipped: 1 non-GitHub, 1 unavailable, 0 lookup-limited
Release continuation sections: 0
Comments: 1 (842 chars)
Found packages: aqua:cli/cli
Non-GitHub packages: crate:serde
Unavailable packages: aqua:missing/release
Lookup-limited packages: none`);
  });
});

function apiWithReleasePaths(paths) {
  return {
    async get(path) {
      paths.push(path);
      return githubRelease();
    },
  };
}

function githubRelease() {
  return {
    html_url: "https://github.com/cli/cli/releases/tag/v2.95.0",
    name: "GitHub CLI 2.95.0",
    body: "Bug fixes.",
    tag_name: "v2.95.0",
  };
}

function githubUpdate(githubRepo, toVersion) {
  return {
    packageName: githubRepo,
    sourceUrl: `https://github.com/${githubRepo}`,
    githubRepo,
    updateType: "patch",
    fromVersion: "0.0.1",
    toVersion,
    skipReason: null,
  };
}

function ownedComment(id, part, total, body) {
  return {
    id,
    body: markerBody(part, total, body),
    user: { login: "github-actions[bot]" },
  };
}

function markerBody(part, total, body) {
  return `<!-- renovate-release-notes-comment:v1 part=${part} total=${total} -->\n${body}`;
}

function apiWithComments(calls, comments) {
  return {
    async getAll() {
      return comments;
    },
    async post(path, body) {
      calls.push(["post", path, body]);
    },
    async patch(path, body) {
      calls.push(["patch", path, body]);
    },
    async delete(path) {
      calls.push(["delete", path]);
    },
  };
}
