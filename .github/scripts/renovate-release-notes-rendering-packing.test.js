import { describe, expect, test } from "bun:test";

import { createReleaseNotesSections } from "./renovate-release-notes-lib.mjs";
import {
  collectionResult,
  githubUpdate,
} from "./renovate-release-notes-test-fixtures.js";

describe("createReleaseNotesSections continuation packing", () => {
  test("uses the fewest blocks across continuation-count digit boundaries", () => {
    const update = {
      ...githubUpdate("o/r", "2"),
      packageName: "p",
      fromVersion: "1",
    };
    const sections = createReleaseNotesSections(
      [
        collectionResult(update, "range-found", [
          {
            htmlUrl: "https://x",
            name: "R",
            // Nine `of 9` parts fit 1648 chars; `of 10` loses nine chars.
            body: "x".repeat(1648),
            tagName: "2",
          },
        ]),
      ],
      { maxSectionChars: 256 },
    );
    const packageSections = sections.filter((section) =>
      section.startsWith("<details>"),
    );

    expect(packageSections).toHaveLength(9);
    expect(packageSections.at(-1)).toContain(
      "<summary>o/r (p) - part 9 of 9</summary>",
    );
  });

  test("sizes oversized body chunks for the candidate continuation total", () => {
    const update = {
      ...githubUpdate("o/r", "2"),
      packageName: "p",
      fromVersion: "1",
    };
    const body = "x".repeat(200);
    const sections = createReleaseNotesSections(
      [
        collectionResult(update, "range-found", [
          { htmlUrl: "u", name: "", body, tagName: "2" },
        ]),
      ],
      { maxSectionChars: 200 },
    );
    const packageSections = sections.filter((section) =>
      section.startsWith("<details>"),
    );
    const packageContent = packageSections
      .map((section) =>
        section.slice(
          section.indexOf("</summary>\n\n") + "</summary>\n\n".length,
          section.lastIndexOf("\n\n</details>"),
        ),
      )
      .join("");
    const reconstructedBody = /\[Compare Source]\([^\n]+\)\n\n([\s\S]*)$/.exec(
      packageContent,
    )?.[1];

    expect(packageSections).toHaveLength(2);
    expect(
      packageSections.map(
        (section) => /<summary>(.*?)<\/summary>/.exec(section)?.[1],
      ),
    ).toEqual(["o/r (p) - part 1 of 2", "o/r (p) - part 2 of 2"]);
    expect(packageSections.every((section) => section.length <= 200)).toBe(
      true,
    );
    expect(reconstructedBody).toBe(body);
    for (const section of packageSections) {
      expect(
        Array.from(section).filter((character) => {
          const codePoint = character.charCodeAt(0);
          return (
            character.length === 1 && codePoint >= 0xd800 && codePoint <= 0xdfff
          );
        }),
      ).toEqual([]);
    }
  });
});
