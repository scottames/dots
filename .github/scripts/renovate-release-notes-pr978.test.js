import { describe, expect, test } from "bun:test";

import { runForPullRequest } from "./renovate-release-notes-comment.mjs";
import {
  pr978Body,
  rawGithubRelease,
} from "./renovate-release-notes-test-fixtures.js";

const pullRequestNumber = 978;
const unavailablePackages = [
  "cargo:cargo-deny",
  "go",
  "npm:socket",
  "pipx:mypy",
];
const nonGithubPackages = ["go:golang.org/x/tools/gopls", "npm:prettier"];
const githubTargets = [
  ["aqua:anthropics/claude-code", "anthropics/claude-code", "2.1.206"],
  ["aqua:astral-sh/ruff", "astral-sh/ruff", "0.15.21"],
  ["aqua:astral-sh/uv", "astral-sh/uv", "0.11.28"],
  ["aqua:atuinsh/atuin", "atuinsh/atuin", "18.17.0"],
  ["aqua:casey/just", "casey/just", "1.56.0"],
  ["aqua:eza-community/eza", "eza-community/eza", "0.23.5"],
  ["aqua:fastfetch-cli/fastfetch", "fastfetch-cli/fastfetch", "2.66.0"],
  ["aqua:helm/helm", "helm/helm", "4.2.3"],
  ["aqua:siderolabs/talos", "siderolabs/talos", "1.13.6"],
  ["aqua:snyk/cli", "snyk/cli", "1.1306.0"],
  ["aqua:sst/opencode", "sst/opencode", "1.17.18"],
  ["aqua:twpayne/chezmoi", "twpayne/chezmoi", "2.71.0"],
  ["cargo:cargo-deny", "EmbarkStudios/cargo-deny", "0.20.0"],
  ["github:agavra/tuicr", "agavra/tuicr", "v0.19.0"],
  ["github:aquaproj/aqua", "aquaproj/aqua", "v2.60.2"],
  ["github:dlvhdr/gh-dash", "dlvhdr/gh-dash", "v4.25.2"],
  ["github:janosmiko/lfk", "janosmiko/lfk", "v0.15.6"],
  ["github:max-sixty/worktrunk", "max-sixty/worktrunk", "v0.67.0"],
  ["go", "golang/go", "1.26.5"],
  ["npm:socket", "SocketDev/socket-cli", "1.1.143"],
  ["pipx:guarddog", "DataDog/guarddog", "3.1.0"],
  ["pipx:mypy", "python/mypy", "2.2.0"],
  ["pipx:semgrep", "semgrep/semgrep", "1.169.0"],
  ["rust", "rust-lang/rust", "1.97.0"],
];

describe("PR 978 release notes integration", () => {
  test("collects, renders, and posts every package outcome", async () => {
    const fixture = createApiFixture();

    const result = await runForPullRequest(fixture.api, pullRequestNumber, {
      maxCommentChars: 1800,
    });

    const expectedPackages = [
      ...githubTargets.map(([packageName]) => packageName),
      ...nonGithubPackages,
    ].sort();
    const accountedPackages = Object.values(
      result.stats.outcomePackages,
    ).flat();
    const successfulPackages = [
      ...result.stats.outcomePackages["range-found"],
      ...result.stats.outcomePackages["target-only-found"],
    ];

    expect(result.status).toBe("updated");
    expect(result.stats.parsedUpdates).toBe(26);
    expect(result.stats.githubBacked).toBe(24);
    expect(accountedPackages).toHaveLength(26);
    expect(new Set(accountedPackages).size).toBe(26);
    expect(accountedPackages.toSorted()).toEqual(expectedPackages);
    expect(successfulPackages).toHaveLength(20);
    expect(result.stats.outcomeCounts).toEqual({
      "range-found": 20,
      "target-only-found": 0,
      unavailable: 4,
      "request-limited": 0,
      "non-github": 2,
    });
    expect(result.stats.outcomePackages.unavailable).toEqual(
      unavailablePackages,
    );
    expect(result.stats.outcomePackages["non-github"]).toEqual(
      nonGithubPackages,
    );
    expect(result.stats.outcomePackages["range-found"]).toContain(
      "aqua:sst/opencode",
    );
    expect(result.stats.selectedReleaseEntries).toBe(24);
    expect(result.stats.continuationSections).toBe(0);
    expect(result.stats.fallbackReasons).toEqual([]);

    expect(fixture.exactPaths).toEqual(expectedExactPaths());
    expect(fixture.releasePagePaths).toEqual(expectedReleasePagePaths());
    expect(result.stats.releaseRequests).toBe(48);
    expect(result.stats.releaseRequests).toBe(
      fixture.exactPaths.length + fixture.releasePagePaths.length,
    );
    expect(result.stats.terminalRepositoryScans).toBe(20);
    expect(result.stats.releaseRequests).toBeGreaterThan(0);
    expect(result.stats.terminalRepositoryScans).toBeGreaterThan(0);

    expect(fixture.commentListPaths).toEqual([
      `/issues/${pullRequestNumber}/comments`,
    ]);
    expect(fixture.postedComments).toHaveLength(result.comments);
    expect(fixture.postedComments.length).toBeGreaterThan(1);
    expect(
      fixture.postedComments.every(
        ({ path }) => path === `/issues/${pullRequestNumber}/comments`,
      ),
    ).toBe(true);
    expect(result.stats.commentChars).toEqual(
      fixture.postedComments.map(({ body }) => body.length),
    );

    const rendered = fixture.postedComments.map(({ body }) => body).join("\n");
    expect(
      rendered.match(
        /<summary>sst\/opencode \(aqua:sst\/opencode\)<\/summary>/g,
      ),
    ).toHaveLength(1);
    const opencodeBodies = [18, 17, 16, 15].map(
      (version) =>
        `Unique OpenCode ${version} body. Thanks @&#8203;user${version}.`,
    );
    for (const body of opencodeBodies) {
      expect(rendered.split(body)).toHaveLength(2);
      expect(rendered).not.toContain(body.replace("@&#8203;", "@"));
    }
    const bodyPositions = opencodeBodies.map((body) => rendered.indexOf(body));
    expect(bodyPositions).toEqual(
      [...bodyPositions].sort((left, right) => left - right),
    );
    const worktrunkSummary =
      /<summary>max-sixty\/worktrunk \(github:max-sixty\/worktrunk\)<\/summary>/g;
    expect(rendered.match(worktrunkSummary)).toHaveLength(1);
    const worktrunkPositions = ["v0.67.0", "v0.66.0"].map((version) => {
      const url = `https://github.com/max-sixty/worktrunk/releases/tag/${version}`;
      expect(rendered.split(url)).toHaveLength(2);
      return rendered.indexOf(url);
    });
    expect(worktrunkPositions).toEqual(
      [...worktrunkPositions].sort((left, right) => left - right),
    );
  });
});
function createApiFixture() {
  const unavailable = new Set(unavailablePackages);
  const targetsByRepository = new Map();
  const unavailableRepositories = new Set();

  for (const [
    index,
    [packageName, repository, version],
  ] of githubTargets.entries()) {
    if (unavailable.has(packageName)) {
      unavailableRepositories.add(repository);
      continue;
    }
    targetsByRepository.set(
      repository,
      releaseFixture(repository, version, 1000 + index, packageName),
    );
  }
  const opencodeTarget = targetsByRepository.get("sst/opencode");
  const opencodeReleases = [15, 18, 16, 17].map((version) =>
    version === 18
      ? opencodeTarget
      : releaseFixture(
          "sst/opencode",
          `1.17.${version}`,
          11700 + version,
          "aqua:sst/opencode",
        ),
  );
  const releasesByRepository = new Map([
    ["sst/opencode", opencodeReleases],
    [
      "max-sixty/worktrunk",
      [
        targetsByRepository.get("max-sixty/worktrunk"),
        releaseFixture(
          "max-sixty/worktrunk",
          "v0.66.0",
          660,
          "github:max-sixty/worktrunk",
        ),
      ],
    ],
  ]);
  const exactPaths = [];
  const releasePagePaths = [];
  const commentListPaths = [];
  const postedComments = [];

  const api = {
    async get(path) {
      if (path === `/pulls/${pullRequestNumber}`) {
        return { user: { login: "renovate[bot]" }, body: pr978Body };
      }

      const match = path.match(/^\/repos\/(.+)\/releases\/tags\/(.+)$/);
      if (!match) {
        throw new Error(`unexpected GET ${path}`);
      }
      exactPaths.push(path);
      const [, repository, encodedTag] = match;
      const target = targetsByRepository.get(repository);
      if (
        unavailableRepositories.has(repository) ||
        !target ||
        decodeURIComponent(encodedTag) !== target.tag_name
      ) {
        throw notFound();
      }
      return target;
    },
    async getReleasePage(path) {
      releasePagePaths.push(path);
      const match = path.match(
        /^\/repos\/(.+)\/releases\?per_page=100&page=1$/,
      );
      const repository = match?.[1];
      const target = targetsByRepository.get(repository);
      if (!target) {
        throw new Error(`unexpected release page ${path}`);
      }
      return {
        releases: releasesByRepository.get(repository) ?? [target],
        link: null,
      };
    },
    async getAll(path) {
      commentListPaths.push(path);
      return [];
    },
    async post(path, payload) {
      postedComments.push({ path, body: payload.body });
      return { id: postedComments.length };
    },
    async patch(path) {
      throw new Error(`unexpected PATCH ${path}`);
    },
    async delete(path) {
      throw new Error(`unexpected DELETE ${path}`);
    },
  };

  return {
    api,
    exactPaths,
    releasePagePaths,
    commentListPaths,
    postedComments,
  };
}

function releaseFixture(repository, version, id, packageName) {
  const opencodeVersion =
    repository === "sst/opencode" ? version.split(".").at(-1) : null;
  return rawGithubRelease({
    id,
    html_url: `https://github.com/${repository}/releases/tag/${version}`,
    name:
      opencodeVersion === null
        ? `Release ${version}`
        : `OpenCode 1.17.${opencodeVersion}`,
    body:
      opencodeVersion === null
        ? `Complete release notes for ${packageName}.`
        : `Unique OpenCode ${opencodeVersion} body. Thanks @user${opencodeVersion}.`,
    tag_name: version,
  });
}

function expectedExactPaths() {
  return githubTargets.flatMap(([packageName, repository, version]) => {
    const tags = unavailablePackages.includes(packageName)
      ? [version, version.startsWith("v") ? version.slice(1) : `v${version}`]
      : [version];
    return tags.map(
      (tag) => `/repos/${repository}/releases/tags/${encodeURIComponent(tag)}`,
    );
  });
}

function expectedReleasePagePaths() {
  return githubTargets
    .filter(([packageName]) => !unavailablePackages.includes(packageName))
    .map(
      ([, repository]) => `/repos/${repository}/releases?per_page=100&page=1`,
    );
}

function notFound() {
  const error = new Error("not found");
  error.status = 404;
  return error;
}
