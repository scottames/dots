export { selectReleaseRange } from "./renovate-release-notes-collection-policy.mjs";
export {
  buildCommentBodies,
  markerPrefix,
  maxCommentContentChars,
} from "./renovate-release-notes-comments.mjs";
import {
  renderPackageSections,
  renderSkippedSections,
} from "./renovate-release-notes-rendering.mjs";

const defaultMaxSectionChars = 59000;

export function parseRenovateUpdates(body) {
  const updates = [];
  let headers = null;

  for (const line of body.split("\n")) {
    if (!line.trim().startsWith("|")) {
      headers = null;
      continue;
    }

    const cells = splitMarkdownTableRow(line);
    if (!cells.length || isSeparatorRow(cells)) {
      continue;
    }

    if (cells.some((cell) => normalizeHeader(cell) === "package")) {
      headers = cells.map(normalizeHeader);
      continue;
    }

    if (!headers?.includes("package")) {
      continue;
    }

    const row = Object.fromEntries(
      headers.map((header, index) => [header, cells[index] ?? ""]),
    );
    const packageCell = row.package ?? "";
    const link = extractMarkdownLink(packageCell);
    const sourceUrl = link?.url ?? stripMarkdown(packageCell);
    const githubRepo = githubRepoFromUrl(sourceUrl);
    const versions = extractVersionChange(row.change ?? "");

    updates.push({
      packageName: link?.text ?? stripMarkdown(packageCell),
      sourceUrl,
      githubRepo,
      updateType: row.update || row.type || null,
      fromVersion: versions.fromVersion,
      toVersion: versions.toVersion,
      skipReason: githubRepo ? null : "non-github-source",
    });
  }

  return updates;
}

export function createReleaseNotesSections(results, options = {}) {
  const maxSectionChars = options.maxSectionChars ?? defaultMaxSectionChars;
  const sections = [
    [
      "### Renovate Release Notes",
      "Generated from Renovate's update table by the `renovate-release-notes-comment` workflow.",
      "Packages that cannot be summarized from GitHub releases are listed explicitly below.",
    ].join("\n\n"),
  ];
  const nonGithub = [];
  const requestLimited = [];
  const unavailable = [];

  for (const result of results) {
    if (result.outcome === "non-github") {
      nonGithub.push(result.update);
    } else if (result.outcome === "request-limited") {
      requestLimited.push(result.update);
    } else if (result.outcome === "unavailable") {
      unavailable.push(result.update);
    } else if (result.releases.length) {
      sections.push(
        ...renderPackageSections(
          result.update,
          result.releases,
          maxSectionChars,
        ),
      );
    }
  }

  if (nonGithub.length || requestLimited.length || unavailable.length) {
    sections.push(
      ...renderSkippedSections(nonGithub, requestLimited, unavailable),
    );
  }

  if (results.length === 0) {
    sections.push("No Renovate update table was found in the PR body.");
  }

  return sections;
}

function splitMarkdownTableRow(line) {
  return line
    .trim()
    .replace(/^\|/, "")
    .replace(/\|$/, "")
    .split("|")
    .map((cell) => cell.trim());
}

function isSeparatorRow(cells) {
  return cells.every((cell) => /^:?-{3,}:?$/.test(cell));
}

function normalizeHeader(header) {
  return header.toLowerCase().replace(/\s+/g, "-");
}

function extractMarkdownLink(cell) {
  const match = /^\[([^\]]+)]\(([^)]+)\)/.exec(cell.trim());
  if (!match) {
    return null;
  }
  return { text: match[1], url: match[2] };
}

function stripMarkdown(input) {
  return input
    .replace(/^\[([^\]]+)]\(([^)]+)\)$/, "$1")
    .replace(/`/g, "")
    .trim();
}

function githubRepoFromUrl(url) {
  try {
    const parsed = new URL(url);
    if (
      !["github.com", "www.github.com", "redirect.github.com"].includes(
        parsed.hostname,
      )
    ) {
      return null;
    }
    const [owner, repo] = parsed.pathname.split("/").filter(Boolean);
    if (!owner || !repo) {
      return null;
    }
    return `${owner}/${repo.replace(/\.git$/, "")}`;
  } catch {
    return null;
  }
}

function extractVersionChange(changeCell) {
  const match = /`([^`]+)`\s*(?:→|->|&rarr;)\s*`([^`]+)`/.exec(changeCell);
  return {
    fromVersion: match?.[1] ?? null,
    toVersion: match?.[2] ?? null,
  };
}
