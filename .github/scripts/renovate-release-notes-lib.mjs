export const markerPrefix = "renovate-release-notes-comment:v1";

const defaultMaxCommentChars = 60000;
const defaultMaxComments = 50;
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

export function createReleaseNotesSections(updates, releases, options = {}) {
  const maxSectionChars = options.maxSectionChars ?? defaultMaxSectionChars;
  const sections = [
    [
      "### Renovate Release Notes",
      "Generated from Renovate's update table by the `renovate-release-notes-comment` workflow.",
      "Packages that cannot be summarized from GitHub releases are listed explicitly below.",
    ].join("\n\n"),
  ];
  const nonGithub = [];
  const lookupLimited = [];
  const unavailable = [];

  for (const update of updates) {
    if (update.skipReason === "non-github-source") {
      nonGithub.push(update);
      continue;
    }
    if (update.skipReason === "github-release-lookup-limit") {
      lookupLimited.push(update);
      continue;
    }

    const release = releases.get(releaseKey(update));
    if (!release) {
      unavailable.push(update);
      continue;
    }

    sections.push(...renderReleaseSections(update, release, maxSectionChars));
  }

  if (nonGithub.length || lookupLimited.length || unavailable.length) {
    sections.push(
      ...renderSkippedSections(nonGithub, lookupLimited, unavailable),
    );
  }

  if (updates.length === 0) {
    sections.push("No Renovate update table was found in the PR body.");
  }

  return sections;
}

export function buildCommentBodies(sections, options = {}) {
  const maxCommentChars = options.maxCommentChars ?? defaultMaxCommentChars;
  const maxComments = options.maxComments ?? defaultMaxComments;
  const chunkLimit = maxCommentContentChars(maxCommentChars, maxComments);
  const chunks = [];
  let current = "";

  for (const section of sections) {
    if (section.length > chunkLimit) {
      throw new Error("section exceeds GitHub comment size limit");
    }
    const next = current ? `${current}\n\n${section}` : section;
    if (current && next.length > chunkLimit) {
      chunks.push(current);
      current = section;
    } else {
      current = next;
    }
  }

  if (current) {
    chunks.push(current);
  }

  if (chunks.length > maxComments) {
    throw new Error(
      `release notes require ${chunks.length} comments, limit is ${maxComments}`,
    );
  }

  const total = chunks.length || 1;
  return (chunks.length ? chunks : ["No release notes were generated."]).map(
    (chunk, index) => {
      const marker = commentMarker(index + 1, total);
      const body = `${marker}\n${chunk}`;
      if (body.length > maxCommentChars) {
        throw new Error("comment exceeds GitHub comment size limit");
      }
      return body;
    },
  );
}

export function maxCommentContentChars(
  maxCommentChars = defaultMaxCommentChars,
  maxComments = defaultMaxComments,
) {
  const markerReserve = commentMarker(maxComments, maxComments).length + 1;
  return Math.max(1, maxCommentChars - markerReserve);
}

function commentMarker(part, total) {
  return `<!-- ${markerPrefix} part=${part} total=${total} -->`;
}

export function releaseKey(update) {
  return `${update.githubRepo}@${update.toVersion}`;
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

function renderReleaseSections(update, release, maxSectionChars) {
  const body = neutralizeMentions(
    release.body || "No release notes body was provided by GitHub.",
  );
  const singleSection = renderReleaseSection(update, release, body, 1, 1);
  if (singleSection.length <= maxSectionChars) {
    return [singleSection];
  }

  const wrapperChars =
    renderReleaseSection(update, release, "x", 999999, 999999).length - 1;
  const maxBodyChars = maxSectionChars - wrapperChars;
  if (maxBodyChars < 1) {
    throw new Error(
      "release notes section metadata exceeds comment size limit",
    );
  }

  const bodyParts = splitReleaseBody(body, maxBodyChars);
  return bodyParts.map((part, index) =>
    renderReleaseSection(update, release, part, index + 1, bodyParts.length),
  );
}

function renderReleaseSection(update, release, body, part, total) {
  const compareUrl = compareSourceUrl(update, release);
  const releaseTitle = release.name
    ? `${release.tagName}: ${release.name}`
    : release.tagName;
  const summarySuffix = total > 1 ? ` - part ${part} of ${total}` : "";

  return [
    "<details>",
    `<summary>${escapeHtml(update.githubRepo)} (${escapeHtml(update.packageName)})${summarySuffix}</summary>`,
    "",
    `#### [${escapeMarkdownText(releaseTitle)}](${release.htmlUrl})`,
    "",
    compareUrl ? `[Compare Source](${compareUrl})` : "",
    "",
    body,
    "",
    "</details>",
  ]
    .filter((line, index, lines) => line || lines[index - 1])
    .join("\n");
}

function splitReleaseBody(body, maxChars) {
  const parts = [];
  let remaining = body;

  while (remaining.length > maxChars) {
    let splitAt = remaining.lastIndexOf("\n", maxChars);
    if (splitAt < 1) {
      splitAt = maxChars;
      const before = remaining.charCodeAt(splitAt - 1);
      const after = remaining.charCodeAt(splitAt);
      if (
        before >= 0xd800 &&
        before <= 0xdbff &&
        after >= 0xdc00 &&
        after <= 0xdfff
      ) {
        splitAt -= 1;
        if (splitAt === 0) {
          throw new Error(
            "release note character exceeds section body size limit",
          );
        }
      }
    } else {
      splitAt += 1;
    }
    parts.push(remaining.slice(0, splitAt));
    remaining = remaining.slice(splitAt);
  }
  parts.push(remaining);
  return parts;
}

function renderSkippedSections(nonGithub, lookupLimited, unavailable) {
  const sections = ["### Skipped Packages"];

  if (nonGithub.length) {
    sections.push("#### Non-GitHub Sources");
    for (const update of nonGithub) {
      sections.push(
        `- ${escapeMarkdownText(update.packageName)} (${escapeMarkdownText(update.sourceUrl || "no source URL")})`,
      );
    }
  }

  if (lookupLimited.length) {
    sections.push("#### GitHub Release Lookup Limit Reached");
    for (const update of lookupLimited) {
      sections.push(
        `- ${escapeMarkdownText(update.packageName)}: skipped after the workflow lookup limit was reached`,
      );
    }
  }

  if (unavailable.length) {
    sections.push("#### GitHub Release Notes Unavailable");
    for (const update of unavailable) {
      sections.push(
        `- ${escapeMarkdownText(update.packageName)}: No GitHub release was found for \`${escapeMarkdownText(update.toVersion ?? "unknown")}\``,
      );
    }
  }

  return sections;
}

function compareSourceUrl(update, release) {
  if (!update.fromVersion || !update.toVersion || !update.githubRepo) {
    return null;
  }

  const toVersion = release.tagName || update.toVersion;
  const fromVersion =
    toVersion.startsWith("v") && !update.fromVersion.startsWith("v")
      ? `v${update.fromVersion}`
      : update.fromVersion;
  return `https://github.com/${update.githubRepo}/compare/${encodeURIComponent(fromVersion)}...${encodeURIComponent(toVersion)}`;
}

function escapeHtml(input) {
  return neutralizeMentions(input).replace(
    /[&<>]/g,
    (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" })[char],
  );
}

function escapeMarkdownText(input) {
  return neutralizeMentions(input).replace(/([\\\]\[])/g, "\\$1");
}

function neutralizeMentions(input) {
  return String(input ?? "").replace(/@/g, "@&#8203;");
}
