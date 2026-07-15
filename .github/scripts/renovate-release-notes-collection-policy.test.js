import { describe, expect, test } from "bun:test";

import { releaseNextPage } from "./renovate-release-notes-collection-policy.mjs";

describe("releaseNextPage Link policy", () => {
  test("accepts GitHub's canonical numeric repository path", () => {
    const link =
      '<https://api.github.com/repositories/975734319/releases?per_page=100&page=2>; rel="next", <https://api.github.com/repositories/975734319/releases?per_page=100&page=9>; rel="last"';

    expect(releaseNextPage(link, "sst/opencode", 1)).toEqual({
      page: 2,
      reason: null,
      lastPage: 9,
      repositoryPath: "/repositories/975734319/releases",
    });
  });

  test("rejects mixed numeric repository paths", () => {
    const link =
      '<https://api.github.com/repositories/975734319/releases?per_page=100&page=2>; rel="next", <https://api.github.com/repositories/1078528927/releases?per_page=100&page=9>; rel="last"';

    expect(releaseNextPage(link, "sst/opencode", 1).reason).toBe(
      "invalid-next-link",
    );
  });

  test.each([
    [
      "malformed trailing entry",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next", not a link',
    ],
    [
      "duplicate next relation",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next", <https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next"',
    ],
    [
      "duplicate first relation",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next", <https://api.github.com/repos/one/repo/releases?per_page=100&page=1>; rel="first", <https://api.github.com/repos/one/repo/releases?per_page=100&page=1>; rel="first"',
    ],
    [
      "unknown relation",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next", <https://api.github.com/repos/one/repo/releases?per_page=100&page=1>; rel="alternate"',
    ],
    [
      "off-origin first relation",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next", <https://evil.example/repos/one/repo/releases?per_page=100&page=1>; rel="first"',
    ],
    [
      "wrong-path first relation",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next", <https://api.github.com/repos/one/repo/issues?per_page=100&page=1>; rel="first"',
    ],
    [
      "wrong per_page first relation",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next", <https://api.github.com/repos/one/repo/releases?per_page=50&page=1>; rel="first"',
    ],
    [
      "extra query parameter",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next", <https://api.github.com/repos/one/repo/releases?per_page=100&page=1&after=cursor>; rel="first"',
    ],
    [
      "duplicate query parameter",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next", <https://api.github.com/repos/one/repo/releases?per_page=100&page=1&page=1>; rel="first"',
    ],
    [
      "invalid page number",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next", <https://api.github.com/repos/one/repo/releases?per_page=100&page=zero>; rel="first"',
    ],
    [
      "non-canonical page number",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=02>; rel="next"',
    ],
    [
      "zero numeric repository ID",
      '<https://api.github.com/repositories/0/releases?per_page=100&page=2>; rel="next"',
    ],
    [
      "leading-zero numeric repository ID",
      '<https://api.github.com/repositories/01/releases?per_page=100&page=2>; rel="next"',
    ],
    [
      "nonnumeric repository ID",
      '<https://api.github.com/repositories/975x/releases?per_page=100&page=2>; rel="next"',
    ],
  ])("validates every Link entry: %s", (_name, link) => {
    expect(releaseNextPage(link, "one/repo", 1).reason).toBe(
      "invalid-next-link",
    );
  });

  test.each([
    [
      "first does not identify page 1",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="first"',
      1,
    ],
    [
      "prev occurs on page 1",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=1>; rel="prev"',
      1,
    ],
    [
      "prev is not the preceding page",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=1>; rel="prev"',
      3,
    ],
    [
      "last precedes the current page",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=1>; rel="last"',
      2,
    ],
    [
      "next exceeds last",
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=2>; rel="next", <https://api.github.com/repos/one/repo/releases?per_page=100&page=1>; rel="last"',
      1,
    ],
  ])("rejects invalid relation semantics when %s", (_name, link, page) => {
    expect(releaseNextPage(link, "one/repo", page).reason).toBe(
      "invalid-next-link",
    );
  });

  test("accepts a terminal header with valid first and prev but no next or last", () => {
    const link =
      '<https://api.github.com/repos/one/repo/releases?per_page=100&page=1>; rel="prev", <https://api.github.com/repos/one/repo/releases?per_page=100&page=1>; rel="first"';

    expect(releaseNextPage(link, "one/repo", 2)).toMatchObject({
      page: null,
      reason: null,
    });
  });
});
