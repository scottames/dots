# Worktrees

Stax manages branches, stacks and worktrees. Sibling checkouts use `root_dir = ".."`;
warm-slot recycling is disabled to keep paths stable.

| Command | Behavior |
| --- | --- |
| `wtc branch` | Create/reuse a worktree and enter it |
| `wtc branch --from main` | Create from an explicit base |
| `wtg [branch]` | Enter an existing worktree; no argument opens the picker |
| `wts [branch]` | Alias for `wtg` |
| `wtr branch` | Remove a checkout, retaining its branch |

Native creation stacks on the current tracked branch by default. Use `--from`
for independent work. Existing checkouts and branch metadata are reused in place.
Legacy `.bare` layouts work; select a checkout rather than the admin directory.

## Setup

The blocking `post_create` hook copies ignored regular files from the primary
checkout, runs `thts init --no-agents --force` when available, then `trunk check`
if configured. Existing files and symlinks are skipped. Project `stax.toml` can
replace the hook with project-specific setup.

A setup failure leaves the checkout in place and stops launch. Fix setup there
before re-entering; re-entry does not retry `post_create`.

## Cleanup

`git_prune` previews; `git_prune --apply` requires a clean primary checkout on
trunk, validates metadata, and pulls with `--ff-only`.

Only clean, unlocked, inactive checkouts older than two days whose HEAD is an
ancestor of trunk are removed through Stax. Primary/current, detached, interrupted,
recently used, uncertain and parent checkouts are kept. Squash merges without
ancestry confirmation need manual review. Branches and metadata are retained.

Activity checks use current-user process directories and, inside Herdr, its
spaces/terminals. Probe failures keep the checkout. Checks cannot see other users
or hidden container processes; `stax wt lock branch` explicitly protects a checkout.
Save ignored artifacts before applying.

Stale bookkeeping is pruned separately with a two-day floor; recoverable staged
or interrupted state blocks pruning. Branch deletion is a separate reviewed step;
avoid `--delete-branch` on parents with surviving children.

## Optional terminal integration

Inside Herdr, `hw` opens/reuses a space for the current checkout; `hwt [branch]`
selects an existing worktree; `hwtc branch` creates from trunk. Use
`hwtc --base feature branch` or `--base @` for an explicit parent. These preserve
project labels and the calling directory. See [Herdr](herdr.md).

`zw [-c] [-b BASE] [branch]` provides the legacy Zellij tab/agent flow.
`gt-wt-create [-b BASE] [--no-cd] branch` retains Graphite-only tracking.
