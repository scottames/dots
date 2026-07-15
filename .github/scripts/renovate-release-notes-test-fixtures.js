export const renovateBody = `This PR contains the following updates:

| Package | Update | Change |
|---|---|---|
| [aqua:cli/cli](https://redirect.github.com/cli/cli) | minor | \`2.94.0\` → \`2.95.0\` |
`;

export const renovateMixedBody = `This PR contains the following updates:

| Package | Update | Change |
|---|---|---|
| [aqua:cli/cli](https://redirect.github.com/cli/cli) | minor | \`2.94.0\` → \`2.95.0\` |
| [crate:serde](https://crates.io/crates/serde) | patch | \`1.0.0\` → \`1.0.1\` |
| [no-link-package](not-a-url) | patch | \`1.0.0\` → \`1.0.1\` |
`;

export const pr978Body = `| Package | Update | Change | Pending | Age | Adoption | Passing | Confidence |
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

export function githubUpdate(githubRepo, toVersion) {
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

export function rawGithubRelease(overrides = {}) {
  return {
    id: 295,
    html_url: "https://github.com/cli/cli/releases/tag/v2.95.0",
    name: "GitHub CLI 2.95.0",
    body: "Bug fixes.",
    tag_name: "v2.95.0",
    draft: false,
    prerelease: false,
    published_at: "2026-07-01T12:00:00Z",
    ...overrides,
  };
}

export function normalizedGithubRelease(overrides = {}) {
  const release = rawGithubRelease(overrides);
  return {
    id: release.id,
    htmlUrl: release.html_url,
    name: release.name,
    body: release.body,
    tagName: release.tag_name,
    draft: release.draft,
    prerelease: release.prerelease,
    publishedAt: release.published_at,
  };
}

export function selectedGithubRelease(id, tagName, overrides = {}) {
  return {
    id,
    tagName,
    draft: false,
    prerelease: false,
    publishedAt: "2026-07-14T00:00:00Z",
    ...overrides,
  };
}

export function renderedRelease(repository, tagName, body) {
  return {
    htmlUrl: `https://github.com/${repository}/releases/tag/${tagName}`,
    name: `Release ${tagName}`,
    body,
    tagName,
  };
}

export function collectionResult(
  update,
  outcome,
  releases = [],
  reason = null,
) {
  return { update, outcome, reason, releases };
}

export function collectionResults(updates, releaseForUpdate = () => []) {
  return updates.map((update) => {
    if (!update.githubRepo) {
      return collectionResult(update, "non-github", [], "non-github-source");
    }
    const releases = releaseForUpdate(update);
    return releases.length
      ? collectionResult(update, "target-only-found", releases, "fixture")
      : collectionResult(update, "unavailable", [], "not-found");
  });
}
