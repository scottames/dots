import { describe, expect, test } from "bun:test";

import { buildCommentBodies } from "./renovate-release-notes-comments.mjs";
import {
  createReleaseNotesSections,
  parseRenovateUpdates,
} from "./renovate-release-notes-lib.mjs";
import {
  collectionResults,
  pr978Body,
} from "./renovate-release-notes-test-fixtures.js";

describe("buildCommentBodies", () => {
  test("splits long output into marked comments", () => {
    const comments = buildCommentBodies(
      [
        "### Renovate Release Notes\n\nIntro",
        "<details>\n<summary>one</summary>\n\n" +
          "a".repeat(40) +
          "\n</details>",
        "<details>\n<summary>two</summary>\n\n" +
          "b".repeat(40) +
          "\n</details>",
      ],
      { maxCommentChars: 180 },
    );

    expect(comments).toHaveLength(2);
    expect(comments[0]).toStartWith(
      "<!-- renovate-release-notes-comment:v1 part=1 total=2 -->",
    );
    expect(comments[1]).toStartWith(
      "<!-- renovate-release-notes-comment:v1 part=2 total=2 -->",
    );
    expect(comments.every((comment) => comment.length <= 180)).toBe(true);
  });

  test("preserves large skipped package lists across chunks", () => {
    const updates = Array.from({ length: 20 }, (_, index) => ({
      packageName: `crate:package-${index}`,
      sourceUrl: `https://crates.io/crates/package-${index}`,
      githubRepo: null,
      updateType: "patch",
      fromVersion: "1.0.0",
      toVersion: "1.0.1",
      skipReason: "non-github-source",
    }));

    const comments = buildCommentBodies(
      createReleaseNotesSections(collectionResults(updates), {
        maxSectionChars: 1000,
      }),
      { maxCommentChars: 300 },
    );
    const rendered = comments.join("\n");

    expect(comments.every((comment) => comment.length <= 300)).toBe(true);
    expect(rendered).toContain("crate:package-0");
    expect(rendered).toContain("crate:package-19");
  });

  test("rejects an oversized section instead of truncating output", () => {
    expect(() =>
      buildCommentBodies(["x".repeat(200)], { maxCommentChars: 150 }),
    ).toThrow("section exceeds GitHub comment size limit");
  });

  test("rejects output that would exceed the comment-count limit", () => {
    const sections = Array.from({ length: 51 }, () => "x".repeat(80));
    const allowed = buildCommentBodies(sections.slice(0, 50), {
      maxCommentChars: 150,
      maxComments: 50,
    });

    expect(allowed).toHaveLength(50);
    expect(allowed.every((comment) => comment.length <= 150)).toBe(true);
    expect(() =>
      buildCommentBodies(sections, {
        maxCommentChars: 150,
        maxComments: 50,
      }),
    ).toThrow("release notes require 51 comments, limit is 50");
  });

  test("accounts for every PR 978 package across grouped comments", () => {
    const updates = parseRenovateUpdates(pr978Body);
    const unavailable = new Set([
      "cargo:cargo-deny",
      "go",
      "npm:socket",
      "pipx:mypy",
    ]);
    const results = collectionResults(updates, (update) => {
      if (unavailable.has(update.packageName)) {
        return [];
      }
      if (update.packageName === "aqua:sst/opencode") {
        return [18, 17, 16, 15].map((version) => ({
          htmlUrl: `https://github.com/sst/opencode/releases/tag/1.17.${version}`,
          name: `OpenCode 1.17.${version}`,
          body: `Unique OpenCode ${version} body. Thanks @user${version}.`,
          tagName: `1.17.${version}`,
        }));
      }
      return [
        {
          htmlUrl: `https://github.com/${update.githubRepo}/releases/tag/${update.toVersion}`,
          name: "Release",
          body: `Complete release notes for ${update.packageName}.`,
          tagName: update.toVersion,
        },
      ];
    });
    const outcomeCounts = Object.groupBy(results, ({ outcome }) => outcome);
    const successfulPackages = results.filter(
      ({ releases }) => releases.length,
    );
    const releaseEntries = results.flatMap(({ releases }) => releases);
    const comments = buildCommentBodies(
      createReleaseNotesSections(results, {
        maxSectionChars: 4000,
      }),
      { maxCommentChars: 2000 },
    );
    const rendered = comments.join("\n");

    expect(updates).toHaveLength(26);
    expect(
      Object.values(outcomeCounts).reduce(
        (total, packages) => total + packages.length,
        0,
      ),
    ).toBe(26);
    expect(successfulPackages).toHaveLength(20);
    expect(releaseEntries.length).toBeGreaterThan(successfulPackages.length);
    expect(comments.length).toBeGreaterThan(1);
    for (const result of results) {
      const { update, releases } = result;
      if (releases.length) {
        expect(
          rendered.split(
            `<summary>${update.githubRepo} (${update.packageName})</summary>`,
          ),
        ).toHaveLength(2);
        for (const release of releases) {
          expect(rendered.split(release.htmlUrl)).toHaveLength(2);
          expect(
            rendered.split(release.body.replaceAll("@", "@&#8203;")),
          ).toHaveLength(2);
        }
      } else {
        const line =
          result.outcome === "non-github"
            ? `- ${update.packageName} (${update.sourceUrl})`
            : result.outcome === "request-limited"
              ? `- ${update.packageName}: skipped after the workflow lookup limit was reached`
              : `- ${update.packageName}: No GitHub release was found for \`${update.toVersion}\``;
        expect(rendered.split(line)).toHaveLength(2);
      }
    }
    expect(rendered).not.toContain("truncated");
    const opencodeBodies = [18, 17, 16, 15].map(
      (version) =>
        `Unique OpenCode ${version} body. Thanks @&#8203;user${version}.`,
    );
    for (const body of opencodeBodies) {
      expect(rendered.split(body)).toHaveLength(2);
    }
    const positions = opencodeBodies.map((body) => rendered.indexOf(body));
    expect(positions).toEqual(
      [...positions].sort((left, right) => left - right),
    );
  });
});
