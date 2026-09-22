# Mise locks

Use mise **2026.9.12 or newer** (the version used for this v2 migration) and the
configured uv version. Mise 2026.9.11 fixed sidecar resolution through global
lockfile symlinks; older clients cannot use this layout reliably. Linux clients
get mise from `scottames/containers`; the configured Apple Silicon macOS client
gets the checksum-pinned upstream binary from `nix/mise.nix` while nixpkgs lags.
Rebuild the Darwin configuration before applying these dotfiles. The config enforces the
minimum version; keep the lock workflow and container installer aligned because
the baked Aqua registry also carries provenance-verification metadata.

Commit `mise.lock` and `.mise/locks/` together. Sidecars contain the frozen
npm/aube and Python/uv dependency graphs, and their bytes are covered by digests
in `mise.lock`. Let mise generate them; do not auto-format them.

Renovate updates tool declarations. `pr_mise_lock.yaml` owns automated lock
generation and publishes the complete output in a GitHub-verified App commit,
including obsolete-sidecar deletions. The separate vet config retains native
Renovate artifact handling in its own group.

Ordinary `mise lock` preserves locked versions and dependency graphs. The v2
migration used `mise lock --upgrade` once. To intentionally refresh a tool's
transitive dependencies without changing its top-level pin, run
`mise lock --bump <tool>` and review the graph diff. There is no scheduled
transitive-only refresh; generated manifests are excluded from independent
Renovate discovery.

## Global symlinks

Chezmoi links `~/.config/mise/config.toml` and `~/.config/mise/mise.lock` into
this directory. Mise resolves and writes sidecars beside the repository
lockfile. From the live symlinked layout, use `mise lock --global` rather than
project-scope locking.

The old `~/.config/mise/.mise` directory symlink is no longer needed. After
upgrading mise, intentionally remove it **only if** `readlink` shows it points
to this repository's `mise/.mise` directory. Remove the link itself, preserving
its target and both file symlinks. Deleting the Chezmoi source does not remove
an already-deployed link. The existing atomic-write lockfile-symlink repair
helper is still required for that separate behavior.
