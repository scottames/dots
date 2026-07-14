# GitHub Workflow Scripts

This directory contains small support scripts for repository automation that is
too complex to keep directly in workflow YAML.

## Renovate Release Notes Comments

`renovate-release-notes-comment.mjs` is the executable used by
`.github/workflows/pr_renovate_release_notes.yaml`. It maintains best-effort
GitHub Release notes as PR comments instead of letting Renovate put changelogs
in the PR description.

`renovate-release-notes-lib.mjs` contains the pure parsing, rendering, and
comment chunking helpers used by the executable.

The workflow exists because Renovate release notes can exceed GitHub PR body
limits. When that happens, GitHub truncates the PR description and the useful
release-note detail can be cut off mid-package. Keeping the update table in the
PR body and moving release notes to maintained comments keeps the description
readable while preserving the GitHub Release details that the workflow finds.

This is intentionally narrower than Renovate's native changelog collection. It
fetches the target version's GitHub Release only; it does not parse changelog
files or collect intermediate releases between the current and target versions.

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
- It deduplicates and caps GitHub release API lookups.
- It rejects output above the configured comment-count limit before writing.
- It neutralizes `@` mentions in imported release text.
- It URL-encodes version components used in compare links.

## Tests

Run the release notes tests with Bun:

```bash
bun test ./.github/scripts/renovate-release-notes-comment.test.js ./.github/scripts/renovate-release-notes-lib.test.js
```

The tests cover parsing, complete package accounting, lossless comment chunking,
release lookup fallback/capping, run statistics, comment upsert behavior,
pagination, and non-Renovate PR no-op behavior.
