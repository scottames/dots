#!/usr/bin/env node

import {
  createReleaseNotesSections,
  parseRenovateUpdates,
} from "./renovate-release-notes-lib.mjs";
import {
  collectGithubReleases,
  defaultMaxReleaseRequests,
  positiveSafeInteger,
} from "./renovate-release-notes-collection.mjs";
import {
  buildCommentBodies,
  defaultMaxCommentChars,
  defaultMaxComments,
  maxCommentContentChars,
  upsertCommentBodies,
} from "./renovate-release-notes-comments.mjs";

export {
  createReleaseNotesSections,
  parseRenovateUpdates,
} from "./renovate-release-notes-lib.mjs";
export {
  collectGithubReleases,
  positiveSafeInteger,
} from "./renovate-release-notes-collection.mjs";
export {
  buildCommentBodies,
  upsertCommentBodies,
} from "./renovate-release-notes-comments.mjs";

const collectionOutcomes = [
  "range-found",
  "target-only-found",
  "unavailable",
  "request-limited",
  "non-github",
];

export function isRenovatePullRequest(pr) {
  const login = pr?.user?.login ?? "";
  return login === "renovate[bot]" || login === "app/renovate";
}

export async function runForPullRequest(api, issueNumber, options = {}) {
  const pr = await api.get(`/pulls/${issueNumber}`);

  if (!isRenovatePullRequest(pr)) {
    return { status: "skipped" };
  }

  const updates = parseRenovateUpdates(pr.body || "");
  const maxCommentChars = options.maxCommentChars ?? defaultMaxCommentChars;
  const maxComments = options.maxComments ?? defaultMaxComments;
  const collection = await collectGithubReleases(api, updates, {
    maxReleaseRequests: options.maxReleaseRequests,
  });
  const sections = createReleaseNotesSections(collection.results, {
    maxSectionChars: maxCommentContentChars(maxCommentChars, maxComments),
  });
  const bodies = buildCommentBodies(sections, {
    maxCommentChars,
    maxComments,
  });

  await upsertCommentBodies(api, issueNumber, bodies, {
    maxMutations: maxComments,
    managedAuthors: options.managedAuthors,
  });
  return {
    status: "updated",
    comments: bodies.length,
    stats: createRunStats(collection, sections, bodies),
  };
}

function createRunStats(collection, sections, bodies) {
  const outcomeCounts = Object.fromEntries(
    collectionOutcomes.map((outcome) => [outcome, 0]),
  );
  const outcomePackages = Object.fromEntries(
    collectionOutcomes.map((outcome) => [outcome, []]),
  );
  const fallbackReasons = [];
  let githubBacked = 0;
  let selectedReleaseEntries = 0;
  let successfulPackages = 0;

  for (const result of collection.results) {
    if (result.update.githubRepo) {
      githubBacked += 1;
    }
    if (Object.hasOwn(outcomeCounts, result.outcome)) {
      outcomeCounts[result.outcome] += 1;
      outcomePackages[result.outcome].push(result.update.packageName);
    }
    selectedReleaseEntries += result.releases.length;
    if (result.releases.length) {
      successfulPackages += 1;
    }
    if (result.outcome === "target-only-found") {
      fallbackReasons.push({
        packageName: result.update.packageName,
        reason: result.reason,
      });
    }
  }

  const renderedPackageSections = sections.filter((section) =>
    section.startsWith("<details>\n<summary>"),
  ).length;

  return {
    parsedUpdates: collection.results.length,
    githubBacked,
    outcomeCounts,
    selectedReleaseEntries,
    continuationSections: renderedPackageSections - successfulPackages,
    terminalRepositoryScans: collection.terminalRepositoryScans,
    releaseRequests: collection.releaseRequests,
    commentChars: bodies.map((body) => body.length),
    outcomePackages,
    fallbackReasons,
  };
}

export function formatRunSummary(result) {
  const { stats } = result;
  const packageList = (packages) => packages.join(", ") || "none";
  const outcomeTotal = Object.values(stats.outcomeCounts).reduce(
    (total, count) => total + count,
    0,
  );
  const fallbackReasons =
    stats.fallbackReasons
      .map(({ packageName, reason }) => `${packageName}: ${reason}`)
      .join(", ") || "none";

  return [
    "Renovate release notes summary",
    `Parsed updates: ${stats.parsedUpdates} (${stats.githubBacked} GitHub-backed)`,
    `Package outcomes: ${collectionOutcomes.map((outcome) => `${outcome}=${stats.outcomeCounts[outcome]}`).join(", ")} (total=${outcomeTotal})`,
    `Selected release entries: ${stats.selectedReleaseEntries}`,
    `Continuation sections: ${stats.continuationSections}`,
    `Terminal repository scans: ${stats.terminalRepositoryScans}`,
    `Actual release requests: ${stats.releaseRequests}`,
    `Comments: ${result.comments} (${stats.commentChars.join(", ")} chars)`,
    ...collectionOutcomes.map(
      (outcome) =>
        `${outcome} packages: ${packageList(stats.outcomePackages[outcome])}`,
    ),
    `Successful fallback reasons: ${fallbackReasons}`,
  ].join("\n");
}

export function createGitHubApi({
  token,
  writeToken = token,
  repository,
  fetchImpl = fetch,
}) {
  const baseUrl = "https://api.github.com";
  const repoPrefix = `/repos/${repository}`;

  async function requestRaw(method, path, body) {
    const apiPath = path.startsWith("/repos/") ? path : `${repoPrefix}${path}`;
    const url = path.startsWith("https://") ? path : `${baseUrl}${apiPath}`;
    const response = await fetchImpl(url, {
      method,
      headers: {
        Accept: "application/vnd.github+json",
        Authorization: `Bearer ${method === "GET" ? token : writeToken}`,
        "Content-Type": "application/json",
        "X-GitHub-Api-Version": "2022-11-28",
      },
      body: body ? JSON.stringify(body) : undefined,
    });

    if (!response.ok) {
      const error = new Error(
        `GitHub API ${method} ${path} failed: ${response.status}`,
      );
      error.status = response.status;
      error.body = await response.text();
      throw error;
    }

    return response;
  }

  async function request(method, path, body) {
    const response = await requestRaw(method, path, body);

    if (response.status === 204) {
      return null;
    }
    return response.json();
  }

  return {
    get: (path) => request("GET", path),
    async getReleasePage(path) {
      const response = await requestRaw("GET", path);
      return {
        releases: await response.json(),
        link: response.headers.get("link"),
      };
    },
    post: (path, body) => request("POST", path, body),
    patch: (path, body) => request("PATCH", path, body),
    delete: (path) => request("DELETE", path),
    async getAll(path, params = {}) {
      const searchParams = new URLSearchParams(params).toString();
      const separator = path.includes("?") ? "&" : "?";
      let next = `${path}${separator}${searchParams}`;
      const results = [];
      while (next) {
        const response = await requestRaw("GET", next);
        results.push(...(await response.json()));
        next = nextPageUrl(response.headers.get("link"));
      }
      return results;
    },
  };
}

async function main() {
  const token = process.env.GITHUB_TOKEN;
  const repository = process.env.GITHUB_REPOSITORY;
  const issueNumber = Number(process.env.PR_NUMBER);

  if (!token || !repository || !issueNumber) {
    throw new Error(
      "GITHUB_TOKEN, GITHUB_REPOSITORY, and PR_NUMBER are required",
    );
  }

  const api = createGitHubApi({
    token,
    writeToken: process.env.GITHUB_WRITE_TOKEN || token,
    repository,
  });
  const result = await runForPullRequest(api, issueNumber, {
    maxReleaseRequests: numberFromEnv(
      "MAX_RELEASE_REQUESTS",
      defaultMaxReleaseRequests,
    ),
    maxCommentChars: numberFromEnv("MAX_COMMENT_CHARS", defaultMaxCommentChars),
    maxComments: numberFromEnv("MAX_COMMENTS", defaultMaxComments),
    managedAuthors: ["github-actions[bot]", process.env.COMMENT_AUTHOR].filter(
      Boolean,
    ),
  });

  if (result.status === "skipped") {
    console.log("Skipping non-Renovate pull request");
  } else {
    console.log(formatRunSummary(result));
  }
}

export function numberFromEnv(name, fallback) {
  return positiveSafeInteger(Number(process.env[name]), fallback);
}

function nextPageUrl(linkHeader) {
  if (!linkHeader) {
    return null;
  }
  const next = linkHeader
    .split(",")
    .map((link) => link.trim())
    .find((link) => link.endsWith('rel="next"'));
  return next?.match(/^<([^>]+)>/)?.[1] ?? null;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
