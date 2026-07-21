# Pi Extensions

This directory is the declarative source for Pi's reviewed global extensions.
Pi loads only the local paths selected by `current`; it does not install packages
at startup.

| Package | Purpose |
| --- | --- |
| `pi-ask-user` | Structured questions |
| `@narumitw/pi-statusline` | Status line |
| `@tintinweb/pi-subagents` | Subagent workflows |

`package.json` pins the direct versions. `package-lock.json` pins the complete
npm registry closure and its artifact integrity hashes. The chezmoi script
installs that lock in a new hash-named directory with lifecycle scripts disabled,
then switches `current` only after success. Previous builds are retained so a
running Pi session keeps its files.

## Update Checklist

1. Change one exact version in `package.json`.
2. Regenerate the lock from this directory with `npm install --registry=https://registry.npmjs.org/ --legacy-peer-deps --package-lock-only --ignore-scripts`.
3. Review the upstream source diff, exact tarball, package capabilities, and full lock diff. Stop for an unexplained new dependency, lifecycle script, binary, native/WASM component, network access, credential access, or Pi hook.
4. Run `bash scripts/test-pi-extension-supply-chain.sh` and a disposable `npm ci --ignore-scripts --legacy-peer-deps --omit=dev`.
5. Review `chezmoi diff`. After explicit approval, run the normal `chezmoi apply` workflow, confirm `readlink ~/.local/share/pi-extensions/current`, then smoke-test through `nono-pi`.

Renovate may propose updates but cannot automerge them. Do not run `npm install`
inside `~/.local/share/pi-extensions`; chezmoi owns `current` and its builds.

## Scope And Limits

The approved baseline is only `pi-ask-user@0.13.0`,
`@narumitw/pi-statusline@0.16.0`, and `@tintinweb/pi-subagents@0.14.2` on the
current Linux host with Pi 0.80.10, `pi-local.json`, and the `nono-pi` launcher.
It accepts the expected terminal-rendering risk and that the subagents run
in-process with Pi's environment and Nono-authorized authority. Upstream
defaults keep transcripts and scheduling enabled; transcripts use Nono's
private `TMPDIR`, and project schedules, optional memory, and explicit
worktree mode can write Pi or Git state. The installer is portable to macOS,
but macOS requires a separate review and approval before activation. Re-review
after changing any package, Pi, operating system, Nono profile, or launcher.

The lock and review establish the identity of downloaded artifacts; they do not
prove an extension is benign. Extensions execute inside Pi with Pi's authority.
Nono confines the aggregate process, not individual extensions. Supported
launches keep this tree read-only, but `~/.pi` remains writable runtime state, so
the local-only settings are a managed-configuration boundary rather than an
immutable security boundary.

## Add Or Remove

An extension is an explicit approval change. Update `package.json`, the local
package path list in `home/private_dot_pi/agent/settings.json.tmpl`, and the
manifest-derived package-path checks in
`scripts/test-pi-extension-supply-chain.sh`; then perform the update checklist
and record a new approval.

If `current` is missing, rerun the approved chezmoi apply workflow. If a build
is incomplete, remove only that hash-named directory after confirming Pi is not
using it, then apply again.
