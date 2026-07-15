# GitHub Workflow Scripts

This directory contains small support scripts for repository automation that is
too complex to keep directly in workflow YAML.

## Renovate Release Notes Comments

`renovate-release-notes-comment.mjs` is the executable and composition root used
by `.github/workflows/pr_renovate_release_notes.yaml`.
`renovate-release-notes-collection.mjs` orchestrates exact lookups, repository
scans, budgets, and package outcomes; `renovate-release-notes-collection-policy.mjs`
contains the pure release normalization and range-selection policy.
`renovate-release-notes-comments.mjs` owns comment construction and lifecycle,
while `renovate-release-notes-lib.mjs` parses Renovate tables and renders release
note sections. Together they maintain best-effort GitHub Release notes as PR
comments instead of putting changelogs in the PR description.

The workflow exists because Renovate release notes can exceed GitHub PR body
limits. When that happens, GitHub truncates the PR description and the useful
release-note detail can be cut off mid-package. Keeping the update table in the
PR body and moving release notes to maintained comments keeps the description
readable while preserving the GitHub Release details that the workflow finds.

Release collection follows a cumulative, fail-closed contract:

- Exact target GitHub Release resolution happens first.
- Cumulative ranges support stable dotted numeric versions with an optional
  lowercase `v`, equal component arity, and the interval
  `(fromVersion, toVersion]`.
- A complete, internally consistent observed repository traversal renders every
  eligible published GitHub Release in that interval, newest first.
- Unsupported, incomplete or bounded, empty, missing-target, and ambiguous
  scans fall back to the complete exact target only. Partial range entries are
  never blended into that fallback.
- Actual release requests share a global 160-request budget. Each repository
  scan also has a private 20-page cap at 100 entries per page.
- GitHub provides no cross-page snapshot guarantee. Complete means one terminal,
  internally consistent observed traversal, not an atomic snapshot.

Package outcomes are `range-found`, `target-only-found`, `unavailable`,
`request-limited`, and `non-github`. Release-entry, actual-request, and terminal
scan counts are reported separately. Comment writes remain sequential and
non-atomic; a later successful run repairs a temporary mixed generation.

This remains intentionally narrower than Renovate's native collection. It adds
no changelog-file parsing, full Renovate versioning parity, ordinary-tag or
prerelease/build/prefixed cumulative ordering, non-GitHub releases, retries,
permission changes, or broader workflow behavior.

## What It Does

- Parses Renovate's PR update table.
- Fetches GitHub releases for GitHub-backed package links.
- Preserves complete GitHub Release bodies across one or more marked PR
  comments.
- Updates existing workflow-owned comments instead of creating duplicates.
- Deletes stale extra comment chunks when later output gets shorter.
- Lists skipped non-GitHub packages explicitly.
- Lists GitHub packages whose release notes could not be found.
- Chunks comments below GitHub's comment body limit.
- Logs package coverage, skip reasons, continuation sections, and comment sizes.

## Safety Constraints

The workflow runs on `pull_request_target`, so the script is intentionally
conservative:

- It only processes PRs authored by `app/renovate` or `renovate[bot]`.
- It checks out the base repository code, not PR-controlled code.
- It filters managed comments to `github-actions[bot]` before edit/delete.
- It deduplicates exact lookups and globally caps actual release requests.
- It rejects output above the configured comment-count limit before writing.
- It neutralizes `@` mentions in imported release text.
- It URL-encodes version components used in compare links.

## Tests

Run the release notes tests with Bun:

```bash
bun test ./.github/scripts/renovate-release-notes-*.test.js
```

The tests cover parsing, complete package accounting, lossless comment chunking,
exact and cumulative release fallback/capping, run statistics, comment upsert
behavior, pagination, and non-Renovate PR no-op behavior.
