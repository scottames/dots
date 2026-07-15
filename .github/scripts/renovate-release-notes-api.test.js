import { describe, expect, test } from "bun:test";

import {
  createGitHubApi,
  numberFromEnv,
} from "./renovate-release-notes-comment.mjs";
import { positiveSafeInteger } from "./renovate-release-notes-collection.mjs";
import { rawGithubRelease } from "./renovate-release-notes-test-fixtures.js";

describe("createGitHubApi", () => {
  test("uses a separate token for mutation requests", async () => {
    const requests = [];
    const api = createGitHubApi({
      token: "read-token",
      writeToken: "write-token",
      repository: "owner/repo",
      async fetchImpl(_url, init) {
        requests.push([init.method, init.headers.Authorization]);
        return new Response(init.method === "DELETE" ? null : "{}", {
          status:
            init.method === "POST" ? 201 : init.method === "DELETE" ? 204 : 200,
        });
      },
    });

    await api.get("/pulls/1");
    await api.post("/issues/1/comments", { body: "comment" });
    await api.patch("/issues/comments/1", { body: "updated" });
    await api.delete("/issues/comments/1");

    expect(requests).toEqual([
      ["GET", "Bearer read-token"],
      ["POST", "Bearer write-token"],
      ["PATCH", "Bearer write-token"],
      ["DELETE", "Bearer write-token"],
    ]);
  });

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

  test("fetches one release page without automatic pagination", async () => {
    const requested = [];
    const api = createGitHubApi({
      token: "token",
      repository: "owner/repo",
      async fetchImpl(url) {
        requested.push(url);
        return new Response(JSON.stringify([rawGithubRelease()]), {
          status: 200,
          headers: {
            link: '<https://api.github.com/repos/cli/cli/releases?per_page=100&page=2>; rel="next"',
          },
        });
      },
    });

    const page = await api.getReleasePage(
      "/repos/cli/cli/releases?per_page=100&page=1",
    );

    expect(requested).toEqual([
      "https://api.github.com/repos/cli/cli/releases?per_page=100&page=1",
    ]);
    expect(page).toEqual({
      releases: [rawGithubRelease()],
      link: '<https://api.github.com/repos/cli/cli/releases?per_page=100&page=2>; rel="next"',
    });
  });
});

describe("release request budget parsing", () => {
  test("uses the fallback unless a positive safe integer is supplied", () => {
    for (const value of [
      undefined,
      null,
      "",
      "17",
      0,
      -1,
      1.5,
      Infinity,
      true,
      false,
      17n,
      new Number(17),
      Symbol("17"),
    ]) {
      expect(positiveSafeInteger(value, 160)).toBe(160);
    }
    expect(positiveSafeInteger(Number.MAX_SAFE_INTEGER + 1, 160)).toBe(160);
    expect(positiveSafeInteger(17, 160)).toBe(17);
  });

  test("parses environment values with the same safe-integer rules", () => {
    const name = "TEST_MAX_RELEASE_REQUESTS";
    const original = process.env[name];
    try {
      process.env[name] = "2.5";
      expect(numberFromEnv(name, 160)).toBe(160);
      process.env[name] = "9007199254740992";
      expect(numberFromEnv(name, 160)).toBe(160);
      process.env[name] = "42";
      expect(numberFromEnv(name, 160)).toBe(42);
    } finally {
      if (original === undefined) {
        delete process.env[name];
      } else {
        process.env[name] = original;
      }
    }
  });
});
