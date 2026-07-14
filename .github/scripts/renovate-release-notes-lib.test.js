import { describe, expect, test } from "bun:test";

import {
  buildCommentBodies,
  createReleaseNotesSections,
  parseRenovateUpdates,
} from "./renovate-release-notes-lib.mjs";

const renovateBody = `This PR contains the following updates:

| Package | Update | Change |
|---|---|---|
| [aqua:cli/cli](https://redirect.github.com/cli/cli) | minor | \`2.94.0\` → \`2.95.0\` |
| [crate:serde](https://crates.io/crates/serde) | patch | \`1.0.0\` → \`1.0.1\` |
| [no-link-package](not-a-url) | patch | \`1.0.0\` → \`1.0.1\` |
`;

describe("parseRenovateUpdates", () => {
  test("extracts GitHub updates and marks non-GitHub packages as skipped", () => {
    expect(parseRenovateUpdates(renovateBody)).toEqual([
      {
        packageName: "aqua:cli/cli",
        sourceUrl: "https://redirect.github.com/cli/cli",
        githubRepo: "cli/cli",
        updateType: "minor",
        fromVersion: "2.94.0",
        toVersion: "2.95.0",
        skipReason: null,
      },
      {
        packageName: "crate:serde",
        sourceUrl: "https://crates.io/crates/serde",
        githubRepo: null,
        updateType: "patch",
        fromVersion: "1.0.0",
        toVersion: "1.0.1",
        skipReason: "non-github-source",
      },
      {
        packageName: "no-link-package",
        sourceUrl: "not-a-url",
        githubRepo: null,
        updateType: "patch",
        fromVersion: "1.0.0",
        toVersion: "1.0.1",
        skipReason: "non-github-source",
      },
    ]);
  });
});

describe("createReleaseNotesSections", () => {
  test("renders release notes and makes skipped packages visible", () => {
    const rendered = createReleaseNotesSections(
      parseRenovateUpdates(renovateBody),
      new Map([
        [
          "cli/cli@2.95.0",
          {
            htmlUrl: "https://github.com/cli/cli/releases/tag/v2.95.0",
            name: "GitHub CLI 2.95.0",
            body: "Bug fixes and improvements.",
            tagName: "v2.95.0",
          },
        ],
      ]),
      { maxSectionChars: 1000 },
    ).join("\n");

    expect(rendered).toContain("### Renovate Release Notes");
    expect(rendered).toContain("<summary>cli/cli (aqua:cli/cli)</summary>");
    expect(rendered).toContain("Bug fixes and improvements.");
    expect(rendered).toContain("#### Non-GitHub Sources");
    expect(rendered).toContain("crate:serde");
    expect(rendered).toContain("no-link-package");
  });

  test("neutralizes mentions in imported release notes", () => {
    const rendered = createReleaseNotesSections(
      parseRenovateUpdates(renovateBody),
      new Map([
        [
          "cli/cli@2.95.0",
          {
            htmlUrl: "https://github.com/cli/cli/releases/tag/v2.95.0",
            name: "Release for @everyone",
            body: "Thanks @octocat.",
            tagName: "v2.95.0",
          },
        ],
      ]),
      { maxSectionChars: 1000 },
    ).join("\n");

    expect(rendered).toContain("@&#8203;everyone");
    expect(rendered).toContain("@&#8203;octocat");
  });

  test("encodes compare URL versions before rendering markdown links", () => {
    const update = githubUpdate("cli/cli", "2.0.0)@octocat");
    update.fromVersion = "1.0.0)@octocat";

    const rendered = createReleaseNotesSections(
      [update],
      new Map([
        [
          "cli/cli@2.0.0)@octocat",
          {
            htmlUrl: "https://github.com/cli/cli/releases/tag/v2.0.0",
            name: "Release",
            body: "Notes",
            tagName: "v2.0.0)@octocat",
          },
        ],
      ]),
      { maxSectionChars: 1000 },
    ).join("\n");

    expect(rendered).toContain("compare/v1.0.0)%40octocat...v2.0.0)%40octocat");
    expect(rendered).not.toContain(
      "Compare Source](https://github.com/cli/cli/compare/v1.0.0)@octocat",
    );
  });

  test("reports GitHub packages whose release notes are unavailable", () => {
    const rendered = createReleaseNotesSections(
      parseRenovateUpdates(renovateBody),
      new Map(),
      { maxSectionChars: 1000 },
    ).join("\n");

    expect(rendered).toContain("#### GitHub Release Notes Unavailable");
    expect(rendered).toContain("aqua:cli/cli");
    expect(rendered).toContain("No GitHub release was found for `2.95.0`");
  });

  test("splits oversized release notes without dropping content", () => {
    const lines = Array.from(
      { length: 30 },
      (_, index) => `unique-release-line-${index.toString().padStart(2, "0")}`,
    );
    const sections = createReleaseNotesSections(
      [githubUpdate("cli/cli", "2.0.0")],
      new Map([
        [
          "cli/cli@2.0.0",
          {
            htmlUrl: "https://github.com/cli/cli/releases/tag/v2.0.0",
            name: "Release",
            body: lines.join("\n"),
            tagName: "v2.0.0",
          },
        ],
      ]),
      { maxSectionChars: 500 },
    );
    const rendered = sections.join("\n");

    expect(
      sections.filter((section) => section.includes("<details>")),
    ).toHaveLength(3);
    for (const line of lines) {
      expect(rendered.match(new RegExp(line, "g"))).toHaveLength(1);
    }
    expect(rendered).not.toContain("Release notes truncated");
  });

  test("does not split Unicode surrogate pairs between sections", () => {
    const emoji = "😀";
    const releases = new Map([
      [
        "cli/cli@2.0.0",
        {
          htmlUrl: "https://github.com/cli/cli/releases/tag/v2.0.0",
          name: "Release",
          body: emoji.repeat(300),
          tagName: "v2.0.0",
        },
      ],
    ]);

    for (
      let maxSectionChars = 450;
      maxSectionChars <= 510;
      maxSectionChars += 1
    ) {
      const rendered = createReleaseNotesSections(
        [githubUpdate("cli/cli", "2.0.0")],
        releases,
        { maxSectionChars },
      ).join("\n");
      const loneSurrogates = Array.from(rendered).filter((character) => {
        const codePoint = character.charCodeAt(0);
        return (
          character.length === 1 && codePoint >= 0xd800 && codePoint <= 0xdfff
        );
      });

      expect(rendered.split(emoji)).toHaveLength(301);
      expect(loneSurrogates).toEqual([]);
    }

    const boundaryErrors = new Set();
    for (let maxSectionChars = 1; maxSectionChars < 450; maxSectionChars += 1) {
      try {
        createReleaseNotesSections(
          [githubUpdate("cli/cli", "2.0.0")],
          releases,
          { maxSectionChars },
        );
      } catch (error) {
        boundaryErrors.add(error.message);
      }
    }
    expect(boundaryErrors).toContain(
      "release note character exceeds section body size limit",
    );
  });
});

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
      createReleaseNotesSections(updates, new Map(), {
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
    const body = `| Package | Update | Change | Pending | Age | Adoption | Passing | Confidence |
|---|---|---|---|---|---|---|---|
| [aqua:anthropics/claude-code](https://redirect.github.com/anthropics/claude-code) | patch | \`2.1.202\` → \`2.1.206\` |  |  |  |  |  |
| [aqua:astral-sh/ruff](https://redirect.github.com/astral-sh/ruff) | patch | \`0.15.20\` → \`0.15.21\` |  |  |  |  |  |
| [aqua:astral-sh/uv](https://redirect.github.com/astral-sh/uv) | patch | \`0.11.27\` → \`0.11.28\` |  |  |  |  |  |
| [aqua:atuinsh/atuin](https://redirect.github.com/atuinsh/atuin) | minor | \`18.16.1\` → \`18.17.0\` |  |  |  |  |  |
| [aqua:casey/just](https://redirect.github.com/casey/just) | minor | \`1.55.1\` → \`1.56.0\` |  |  |  |  |  |
| [aqua:eza-community/eza](https://redirect.github.com/eza-community/eza) | patch | \`0.23.4\` → \`0.23.5\` |  |  |  |  |  |
| [aqua:fastfetch-cli/fastfetch](https://redirect.github.com/fastfetch-cli/fastfetch) | minor | \`2.65.2\` → \`2.66.0\` |  |  |  |  |  |
| [aqua:helm/helm](https://redirect.github.com/helm/helm) | patch | \`4.2.2\` → \`4.2.3\` |  |  |  |  |  |
| [aqua:siderolabs/talos](https://redirect.github.com/siderolabs/talos) | patch | \`1.13.5\` → \`1.13.6\` |  |  |  |  |  |
| [aqua:snyk/cli](https://redirect.github.com/snyk/cli) | minor | \`1.1305.2\` → \`1.1306.0\` |  |  |  |  |  |
| [aqua:sst/opencode](https://redirect.github.com/sst/opencode) | patch | \`1.17.14\` → \`1.17.18\` |  |  |  |  |  |
| [aqua:twpayne/chezmoi](https://redirect.github.com/twpayne/chezmoi) | minor | \`2.70.5\` → \`2.71.0\` |  |  |  |  |  |
| [cargo:cargo-deny](https://redirect.github.com/EmbarkStudios/cargo-deny) | minor | \`0.19.0\` → \`0.20.0\` |  |  |  |  |  |
| [github:agavra/tuicr](https://redirect.github.com/agavra/tuicr) | minor | \`v0.18.0\` → \`v0.19.0\` |  |  |  |  |  |
| [github:aquaproj/aqua](https://redirect.github.com/aquaproj/aqua) | patch | \`v2.60.1\` → \`v2.60.2\` |  |  |  |  |  |
| [github:dlvhdr/gh-dash](https://redirect.github.com/dlvhdr/gh-dash) | patch | \`v4.25.0\` → \`v4.25.2\` |  |  |  |  |  |
| [github:janosmiko/lfk](https://redirect.github.com/janosmiko/lfk) | minor | \`v0.14.19\` → \`v0.15.6\` |  |  |  |  |  |
| [github:max-sixty/worktrunk](https://redirect.github.com/max-sixty/worktrunk) | minor | \`v0.65.0\` → \`v0.67.0\` |  |  |  |  |  |
| [go](https://redirect.github.com/golang/go) | patch | \`1.26.4\` → \`1.26.5\` |  |  |  |  |  |
| [go:golang.org/x/tools/gopls](go:golang.org/x/tools/gopls) | minor | \`0.22.0\` → \`v0.23.0\` |  |  |  |  |  |
| [npm:prettier](https://prettier.io) | patch | \`3.9.4\` → \`3.9.5\` |  |  |  |  |  |
| [npm:socket](https://redirect.github.com/SocketDev/socket-cli) | patch | \`1.1.139\` → \`1.1.143\` |  |  |  |  |  |
| [pipx:guarddog](https://redirect.github.com/DataDog/guarddog) | minor | \`3.0.2\` → \`3.1.0\` |  |  |  |  |  |
| [pipx:mypy](https://redirect.github.com/python/mypy) | minor | \`2.1.0\` → \`2.2.0\` |  |  |  |  |  |
| [pipx:semgrep](https://redirect.github.com/semgrep/semgrep) | minor | \`1.168.0\` → \`1.169.0\` |  |  |  |  |  |
| [rust](https://redirect.github.com/rust-lang/rust) | minor | \`1.96.1\` → \`1.97.0\` |  |  |  |  |  |`;
    const updates = parseRenovateUpdates(body);
    const unavailable = new Set([
      "cargo:cargo-deny",
      "go",
      "npm:socket",
      "pipx:mypy",
    ]);
    const releases = new Map(
      updates
        .filter(
          (update) => update.githubRepo && !unavailable.has(update.packageName),
        )
        .map((update) => [
          `${update.githubRepo}@${update.toVersion}`,
          {
            htmlUrl: `https://github.com/${update.githubRepo}/releases/tag/${update.toVersion}`,
            name: "Release",
            body: "Complete release notes.",
            tagName: update.toVersion,
          },
        ]),
    );
    const comments = buildCommentBodies(
      createReleaseNotesSections(updates, releases, {
        maxSectionChars: 700,
      }),
      { maxCommentChars: 800 },
    );
    const rendered = comments.join("\n");

    expect(updates).toHaveLength(26);
    expect(releases).toHaveLength(20);
    expect(comments.length).toBeGreaterThan(1);
    const incorrectlyRendered = updates
      .map((update) => ({
        packageName: update.packageName,
        occurrences:
          rendered.split(`(${update.packageName})</summary>`).length -
          1 +
          (rendered.split(`- ${update.packageName}: No GitHub release`).length -
            1) +
          (rendered.split(`- ${update.packageName}: skipped after`).length -
            1) +
          (rendered.split(`- ${update.packageName} (`).length - 1),
      }))
      .filter(({ occurrences }) => occurrences !== 1);
    expect(incorrectlyRendered).toEqual([]);
    expect(rendered).not.toContain("truncated");
  });
});

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
