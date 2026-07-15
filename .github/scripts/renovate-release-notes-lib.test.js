import { describe, expect, test } from "bun:test";

import { selectReleaseRange } from "./renovate-release-notes-collection-policy.mjs";
import { parseRenovateUpdates } from "./renovate-release-notes-lib.mjs";
import {
  githubUpdate,
  renovateMixedBody,
  selectedGithubRelease,
} from "./renovate-release-notes-test-fixtures.js";

describe("parseRenovateUpdates", () => {
  test("extracts GitHub updates and marks non-GitHub packages as skipped", () => {
    expect(parseRenovateUpdates(renovateMixedBody)).toEqual([
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

describe("selectReleaseRange", () => {
  test("selects descending intervals when the exclusive lower bound is absent", () => {
    const update = githubUpdate("sst/opencode", "v1.17.18");
    update.fromVersion = "1.17.14";
    const releases = [
      selectedGithubRelease(18, "1.17.18"),
      selectedGithubRelease(16, "1.17.16"),
      selectedGithubRelease(15, "v1.17.15"),
      selectedGithubRelease(17, "v1.17.17"),
    ];

    const result = selectReleaseRange(update, releases);

    expect(result.update).toBe(update);
    expect(result.fallbackReason).toBeNull();
    expect(result.releases.map(({ tagName }) => tagName)).toEqual([
      "1.17.18",
      "v1.17.17",
      "1.17.16",
      "v1.17.15",
    ]);

    expect(
      selectReleaseRange(
        { ...update, fromVersion: "1.9", toVersion: "v1.10" },
        [selectedGithubRelease(2, "1.9"), selectedGithubRelease(1, "v1.10")],
      ).releases.map(({ tagName }) => tagName),
    ).toEqual(["v1.10"]);
    expect(
      selectReleaseRange(
        { ...update, fromVersion: "v01.009", toVersion: "1.010" },
        [selectedGithubRelease(3, "v01.010")],
      ).releases.map(({ tagName }) => tagName),
    ).toEqual(["v01.010"]);
    expect(
      selectReleaseRange(
        {
          ...update,
          fromVersion: "1.99999999999999999999999999999999999999",
          toVersion: "1.100000000000000000000000000000000000000",
        },
        [
          selectedGithubRelease(
            4,
            "v1.100000000000000000000000000000000000000",
          ),
        ],
      ).releases.map(({ tagName }) => tagName),
    ).toEqual(["v1.100000000000000000000000000000000000000"]);
  });

  test("falls back for unsupported or nonascending bounds", () => {
    const unsupportedBounds = [
      [null, "1.2"],
      ["1", "2"],
      ["V1.1", "1.2"],
      ["tool/v1.1", "1.2"],
      ["1.1-alpha", "1.2"],
      ["1.1+build", "1.2"],
      ["1.1", "1.2.0"],
      ["1.2", "v01.002"],
      ["2.0", "1.0"],
    ];

    for (const [fromVersion, toVersion] of unsupportedBounds) {
      const update = {
        ...githubUpdate("one/repo", toVersion),
        fromVersion,
      };

      expect(
        selectReleaseRange(update, [selectedGithubRelease(1, "1.2")]),
      ).toEqual({
        update,
        releases: [],
        fallbackReason: "unsupported-range",
      });
    }
  });

  test("excludes ineligible candidates and falls back for an ineligible target", () => {
    const update = {
      ...githubUpdate("one/repo", "1.4"),
      fromVersion: "0.9",
    };
    const releases = [
      selectedGithubRelease(1, "v1.4"),
      selectedGithubRelease(2, "1.3"),
      selectedGithubRelease(3, "1.2", { draft: true }),
      selectedGithubRelease(4, "1.1", { prerelease: true }),
      selectedGithubRelease(5, "1.0", { publishedAt: null }),
      selectedGithubRelease(6, "V1.2"),
      selectedGithubRelease(7, "tool/v1.2"),
      selectedGithubRelease(8, "1.2-alpha"),
      selectedGithubRelease(9, "1.2+build"),
      selectedGithubRelease(10, "1.2.0"),
    ];

    expect(
      selectReleaseRange(update, releases).releases.map(({ id }) => id),
    ).toEqual([1, 2]);

    for (const overrides of [
      { draft: true },
      { prerelease: true },
      { publishedAt: null },
    ]) {
      expect(
        selectReleaseRange(update, [
          selectedGithubRelease(11, "1.4", overrides),
        ]),
      ).toEqual({
        update,
        releases: [],
        fallbackReason: "ineligible-target",
      });
    }
  });

  test("falls back when distinct release IDs normalize to one selected version", () => {
    const update = {
      ...githubUpdate("one/repo", "1.3"),
      fromVersion: "1.0",
    };

    expect(
      selectReleaseRange(update, [
        selectedGithubRelease(1, "1.3"),
        selectedGithubRelease(2, "1.2"),
        selectedGithubRelease(3, "v01.002"),
      ]),
    ).toEqual({
      update,
      releases: [],
      fallbackReason: "version-collision",
    });
  });

  test.each([
    ["draft", { draft: true }],
    ["prerelease", { prerelease: true }],
    ["unpublished", { publishedAt: null }],
  ])(
    "detects a relevant version collision before filtering an %s release",
    (_state, overrides) => {
      const update = {
        ...githubUpdate("one/repo", "1.3"),
        fromVersion: "1.0",
      };

      expect(
        selectReleaseRange(update, [
          selectedGithubRelease(1, "1.3"),
          selectedGithubRelease(2, "1.2"),
          selectedGithubRelease(3, "v01.002", overrides),
        ]),
      ).toEqual({
        update,
        releases: [],
        fallbackReason: "version-collision",
      });
    },
  );

  test("falls back for duplicate normalized versions with missing IDs", () => {
    const update = {
      ...githubUpdate("one/repo", "1.3"),
      fromVersion: "1.0",
    };

    expect(
      selectReleaseRange(update, [
        selectedGithubRelease(undefined, "1.3"),
        selectedGithubRelease(undefined, "v01.003"),
      ]),
    ).toEqual({
      update,
      releases: [],
      fallbackReason: "version-collision",
    });
  });

  test("deduplicates repeated releases with the same ID", () => {
    const update = {
      ...githubUpdate("one/repo", "1.3"),
      fromVersion: "1.0",
    };
    const repeatedRelease = selectedGithubRelease(1, "1.3");

    expect(
      selectReleaseRange(update, [repeatedRelease, repeatedRelease]).releases,
    ).toEqual([repeatedRelease]);
  });

  test("falls back for empty selections and missing targets", () => {
    const update = {
      ...githubUpdate("one/repo", "1.3"),
      fromVersion: "1.0",
    };

    expect(selectReleaseRange(update, [])).toEqual({
      update,
      releases: [],
      fallbackReason: "empty-selection",
    });
    expect(
      selectReleaseRange(update, [selectedGithubRelease(1, "1.2")]),
    ).toEqual({
      update,
      releases: [],
      fallbackReason: "target-missing",
    });
  });
});
