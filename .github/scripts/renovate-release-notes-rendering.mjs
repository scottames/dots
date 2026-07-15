export function renderPackageSections(update, releases, maxSectionChars) {
  let total = 1;
  while (true) {
    const packageContents = packPackageContents(
      update,
      releases,
      maxSectionChars,
      total,
    );
    if (packageContents.length <= total) {
      const actualTotal = packageContents.length;
      return packageContents.map((content, index) =>
        renderPackageSection(update, content, index + 1, actualTotal),
      );
    }
    total = packageContents.length;
  }
}

export function renderSkippedSections(nonGithub, requestLimited, unavailable) {
  const sections = ["### Skipped Packages"];

  if (nonGithub.length) {
    sections.push("#### Non-GitHub Sources");
    for (const update of nonGithub) {
      sections.push(
        `- ${escapeMarkdownText(update.packageName)} (${escapeMarkdownText(update.sourceUrl || "no source URL")})`,
      );
    }
  }

  if (requestLimited.length) {
    sections.push("#### GitHub Release Lookup Limit Reached");
    for (const update of requestLimited) {
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

function packPackageContents(update, releases, maxSectionChars, total) {
  const packageContents = [];
  let content = "";

  const contentCapacity = () =>
    maxSectionChars -
    renderPackageSection(update, "", packageContents.length + 1, total).length;
  const finishPart = () => {
    packageContents.push(content);
    content = "";
  };

  for (const [index, release] of releases.entries()) {
    const freshMetadata = `${renderReleaseMetadata(update, release)}\n\n`;
    let metadata =
      content && index > 0 ? `\n\n${freshMetadata}` : freshMetadata;
    const bodyContent = releaseBody(release);
    const releaseContent = metadata + bodyContent;
    if (content.length + releaseContent.length <= contentCapacity()) {
      content += releaseContent;
      continue;
    }
    if (content) {
      const nextPartCapacity =
        maxSectionChars -
        renderPackageSection(update, "", packageContents.length + 2, total)
          .length;
      const freshReleaseContent = freshMetadata + bodyContent;
      if (freshReleaseContent.length <= nextPartCapacity) {
        finishPart();
        content = freshReleaseContent;
        continue;
      }
    }
    if (content.length + metadata.length > contentCapacity()) {
      if (content) {
        finishPart();
        metadata = freshMetadata;
      }
      if (metadata.length > contentCapacity()) {
        throw new Error(
          "release notes section metadata exceeds comment size limit",
        );
      }
    }
    content += metadata;

    let body = bodyContent;
    while (body) {
      const availableChars = contentCapacity() - content.length;
      if (body.length <= availableChars) {
        content += body;
        body = "";
      } else if (availableChars > 0) {
        const [bodyPart, remainingBody] = splitReleaseBody(
          body,
          availableChars,
        );
        content += bodyPart;
        finishPart();
        body = remainingBody;
      } else if (content) {
        finishPart();
      } else {
        throw new Error(
          "release notes section metadata exceeds comment size limit",
        );
      }
    }
  }

  if (content) {
    packageContents.push(content);
  }
  return packageContents;
}

function renderPackageSection(update, content, part, total) {
  const summarySuffix = total > 1 ? ` - part ${part} of ${total}` : "";
  return [
    "<details>",
    `<summary>${escapeHtml(update.githubRepo)} (${escapeHtml(update.packageName)})${summarySuffix}</summary>`,
    "",
    content,
    "",
    "</details>",
  ].join("\n");
}

function renderReleaseMetadata(update, release) {
  const compareUrl = compareSourceUrl(update, release);
  const releaseTitle = release.name
    ? `${release.tagName}: ${release.name}`
    : release.tagName;
  return [
    `#### [${escapeMarkdownText(releaseTitle)}](${release.htmlUrl})`,
    compareUrl ? `[Compare Source](${compareUrl})` : "",
  ]
    .filter(Boolean)
    .join("\n\n");
}

function releaseBody(release) {
  return neutralizeMentions(
    release.body || "No release notes body was provided by GitHub.",
  );
}

function splitReleaseBody(body, maxChars) {
  let splitAt = body.lastIndexOf("\n", maxChars - 1);
  if (splitAt < 1) {
    splitAt = maxChars;
    const before = body.charCodeAt(splitAt - 1);
    const after = body.charCodeAt(splitAt);
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
  return [body.slice(0, splitAt), body.slice(splitAt)];
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
