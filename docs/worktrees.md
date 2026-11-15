# Worktrees: Stax + Herdr

Stax owns branches, stack metadata and worktrees. Herdr owns terminal spaces and
agent sessions. Fish passes Stax's shell-path payload to the existing Herdr
workspace helper without changing the calling directory.

## Everyday commands

| Command | Behavior |
| --- | --- |
| `hw` | Open/reuse a Herdr space for the current checkout |
| `hwt` | Native Stax existing-worktree picker, then open its Herdr space |
| `hwt branch` | Open an existing worktree |
| `hwtc branch` | Create/reuse a worktree; new branches start at trunk |
| `hwtc --base feature branch` | Explicitly stack a new branch on `feature` |
| `hwtc --base @ branch` | Explicitly stack on the current branch |
| `stax wt create/go` | Native shell-integrated workflow, including changing directory |
| `wts`, `wtsc`, `wtr` | Abbreviations for native Stax go/create/remove |
| `zw [-c] [-b BASE] [branch]` | Same Stax resolver, existing Zellij naming and agent panes |
| `gt-wt-create [-b BASE] [--no-cd] branch` | Graphite-only tracking, Stax worktree creation |

The main checkout gets a Herdr space first. Desktop space reuse and `project_label`
naming are unchanged. Legacy TUI still uses `herdr worktree open`. Its existing
single-tab layout now focuses correctly instead of parsing a nonexistent split
response. Worktrunk's Alt-c picker creation and `pr:123`/special base selectors are
not retained; use `hwtc` and a local base branch. Native `wtsc` follows Stax's
current-branch parenting rules; use `hwtc` for independent agent work.

`root_dir = ".."` preserves sibling layouts, including `<repo>/.bare` with
`<repo>/main`. Warm-slot recycling is disabled: reused directories can retain a
previous branch's pathname and confuse persistent terminal identities. Existing
worktrees are discovered in place; no import, relocation or metadata rewrite is
needed. Existing untracked branches stay untracked. A `.bare` repository needs a
trunk checkout. Stax 0.118.2–0.120.0 includes the bare admin directory in its picker;
select a checkout, not `.bare`. Its rich/JSON status fails on that directory, so
Fish uses read-only Git inventory for primary resolution/completions and the
existing Git fallback in `git_status`.

## Setup hooks

Global `worktree.hooks.post_create` runs synchronously, in this order:

1. Copy ignored regular files from the primary checkout without overwriting
   existing files. This includes local config and dependency files. Symlinks and
   paths through symlinks are skipped. This is a cold copy, not Worktrunk's
   optimized copy engine; `.worktreeinclude` filtering is not implemented.
2. Run `thts init --no-agents --force` if `thts` is installed.
3. Run `trunk check` if `.trunk/trunk.yaml` exists. A missing Trunk binary is an error.

The small Python copy helper does no branch/worktree lifecycle or metadata work.
Project `stax.toml` may override `post_create` to install dependencies instead,
for example `pnpm install`, or to copy only selected local files. A project override
replaces the global hook; include any desired global setup explicitly.

A failure stops the launch, but Stax retains the created branch/worktree. Fix the
cause and run the failed setup in that checkout before opening it with `hwt`.
Re-entering/reusing a worktree runs `post_go`, **not** `post_create`; it will not
retry failed setup. Native `--no-verify` skips create/go hooks. Stax's `post_start`,
`post_go` and `post_remove` are background jobs with discarded output; `pre_remove`
is blocking. No metadata synchronization hook remains.

## Cleanup safety and deliberate differences

`git_prune` previews eligible removals by default. `--apply` requires the clean
primary checkout on configured trunk, validates Stax metadata and pulls with
`--ff-only`. A small Python eligibility filter delegates each removal to
`stax worktree remove <absolute-path>`, never passing force or delete-branch.

A live checkout is eligible only when it is clean, unlocked, not primary/current
or trunk/detached, has no interrupted Git operation or tracked children, is older
than two days, and its HEAD is an ancestor of trunk. Squash-merged branches that
are not ancestors stay for manual review. Branches and stack metadata are always
retained, including after a successful checkout removal.

Age is a conservative proxy using the newest mtime of the checkout's `.git` file,
administrative `gitdir` pointer, and available HEAD/branch reflogs. Recent Git
use postpones cleanup; unknown timestamps keep the checkout. No tracking database
or lifecycle hooks are added. The fixed two-day guard cannot be disabled with
`--min-age` (unknown options fail).

Activity checks cover local Herdr desktop space folders and live terminal CWDs,
legacy Herdr pane CWDs when invoked from that runtime, and current-user process
CWDs (`/proc` on Linux; `lsof` on macOS). A process in any subdirectory protects
the checkout. An installed desktop CLI must respond successfully; an unreachable
app, unsupported pane schema, missing `lsof`, or an unreadable process causes the
candidate to be kept with an "activity unknown" reason. Outside legacy Herdr,
its live shells are covered by the process check.

These are best-effort snapshots: they do not see other users or processes hidden
by container/PID namespaces, and a process can start after a check. Use
`stax wt lock branch` for an explicit keep marker, especially across namespaces.
Every candidate is rechecked immediately before removal; a changed HEAD/branch,
new dirty state, or new activity keeps it. Stax receives non-interactive stdin so
a newly dirty checkout cannot be confirmed for forced removal. Save ignored
artifacts before applying. Dry runs print candidates and individual skip reasons.

Stale Git worktree bookkeeping is also pruned after live cleanup. Missing
worktrees with staged changes, interrupted operations or unreadable state block
pruning. Stax prune accepts no expiry argument, so one young/unknown missing
entry retains all stale entries until a later run. The age floor uses the
administrative `gitdir` file mtime. Locked entries remain protected by Git.
Invalid metadata requires manual repair.

For reviewed individual removals, stop the agent, preserve ignored artifacts, then
use `stax wt rm branch`. This retains the branch and its stack relationships.
Do not use `--delete-branch` on a parent with surviving children: in the tested
Stax releases it deletes that branch's metadata without reparenting children.
Review/reparent through Stax separately and validate afterwards. Native
`stax wt cleanup --dry-run` is available as an advisory preview; applying native
bulk cleanup bypasses the age/activity policy above.

Worktrunk Task/Agent custom columns and pane aliases are removed. Herdr's native
agent reporting remains; the status pane refreshes `stax worktree ll` every ten seconds (falling back
to the compact list for bare repositories). `git_status` retains its stack summary and repository/path display.
Historical release-note fixtures and changelog references remain intentionally.

## Migration

1. Review `chezmoi diff` and deploy normally. This PR does not run `chezmoi apply`.
   Managed removal entries retire the old Fish init/completion and global
   Worktrunk config/sync hook. Save local modifications before deployment.
2. Start a fresh Fish shell so the old `wt` function is no longer loaded.
3. Run `mise install` as usual. Worktrunk is no longer requested; remove its
   installed version separately when satisfied (`mise uninstall github:max-sixty/worktrunk`).
4. In each repo, run `stax validate` and inspect `stax wt list`. Keep existing
   worktrees and metadata. Initialize Stax with the correct trunk where needed.
5. Translate repo-local `.config/wt.toml`/other Worktrunk hooks into `stax.toml`.
   Export any Task/Agent variables you want before deleting `.git/wt` state.
   That state is neither required nor automatically deleted by this migration.
6. Existing warm slots from earlier Stax use remain on disk; review them manually.
   Update project overrides if they enable recycling or still invoke `wt`.

## Validation and upstream references

Integration tests use actual Git, Fish and Stax, with temporary local remotes.
Herdr/Zellij transports are stubbed; no running user sessions are changed.
Test the installed Stax version with:

```sh
python -m unittest discover -s tests -p 'test_*work*.py'
python -m unittest discover -s tests -p 'test_git_prune.py'
fish --no-config tests/fish/git_status.fish
fish --no-config tests/fish/zw.fish
fish --no-config scripts/test-herdr-workspace-workflow.fish
```

Contracts inspected/tested against pinned 0.118.2 and current 0.120.0:
[worktrees](https://cesarferreira.com/stax/worktrees/),
[configuration](https://cesarferreira.com/stax/configuration/),
[CLI source](https://github.com/cesarferreira/stax/blob/v0.120.0/src/cli/args.rs),
[hook/removal source](https://github.com/cesarferreira/stax/tree/v0.120.0/src/commands/worktree),
[Worktrunk prune/copy semantics](https://worktrunk.dev/step/).
