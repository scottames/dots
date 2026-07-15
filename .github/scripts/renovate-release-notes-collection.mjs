import {
  hasConsistentEligibilityFields,
  isRelevantRelease,
  normalizeGithubRelease,
  releaseNextPage,
  releaseTagCandidates,
  selectReleaseRange,
} from "./renovate-release-notes-collection-policy.mjs";

export const defaultMaxReleaseRequests = 160;

export async function collectGithubReleases(api, updates, options = {}) {
  const maxReleaseRequests = positiveSafeInteger(
    options.maxReleaseRequests,
    defaultMaxReleaseRequests,
  );
  const results = new Array(updates.length);
  const targets = new Array(updates.length);
  const exactReleases = new Map();
  const exactNotFound = new Set();
  let releaseRequests = 0;

  for (const [index, update] of updates.entries()) {
    if (!update.githubRepo) {
      results[index] = collectionResult(
        update,
        "non-github",
        update.skipReason || "non-github-source",
      );
      continue;
    }
    if (!update.toVersion) {
      results[index] = collectionResult(
        update,
        "unavailable",
        "missing-target-version",
      );
      continue;
    }

    let target = null;
    let requestLimited = false;
    const tagCandidates = releaseTagCandidates(update.toVersion);
    for (const tag of tagCandidates) {
      const cacheKey = `${update.githubRepo}\0${tag}`;
      if (exactReleases.has(cacheKey)) {
        target = exactReleases.get(cacheKey);
        break;
      }
      if (exactNotFound.has(cacheKey)) {
        continue;
      }
      if (releaseRequests >= maxReleaseRequests) {
        requestLimited = true;
        break;
      }

      releaseRequests += 1;
      try {
        const release = normalizeGithubRelease(
          await api.get(
            `/repos/${update.githubRepo}/releases/tags/${encodeURIComponent(tag)}`,
          ),
        );
        if (release.tagName !== tag) {
          throw new TypeError(
            "exact GitHub release tag does not match requested tag",
          );
        }
        target = release;
        exactReleases.set(cacheKey, target);
        break;
      } catch (error) {
        if (error?.status !== 404) {
          throw error;
        }
        exactNotFound.add(cacheKey);
      }
    }

    if (requestLimited) {
      results[index] = collectionResult(
        update,
        "request-limited",
        "exact-request-limit",
      );
      continue;
    }
    if (!target) {
      results[index] = collectionResult(update, "unavailable", "not-found");
      continue;
    }
    if (target.draft || !target.publishedAt) {
      results[index] = collectionResult(
        update,
        "unavailable",
        "ineligible-target",
      );
      continue;
    }

    const selection = selectReleaseRange(update, [target]);
    targets[index] = target;
    results[index] = collectionResult(
      update,
      "target-only-found",
      selection.fallbackReason || "range-request-limit",
      [target],
    );
  }

  if (
    results.some(
      ({ outcome, reason }) =>
        outcome === "request-limited" && reason === "exact-request-limit",
    )
  ) {
    return { results, releaseRequests, terminalRepositoryScans: 0 };
  }

  const rowsByRepository = new Map();
  for (const [index, result] of results.entries()) {
    if (
      result.outcome !== "target-only-found" ||
      result.reason !== "range-request-limit"
    ) {
      continue;
    }
    const repository = result.update.githubRepo;
    if (!rowsByRepository.has(repository)) {
      rowsByRepository.set(repository, []);
    }
    rowsByRepository.get(repository).push(index);
  }

  let terminalRepositoryScans = 0;
  for (const [repository, rowIndexes] of rowsByRepository) {
    if (releaseRequests >= maxReleaseRequests) {
      continue;
    }

    const candidates = new Map();
    const seenReleaseIds = new Set();
    let page = 1;
    let expectedLastPage = null;
    let expectedRepositoryPath = null;
    let scanReason = null;
    while (true) {
      if (releaseRequests >= maxReleaseRequests) {
        scanReason = "range-request-limit";
        break;
      }
      releaseRequests += 1;
      let response;
      try {
        response = await api.getReleasePage(
          `/repos/${repository}/releases?per_page=100&page=${page}`,
        );
      } catch (error) {
        if (error?.status !== 404) {
          throw error;
        }
        scanReason = "list-not-found";
        break;
      }
      if (
        !response ||
        !Array.isArray(response.releases) ||
        (response.link !== null && typeof response.link !== "string")
      ) {
        throw new TypeError("malformed GitHub release page");
      }

      for (const rawRelease of response.releases) {
        const release = normalizeGithubRelease(rawRelease);
        if (seenReleaseIds.has(release.id)) {
          scanReason = "repeated-release-id";
          break;
        }
        seenReleaseIds.add(release.id);
        if (
          rowIndexes.some((index) =>
            isRelevantRelease(updates[index], targets[index], release),
          )
        ) {
          candidates.set(release.id, release);
        }
      }
      if (scanReason) {
        break;
      }

      const next = releaseNextPage(
        response.link,
        repository,
        page,
        expectedLastPage,
        expectedRepositoryPath,
      );
      if (next.reason) {
        scanReason = next.reason;
        break;
      }
      expectedLastPage = next.lastPage;
      expectedRepositoryPath = next.repositoryPath;
      if (!next.page) {
        break;
      }
      if (page >= 20) {
        scanReason = "page-cap";
        break;
      }
      page = next.page;
    }

    terminalRepositoryScans += 1;
    for (const index of rowIndexes) {
      if (scanReason) {
        results[index] = collectionResult(
          updates[index],
          "target-only-found",
          scanReason,
          [targets[index]],
        );
        continue;
      }
      const candidateReleases = [...candidates.values()];
      const scannedTarget = candidates.get(targets[index].id);
      if (
        scannedTarget &&
        !hasConsistentEligibilityFields(targets[index], scannedTarget)
      ) {
        results[index] = collectionResult(
          updates[index],
          "target-only-found",
          "target-consistency-mismatch",
          [targets[index]],
        );
        continue;
      }
      const selection = selectReleaseRange(updates[index], candidateReleases);
      if (!candidates.has(targets[index].id)) {
        const consistencySelection = selectReleaseRange(updates[index], [
          targets[index],
          ...candidateReleases,
        ]);
        const reason =
          consistencySelection.fallbackReason === "version-collision"
            ? "version-collision"
            : selection.fallbackReason || "target-missing";
        results[index] = collectionResult(
          updates[index],
          "target-only-found",
          reason,
          [targets[index]],
        );
        continue;
      }
      results[index] = selection.fallbackReason
        ? collectionResult(
            updates[index],
            "target-only-found",
            selection.fallbackReason,
            [targets[index]],
          )
        : collectionResult(
            updates[index],
            "range-found",
            null,
            selection.releases,
          );
    }
  }

  return { results, releaseRequests, terminalRepositoryScans };
}

export function positiveSafeInteger(value, fallback) {
  return Number.isSafeInteger(value) && value > 0 ? value : fallback;
}

function collectionResult(update, outcome, reason, releases = []) {
  return { update, outcome, reason, releases };
}
