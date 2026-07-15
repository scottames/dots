import { describe, expect, test } from "bun:test";

import { isRenovatePullRequest } from "./renovate-release-notes-comment.mjs";
import { upsertCommentBodies } from "./renovate-release-notes-comments.mjs";

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

  test("updates comments authored by a configured app", async () => {
    const calls = [];
    const body = markerBody(1, 1, "new body");
    const api = apiWithComments(calls, [
      {
        id: 1,
        body: markerBody(1, 1, "old body"),
        user: { login: "scottames-github-bot[bot]" },
      },
    ]);

    await upsertCommentBodies(api, 123, [body], {
      managedAuthors: ["github-actions[bot]", "scottames-github-bot[bot]"],
    });

    expect(calls).toEqual([["patch", "/issues/comments/1", { body }]]);
  });

  test("creates missing parts and deletes stale managed parts on a shorter rerun", async () => {
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
