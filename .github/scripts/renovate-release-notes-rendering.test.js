import { describe, expect, test } from "bun:test";

import {
  createReleaseNotesSections,
  parseRenovateUpdates,
} from "./renovate-release-notes-lib.mjs";
import {
  collectionResult,
  collectionResults,
  githubUpdate,
  renovateMixedBody,
  renderedRelease,
} from "./renovate-release-notes-test-fixtures.js";

describe("createReleaseNotesSections rendering", () => {
  test("renders all result releases in package and release order", () => {
    const firstUpdate = {
      ...githubUpdate("sst/opencode", "1.17.18"),
      fromVersion: "1.17.14",
    };
    const secondUpdate = githubUpdate("cli/cli", "2.95.0");
    const results = [
      {
        update: firstUpdate,
        outcome: "range-found",
        reason: null,
        releases: [18, 17, 16, 15].map((version) => ({
          htmlUrl: `https://github.com/sst/opencode/releases/tag/1.17.${version}`,
          name: `OpenCode 1.17.${version}`,
          body: `unique-opencode-body-${version}`,
          tagName: `1.17.${version}`,
        })),
      },
      {
        update: secondUpdate,
        outcome: "target-only-found",
        reason: "unsupported-range",
        releases: [
          {
            htmlUrl: "https://github.com/cli/cli/releases/tag/v2.95.0",
            name: "GitHub CLI 2.95.0",
            body: "unique-cli-body",
            tagName: "v2.95.0",
          },
        ],
      },
    ];
    const sections = createReleaseNotesSections(results, {
      maxSectionChars: 4000,
    });
    const rendered = sections.join("\n");
    const bodies = [18, 17, 16, 15].map(
      (version) => `unique-opencode-body-${version}`,
    );
    const details = sections.filter((section) =>
      section.startsWith("<details>"),
    );
    const openCodeSections = details.filter((section) =>
      section.includes("<summary>sst/opencode (sst/opencode)</summary>"),
    );
    const cliSections = details.filter((section) =>
      section.includes("<summary>cli/cli (cli/cli)</summary>"),
    );
    const openCodeSection = openCodeSections[0] ?? "";

    for (const body of [...bodies, "unique-cli-body"]) {
      expect(rendered.split(body)).toHaveLength(2);
    }
    expect(openCodeSections).toHaveLength(1);
    expect(cliSections).toHaveLength(1);
    const openCodePositions = [];
    for (const version of [18, 17, 16, 15]) {
      const heading = `#### [1.17.${version}: OpenCode 1.17.${version}](https://github.com/sst/opencode/releases/tag/1.17.${version})`;
      const compareLink = `[Compare Source](https://github.com/sst/opencode/compare/1.17.14...1.17.${version})`;
      const body = `unique-opencode-body-${version}`;

      expect(rendered.split(heading)).toHaveLength(2);
      expect(rendered.split(compareLink)).toHaveLength(2);
      expect(openCodeSection.split(heading)).toHaveLength(2);
      expect(openCodeSection.split(body)).toHaveLength(2);
      openCodePositions.push(
        openCodeSection.indexOf(heading),
        openCodeSection.indexOf(body),
      );
    }
    expect(openCodePositions).toEqual(
      [...openCodePositions].sort((left, right) => left - right),
    );
    const positions = [...bodies, "unique-cli-body"].map((body) =>
      rendered.indexOf(body),
    );
    expect(positions).toEqual(
      [...positions].sort((left, right) => left - right),
    );
  });

  test("renders release notes and makes skipped packages visible", () => {
    const updates = parseRenovateUpdates(renovateMixedBody);
    const rendered = createReleaseNotesSections(
      collectionResults(updates, (update) =>
        update.packageName === "aqua:cli/cli"
          ? [
              {
                htmlUrl: "https://github.com/cli/cli/releases/tag/v2.95.0",
                name: "GitHub CLI 2.95.0",
                body: "Bug fixes and improvements.",
                tagName: "v2.95.0",
              },
            ]
          : [],
      ),
      { maxSectionChars: 1000 },
    ).join("\n");

    expect(rendered).toContain("### Renovate Release Notes");
    expect(rendered).toContain("<summary>cli/cli (aqua:cli/cli)</summary>");
    expect(rendered).toContain("Bug fixes and improvements.");
    expect(rendered).toContain("#### Non-GitHub Sources");
    expect(rendered).toContain("crate:serde");
    expect(rendered).toContain("no-link-package");
  });

  test("renders the GitHub placeholder for a transport-normalized null body", () => {
    const update = githubUpdate("cli/cli", "2.95.0");
    const rendered = createReleaseNotesSections(
      [
        collectionResult(update, "target-only-found", [
          renderedRelease("cli/cli", "2.95.0", ""),
        ]),
      ],
      { maxSectionChars: 1000 },
    ).join("\n");

    expect(rendered).toContain("No release notes body was provided by GitHub.");
  });

  test("neutralizes mentions in imported release notes", () => {
    const updates = parseRenovateUpdates(renovateMixedBody);
    const rendered = createReleaseNotesSections(
      collectionResults(updates, (update) =>
        update.packageName === "aqua:cli/cli"
          ? [
              {
                htmlUrl: "https://github.com/cli/cli/releases/tag/v2.95.0",
                name: "Release for @everyone",
                body: "Thanks @octocat.",
                tagName: "v2.95.0",
              },
            ]
          : [],
      ),
      { maxSectionChars: 1000 },
    ).join("\n");

    expect(rendered).toContain("@&#8203;everyone");
    expect(rendered).toContain("@&#8203;octocat");
  });

  test("encodes compare URL versions before rendering markdown links", () => {
    const update = githubUpdate("cli/cli", "2.0.0)@octocat");
    update.fromVersion = "1.0.0)@octocat";

    const rendered = createReleaseNotesSections(
      [
        collectionResult(update, "target-only-found", [
          {
            htmlUrl: "https://github.com/cli/cli/releases/tag/v2.0.0",
            name: "Release",
            body: "Notes",
            tagName: "v2.0.0)@octocat",
          },
        ]),
      ],
      { maxSectionChars: 1000 },
    ).join("\n");

    expect(rendered).toContain("compare/v1.0.0)%40octocat...v2.0.0)%40octocat");
    expect(rendered).not.toContain(
      "Compare Source](https://github.com/cli/cli/compare/v1.0.0)@octocat",
    );
  });

  test("reports GitHub packages whose release notes are unavailable", () => {
    const updates = parseRenovateUpdates(renovateMixedBody);
    const rendered = createReleaseNotesSections(collectionResults(updates), {
      maxSectionChars: 1000,
    }).join("\n");

    expect(rendered).toContain("#### GitHub Release Notes Unavailable");
    expect(rendered).toContain("aqua:cli/cli");
    expect(rendered).toContain("No GitHub release was found for `2.95.0`");
  });
});
