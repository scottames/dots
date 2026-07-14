#!/usr/bin/env node

import {
  buildCommentBodies,
  createReleaseNotesSections,
  maxCommentContentChars,
  markerPrefix,
  parseRenovateUpdates,
  releaseKey,
} from "./renovate-release-notes-lib.mjs";

export {
  buildCommentBodies,
  createReleaseNotesSections,
  parseRenovateUpdates,
} from "./renovate-release-notes-lib.mjs";

const defaultMaxCommentChars = 60000;
const defaultMaxComments = 50;
const defaultMaxReleaseLookups = 80;

export async function upsertCommentBodies(
  api,
  issueNumber,
  bodies,
  options = {},
) {
  const maxMutations = options.maxMutations ?? defaultMaxComments;
  const existing = await listReleaseNotesComments(api, issueNumber);
  const existingByPart = new Map(
    existing.map((comment) => [comment.part, comment]),
  );
  const mutations = [];

  for (let index = 0; index < bodies.length; index += 1) {
    const part = index + 1;
    const existingComment = existingByPart.get(part);
    if (existingComment) {
      if (existingComment.body !== bodies[index]) {
        mutations.push([
          "patch",
          `/issues/comments/${existingComment.id}`,
          { body: bodies[index] },
        ]);
      }
    } else {
      mutations.push([
        "post",
        `/issues/${issueNumber}/comments`,
        { body: bodies[index] },
      ]);
    }
  }

  for (const comment of existing) {
    if (comment.part > bodies.length) {
      mutations.push(["delete", `/issues/comments/${comment.id}`]);
    }
  }

  if (mutations.length > maxMutations) {
    throw new Error(
      `comment update requires ${mutations.length} mutations, limit is ${maxMutations}`,
    );
  }

  for (const [method, path, body] of mutations) {
    await api[method](path, body);
  }
}

export async function collectGithubReleases(api, updates, options = {}) {
  const maxReleaseLookups =
    options.maxReleaseLookups ?? defaultMaxReleaseLookups;
  const releases = new Map();
  const seen = new Set();
  const skippedByLookupLimit = new Set();
  let lookups = 0;

  for (const update of updates) {
    if (!update.githubRepo || !update.toVersion) {
      continue;
    }
    const key = releaseKey(update);
    if (seen.has(key)) {
      if (skippedByLookupLimit.has(key)) {
        update.skipReason = "github-release-lookup-limit";
      }
      continue;
    }
    seen.add(key);

    if (lookups >= maxReleaseLookups) {
      update.skipReason = "github-release-lookup-limit";
      skippedByLookupLimit.add(key);
      continue;
    }
    lookups += 1;

    const release = await findGithubRelease(
      api,
      update.githubRepo,
      update.toVersion,
    );
    if (release) {
      releases.set(key, release);
    }
  }

  return releases;
}

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
  const releases = await collectGithubReleases(api, updates, {
    maxReleaseLookups: options.maxReleaseLookups ?? defaultMaxReleaseLookups,
  });
  const sections = createReleaseNotesSections(updates, releases, {
    maxSectionChars: maxCommentContentChars(maxCommentChars, maxComments),
  });
  const bodies = buildCommentBodies(sections, {
    maxCommentChars,
    maxComments,
  });

  await upsertCommentBodies(api, issueNumber, bodies, {
    maxMutations: maxComments,
  });
  return {
    status: "updated",
    comments: bodies.length,
    stats: createRunStats(updates, releases, sections, bodies),
  };
}

function createRunStats(updates, releases, sections, bodies) {
  const found = updates.filter((update) => releases.has(releaseKey(update)));
  const nonGithub = updates.filter(
    (update) => update.skipReason === "non-github-source",
  );
  const lookupLimited = updates.filter(
    (update) => update.skipReason === "github-release-lookup-limit",
  );
  const unavailable = updates.filter(
    (update) =>
      update.githubRepo &&
      update.skipReason !== "github-release-lookup-limit" &&
      !releases.has(releaseKey(update)),
  );
  const renderedReleaseSections = sections.filter((section) =>
    section.startsWith("<details>\n<summary>"),
  ).length;

  return {
    parsedUpdates: updates.length,
    githubBacked: updates.filter((update) => update.githubRepo).length,
    releasesFound: found.length,
    nonGithub: nonGithub.length,
    unavailable: unavailable.length,
    lookupLimited: lookupLimited.length,
    releaseSectionsSplit: renderedReleaseSections - found.length,
    commentChars: bodies.map((body) => body.length),
    foundPackages: found.map((update) => update.packageName),
    nonGithubPackages: nonGithub.map((update) => update.packageName),
    unavailablePackages: unavailable.map((update) => update.packageName),
    lookupLimitedPackages: lookupLimited.map((update) => update.packageName),
  };
}

export function formatRunSummary(result) {
  const { stats } = result;
  const packageList = (packages) => packages.join(", ") || "none";

  return [
    "Renovate release notes summary",
    `Parsed updates: ${stats.parsedUpdates} (${stats.githubBacked} GitHub-backed)`,
    `Releases found: ${stats.releasesFound}`,
    `Skipped: ${stats.nonGithub} non-GitHub, ${stats.unavailable} unavailable, ${stats.lookupLimited} lookup-limited`,
    `Release continuation sections: ${stats.releaseSectionsSplit}`,
    `Comments: ${result.comments} (${stats.commentChars.join(", ")} chars)`,
    `Found packages: ${packageList(stats.foundPackages)}`,
    `Non-GitHub packages: ${packageList(stats.nonGithubPackages)}`,
    `Unavailable packages: ${packageList(stats.unavailablePackages)}`,
    `Lookup-limited packages: ${packageList(stats.lookupLimitedPackages)}`,
  ].join("\n");
}

async function listReleaseNotesComments(api, issueNumber) {
  const comments = await api.getAll(`/issues/${issueNumber}/comments`, {
    per_page: 100,
  });
  const markerRegex = new RegExp(
    `<!-- ${markerPrefix} part=(\\d+) total=(\\d+) -->`,
  );
  return comments
    .map((comment) => {
      const match = markerRegex.exec(comment.body || "");
      if (!match) {
        return null;
      }
      if (comment.user?.login !== "github-actions[bot]") {
        return null;
      }
      return { ...comment, part: Number(match[1]), total: Number(match[2]) };
    })
    .filter(Boolean);
}

async function findGithubRelease(api, githubRepo, version) {
  for (const tag of releaseTagCandidates(version)) {
    let release;
    try {
      release = await api.get(
        `/repos/${githubRepo}/releases/tags/${encodeURIComponent(tag)}`,
      );
    } catch (error) {
      if (error?.status === 404) {
        continue;
      }
      throw error;
    }
    return {
      htmlUrl: release.html_url,
      name: release.name,
      body: release.body,
      tagName: release.tag_name,
    };
  }

  return null;
}

function releaseTagCandidates(version) {
  if (!version) {
    return [];
  }
  const candidates = [version];
  if (version.startsWith("v")) {
    candidates.push(version.slice(1));
  } else {
    candidates.push(`v${version}`);
  }
  return [...new Set(candidates)];
}

export function createGitHubApi({ token, repository, fetchImpl = fetch }) {
  const baseUrl = "https://api.github.com";
  const repoPrefix = `/repos/${repository}`;

  async function requestRaw(method, path, body) {
    const apiPath = path.startsWith("/repos/") ? path : `${repoPrefix}${path}`;
    const url = path.startsWith("https://") ? path : `${baseUrl}${apiPath}`;
    const response = await fetchImpl(url, {
      method,
      headers: {
        Accept: "application/vnd.github+json",
        Authorization: `Bearer ${token}`,
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

async function main() {
  const token = process.env.GITHUB_TOKEN;
  const repository = process.env.GITHUB_REPOSITORY;
  const issueNumber = Number(process.env.PR_NUMBER);

  if (!token || !repository || !issueNumber) {
    throw new Error(
      "GITHUB_TOKEN, GITHUB_REPOSITORY, and PR_NUMBER are required",
    );
  }

  const api = createGitHubApi({ token, repository });
  const result = await runForPullRequest(api, issueNumber, {
    maxReleaseLookups: numberFromEnv(
      "MAX_RELEASE_LOOKUPS",
      defaultMaxReleaseLookups,
    ),
    maxCommentChars: numberFromEnv("MAX_COMMENT_CHARS", defaultMaxCommentChars),
    maxComments: numberFromEnv("MAX_COMMENTS", defaultMaxComments),
  });

  if (result.status === "skipped") {
    console.log("Skipping non-Renovate pull request");
  } else {
    console.log(formatRunSummary(result));
  }
}

function numberFromEnv(name, fallback) {
  const parsed = Number(process.env[name]);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
