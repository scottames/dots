export function selectReleaseRange(update, releases) {
  const fromVersion = parseNumericVersion(update.fromVersion);
  const toVersion = parseNumericVersion(update.toVersion);
  if (
    !fromVersion ||
    !toVersion ||
    fromVersion.length !== toVersion.length ||
    compareNumericVersions(fromVersion, toVersion) >= 0
  ) {
    return { update, releases: [], fallbackReason: "unsupported-range" };
  }

  const candidates = releases.map((release) => ({
    release,
    version: parseNumericVersion(release.tagName),
  }));
  const relevantCandidates = candidates.filter(
    ({ version }) =>
      version?.length === toVersion.length &&
      compareNumericVersions(version, fromVersion) > 0 &&
      compareNumericVersions(version, toVersion) <= 0,
  );
  const releaseIdsByVersion = new Map();
  for (const { release, version } of relevantCandidates) {
    const normalizedVersion = version.join(".");
    if (!releaseIdsByVersion.has(normalizedVersion)) {
      releaseIdsByVersion.set(normalizedVersion, release.id);
      continue;
    }
    const existingId = releaseIdsByVersion.get(normalizedVersion);
    if (
      existingId === undefined ||
      existingId === null ||
      release.id === undefined ||
      release.id === null ||
      existingId !== release.id
    ) {
      return { update, releases: [], fallbackReason: "version-collision" };
    }
  }
  const targetCandidates = candidates.filter(
    ({ version }) =>
      version?.length === toVersion.length &&
      compareNumericVersions(version, toVersion) === 0,
  );
  if (
    targetCandidates.length &&
    !targetCandidates.some(({ release }) => isEligibleRelease(release))
  ) {
    return { update, releases: [], fallbackReason: "ineligible-target" };
  }

  const selected = relevantCandidates
    .filter(({ release }) => isEligibleRelease(release))
    .sort(({ version: left }, { version: right }) =>
      compareNumericVersions(right, left),
    );
  const releasesByVersion = new Map();
  for (const { release, version } of selected) {
    const normalizedVersion = version.join(".");
    if (!releasesByVersion.has(normalizedVersion)) {
      releasesByVersion.set(normalizedVersion, { release, version });
    }
  }
  const uniqueSelected = [...releasesByVersion.values()];
  if (!uniqueSelected.length) {
    return { update, releases: [], fallbackReason: "empty-selection" };
  }
  if (
    !uniqueSelected.some(
      ({ version }) => compareNumericVersions(version, toVersion) === 0,
    )
  ) {
    return { update, releases: [], fallbackReason: "target-missing" };
  }

  return {
    update,
    releases: uniqueSelected.map(({ release }) => release),
    fallbackReason: null,
  };
}

export function isRelevantRelease(update, target, release) {
  if (release.id === target.id) {
    return true;
  }
  const selection = selectReleaseRange(update, [target, release]);
  return (
    selection.fallbackReason === "version-collision" ||
    selection.releases.some(({ id }) => id === release.id)
  );
}

export function hasConsistentEligibilityFields(exact, scanned) {
  return (
    exact.tagName === scanned.tagName &&
    exact.draft === scanned.draft &&
    exact.prerelease === scanned.prerelease &&
    exact.publishedAt === scanned.publishedAt
  );
}

export function normalizeGithubRelease(release) {
  if (!release || typeof release !== "object" || Array.isArray(release)) {
    throw new TypeError("malformed GitHub release");
  }
  if (!Number.isSafeInteger(release.id) || release.id <= 0) {
    throw new TypeError("malformed GitHub release id");
  }
  if (typeof release.tag_name !== "string" || !release.tag_name) {
    throw new TypeError("malformed GitHub release tag");
  }
  if (!isValidGithubHtmlUrl(release.html_url)) {
    throw new TypeError("malformed GitHub release HTML URL");
  }
  if (
    typeof release.draft !== "boolean" ||
    typeof release.prerelease !== "boolean"
  ) {
    throw new TypeError("malformed GitHub release state");
  }
  if (
    release.published_at !== null &&
    !isValidPublicationTimestamp(release.published_at)
  ) {
    throw new TypeError("malformed GitHub release publication timestamp");
  }
  if (release.name !== null && typeof release.name !== "string") {
    throw new TypeError("malformed GitHub release name");
  }
  if (release.body !== null && typeof release.body !== "string") {
    throw new TypeError("malformed GitHub release body");
  }

  return {
    id: release.id,
    tagName: release.tag_name,
    htmlUrl: release.html_url,
    name: release.name || "",
    body: release.body || "",
    draft: release.draft,
    prerelease: release.prerelease,
    publishedAt: release.published_at,
  };
}

export function releaseTagCandidates(version) {
  if (!version) {
    return [];
  }
  const candidates = [version];
  if (version.startsWith("v")) {
    candidates.push(version.slice(1));
  } else {
    candidates.push(`v${version}`);
  }
  return [...new Set(candidates)].filter(Boolean);
}

export function releaseNextPage(
  linkHeader,
  repository,
  currentPage,
  expectedLastPage = null,
  expectedRepositoryPath = null,
) {
  if (linkHeader === null) {
    return {
      page: null,
      reason:
        expectedLastPage !== null && expectedLastPage !== currentPage
          ? "invalid-next-link"
          : null,
      lastPage: expectedLastPage,
      repositoryPath: expectedRepositoryPath,
    };
  }

  const relationPages = new Map();
  let repositoryPath = expectedRepositoryPath;
  for (const entry of linkHeader.split(",").map((link) => link.trim())) {
    const match = /^<([^<>]+)>;\s*rel="([^"]+)"$/.exec(entry);
    const relation = match?.[2];
    if (
      !match ||
      !["next", "first", "prev", "last"].includes(relation) ||
      relationPages.has(relation)
    ) {
      return { page: null, reason: "invalid-next-link", lastPage: null };
    }
    const releasePage = releasePageNumber(match[1], repository);
    if (
      !releasePage ||
      (repositoryPath !== null && releasePage.repositoryPath !== repositoryPath)
    ) {
      return { page: null, reason: "invalid-next-link", lastPage: null };
    }
    repositoryPath ??= releasePage.repositoryPath;
    relationPages.set(relation, releasePage.page);
  }

  const next = relationPages.get("next") ?? null;
  const first = relationPages.get("first") ?? null;
  const prev = relationPages.get("prev") ?? null;
  const declaredLastPage = relationPages.get("last") ?? null;
  if (next !== null && next !== currentPage + 1) {
    return {
      page: null,
      reason: next <= currentPage ? "repeated-page" : "invalid-next-link",
      lastPage: null,
    };
  }
  if (
    (first !== null && first !== 1) ||
    (prev !== null && (currentPage === 1 || prev !== currentPage - 1)) ||
    (declaredLastPage !== null && declaredLastPage < currentPage) ||
    (declaredLastPage !== null &&
      expectedLastPage !== null &&
      declaredLastPage !== expectedLastPage)
  ) {
    return { page: null, reason: "invalid-next-link", lastPage: null };
  }

  const lastPage = declaredLastPage ?? expectedLastPage;
  if (
    (next !== null && lastPage !== null && next > lastPage) ||
    (next === null && lastPage !== null && currentPage !== lastPage)
  ) {
    return { page: null, reason: "invalid-next-link", lastPage: null };
  }
  return { page: next, reason: null, lastPage, repositoryPath };
}

function releasePageNumber(value, repository) {
  try {
    const url = new URL(value);
    const pageValue = url.searchParams.get("page");
    const page = Number(pageValue);
    return url.origin === "https://api.github.com" &&
      !url.username &&
      !url.password &&
      !url.hash &&
      (url.pathname === `/repos/${repository}/releases` ||
        /^\/repositories\/[1-9]\d*\/releases$/.test(url.pathname)) &&
      url.searchParams.get("per_page") === "100" &&
      [...url.searchParams].length === 2 &&
      /^[1-9]\d*$/.test(pageValue) &&
      Number.isSafeInteger(page) &&
      page > 0
      ? { page, repositoryPath: url.pathname }
      : null;
  } catch {
    return null;
  }
}

function isEligibleRelease(release) {
  return !release.draft && !release.prerelease && Boolean(release.publishedAt);
}

function parseNumericVersion(version) {
  if (typeof version !== "string" || !/^v?[0-9]+(?:\.[0-9]+)+$/.test(version)) {
    return null;
  }
  return version
    .replace(/^v/, "")
    .split(".")
    .map((component) => component.replace(/^0+(?=\d)/, ""));
}

function compareNumericVersions(left, right) {
  for (let index = 0; index < left.length; index += 1) {
    const lengthDifference = left[index].length - right[index].length;
    if (lengthDifference) {
      return lengthDifference;
    }
    if (left[index] !== right[index]) {
      return left[index] < right[index] ? -1 : 1;
    }
  }
  return 0;
}

function isValidPublicationTimestamp(value) {
  return (
    typeof value === "string" &&
    /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z$/.test(value) &&
    !Number.isNaN(Date.parse(value))
  );
}

function isValidGithubHtmlUrl(value) {
  try {
    const url = new URL(value);
    return url.protocol === "https:" && url.hostname === "github.com";
  } catch {
    return false;
  }
}
