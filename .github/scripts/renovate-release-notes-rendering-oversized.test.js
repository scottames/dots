import { describe, expect, test } from "bun:test";

import { createReleaseNotesSections } from "./renovate-release-notes-lib.mjs";
import {
  collectionResult,
  githubUpdate,
  renderedRelease,
} from "./renovate-release-notes-test-fixtures.js";

describe("createReleaseNotesSections oversized rendering", () => {
  test("splits oversized release notes without dropping content", () => {
    const lines = Array.from(
      { length: 30 },
      (_, index) => `unique-release-line-${index.toString().padStart(2, "0")}`,
    );
    const update = githubUpdate("cli/cli", "2.0.0");
    const sections = createReleaseNotesSections(
      [
        collectionResult(update, "target-only-found", [
          {
            htmlUrl: "https://github.com/cli/cli/releases/tag/v2.0.0",
            name: "Release",
            body: lines.join("\n"),
            tagName: "v2.0.0",
          },
        ]),
      ],
      { maxSectionChars: 500 },
    );
    const rendered = sections.join("\n");
    const packageSections = sections.filter((section) =>
      section.startsWith("<details>\n<summary>cli/cli (cli/cli)"),
    );

    // The raw-body continuation makes two blocks the valid minimum.
    expect(packageSections).toHaveLength(2);
    expect(
      packageSections.map(
        (section) => /<summary>(.*?)<\/summary>/.exec(section)?.[1],
      ),
    ).toEqual(
      packageSections.map(
        (_, index) =>
          `cli/cli (cli/cli) - part ${index + 1} of ${packageSections.length}`,
      ),
    );
    expect(packageSections.every((section) => section.length <= 500)).toBe(
      true,
    );
    for (const line of lines) {
      expect(rendered.match(new RegExp(line, "g"))).toHaveLength(1);
    }
    expect(rendered).not.toContain("Release notes truncated");
  });

  test("keeps oversized intermediate release parts contiguous within its package", () => {
    const firstUpdate = {
      ...githubUpdate("one/repo", "1.3"),
      fromVersion: "1.0",
    };
    const intermediateBody = Array.from(
      { length: 30 },
      (_, index) => `intermediate-${index.toString().padStart(2, "0")} @team\n`,
    ).join("");
    const sections = createReleaseNotesSections(
      [
        collectionResult(firstUpdate, "range-found", [
          renderedRelease("one/repo", "1.3", "newest"),
          renderedRelease("one/repo", "1.2", intermediateBody),
          renderedRelease("one/repo", "1.1", "oldest"),
        ]),
        collectionResult(
          githubUpdate("two/repo", "2.0"),
          "target-only-found",
          [renderedRelease("two/repo", "2.0", "second-package")],
          "unsupported-range",
        ),
      ],
      { maxSectionChars: 400 },
    );
    const details = sections.filter((section) =>
      section.startsWith("<details>"),
    );
    const firstPackageSections = details.filter((section) =>
      section.startsWith("<details>\n<summary>one/repo (one/repo)"),
    );
    const secondPackageSections = details.filter((section) =>
      section.startsWith("<details>\n<summary>two/repo (two/repo)"),
    );
    const contentMarker = "</summary>\n\n";
    const firstPackageContents = firstPackageSections.map((section) => {
      const contentStart =
        section.indexOf(contentMarker) + contentMarker.length;
      const contentEnd = section.lastIndexOf("\n\n</details>");
      return section.slice(contentStart, contentEnd);
    });
    const firstPackageContent = firstPackageContents.join("");
    const releaseOrder = Array.from(
      sections.join("\n").matchAll(/^#### \[([^:\]]+)/gm),
      (match) => match[1],
    );
    const reconstructedBody =
      /\[Compare Source]\(https:\/\/github\.com\/one\/repo\/compare\/1\.0\.\.\.1\.2\)\n\n([\s\S]*?)#### \[1\.1:/.exec(
        firstPackageContent,
      )?.[1];

    expect(firstPackageSections.length).toBeGreaterThan(1);
    expect(firstPackageSections.every((section) => section.length <= 400)).toBe(
      true,
    );
    // If the next payload fit in the current wrapper, that continuation block
    // would be unnecessary and the ordered packing would not be minimal.
    for (let index = 0; index < firstPackageSections.length - 1; index += 1) {
      expect(
        firstPackageSections[index].length +
          firstPackageContents[index + 1].length,
      ).toBeGreaterThan(400);
    }
    expect(
      firstPackageSections.map(
        (section) => /<summary>(.*?)<\/summary>/.exec(section)?.[1],
      ),
    ).toEqual(
      firstPackageSections.map(
        (_, index) =>
          `one/repo (one/repo) - part ${index + 1} of ${firstPackageSections.length}`,
      ),
    );
    expect(secondPackageSections).toHaveLength(1);
    expect(secondPackageSections[0]).toContain(
      "<summary>two/repo (two/repo)</summary>",
    );
    expect(details).toEqual([
      ...firstPackageSections,
      ...secondPackageSections,
    ]);
    expect(releaseOrder).toEqual(["1.3", "1.2", "1.1", "2.0"]);
    expect(reconstructedBody).toBe(
      intermediateBody.replaceAll("@", "@&#8203;"),
    );
  });

  test("does not split Unicode surrogate pairs between sections", () => {
    const emoji = "😀";
    const results = [
      collectionResult(githubUpdate("cli/cli", "2.0.0"), "target-only-found", [
        {
          htmlUrl: "https://github.com/cli/cli/releases/tag/v2.0.0",
          name: "Release",
          body: emoji.repeat(300),
          tagName: "v2.0.0",
        },
      ]),
    ];

    for (
      let maxSectionChars = 450;
      maxSectionChars <= 510;
      maxSectionChars += 1
    ) {
      const sections = createReleaseNotesSections(results, {
        maxSectionChars,
      });
      const rendered = sections.join("\n");

      expect(rendered.split(emoji)).toHaveLength(301);
      for (const section of sections) {
        const loneSurrogates = Array.from(section).filter((character) => {
          const codePoint = character.charCodeAt(0);
          return (
            character.length === 1 && codePoint >= 0xd800 && codePoint <= 0xdfff
          );
        });

        expect(loneSurrogates).toEqual([]);
      }
    }

    const boundaryErrors = new Set();
    for (let maxSectionChars = 1; maxSectionChars < 450; maxSectionChars += 1) {
      try {
        createReleaseNotesSections(results, { maxSectionChars });
      } catch (error) {
        boundaryErrors.add(error.message);
      }
    }
    expect(boundaryErrors).toContain(
      "release note character exceeds section body size limit",
    );
  });

  test("keeps newline-aware body chunks within the section limit", () => {
    const originalBody = "123456789 @team\n".repeat(100);
    const results = [
      collectionResult(githubUpdate("cli/cli", "2.0.0"), "target-only-found", [
        renderedRelease("cli/cli", "2.0.0", originalBody),
      ]),
    ];

    for (
      let maxSectionChars = 450;
      maxSectionChars <= 510;
      maxSectionChars += 1
    ) {
      const sections = createReleaseNotesSections(results, {
        maxSectionChars,
      });
      const packageContents = sections
        .filter((section) => section.startsWith("<details>"))
        .map((section) =>
          section.slice(
            section.indexOf("</summary>\n\n") + "</summary>\n\n".length,
            section.lastIndexOf("\n\n</details>"),
          ),
        );
      const bodyChunks = packageContents.map((content, index) =>
        index === 0
          ? /\[Compare Source]\([^\n]+\)\n\n([\s\S]*)$/.exec(content)?.[1]
          : content,
      );

      expect(
        sections.every((section) => section.length <= maxSectionChars),
      ).toBe(true);
      expect(
        bodyChunks
          .slice(0, -1)
          .every((chunk) => chunk?.endsWith("@&#8203;team\n")),
      ).toBe(true);
      expect(bodyChunks.join("")).toBe(
        originalBody.replaceAll("@", "@&#8203;"),
      );
    }
  });

  test("drops the inter-release separator when moving to a fresh block", () => {
    const update = {
      ...githubUpdate("o/r", "2"),
      packageName: "p",
      fromVersion: "1",
    };
    const sections = createReleaseNotesSections(
      [
        collectionResult(update, "range-found", [
          { htmlUrl: "u1", tagName: "2", name: "", body: "a" },
          { htmlUrl: "u2", tagName: "1", name: "", body: "bbbbb" },
        ]),
      ],
      { maxSectionChars: 140 },
    );
    const packageSections = sections.filter((section) =>
      section.startsWith("<details>"),
    );
    const innerContents = packageSections.map((section) =>
      section.slice(
        section.indexOf("</summary>\n\n") + "</summary>\n\n".length,
        section.lastIndexOf("\n\n</details>"),
      ),
    );

    expect(packageSections).toHaveLength(2);
    expect(
      packageSections.map(
        (section) => /<summary>(.*?)<\/summary>/.exec(section)?.[1],
      ),
    ).toEqual(["o/r (p) - part 1 of 2", "o/r (p) - part 2 of 2"]);
    expect(packageSections.every((section) => section.length <= 140)).toBe(
      true,
    );
    expect(innerContents[0]).toContain("#### [2](u1)");
    expect(innerContents[0]).toEndWith("\n\na");
    expect(innerContents[0]).not.toContain("](u2)");
    expect(innerContents[1]).toStartWith("####");
    expect(innerContents[1]).toContain("#### [1](u2)");
    expect(innerContents[1]).toEndWith("\n\nbbbbb");
    expect(innerContents[1]).not.toContain("](u1)");
  });
});
