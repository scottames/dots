# Pi Extensions

This directory is the declarative source for Pi's reviewed global extensions.
Pi loads only the local paths selected by `current`; it does not install packages
at startup. Pi scopes each local package's module resolution, so the installer
copies pi-starship's hoisted runtime dependencies beside its generated chunks
and replaces its incompatible TOML `createRequire()` bridge with a static import.

| Package | Purpose |
| --- | --- |
| `pi-ask-user` | Structured questions |
| `@narumitw/pi-starship` | Starship-style status line |
| `@tintinweb/pi-subagents` | Subagent workflows |
| `pi-web-search` | Provider-native web search and Gemini URL context |

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
5. Review `chezmoi diff`. After explicit approval, run the normal `chezmoi apply` workflow, confirm `readlink ~/.local/share/pi-extensions/current`, then smoke-test through `nnp`.

Renovate may propose updates but cannot automerge them. Do not run `npm install`
inside `~/.local/share/pi-extensions`; chezmoi owns `current` and its builds.

## Scope And Limits

The approved baseline is only `pi-ask-user@0.15.0`,
`@narumitw/pi-starship@0.55.0`, `@tintinweb/pi-subagents@0.19.0`, and
`pi-web-search@1.4.0` on the current Linux host with Pi 0.85.0,
`pi-local.json`, and the `nono-pi` launcher. All four registry artifacts are
signed with npm key
`SHA256:DhQ8wR5APBvFHLF/+Tc+AYvPOdTpcIDqOhxsBHRwC7U`.

The exact 13-package production closure matches the physical install by path,
name, and version. Every package has registry integrity and a valid registry
signature; eight have verified SLSA attestations. `npm audit` reports zero
known vulnerabilities. No install lifecycle script, native addon, executable
object, WASM payload, non-registry source, or missing integrity is present.
Only `nanoid` and `yaml` expose binaries, and no extension invokes them.

`@narumitw/pi-starship@0.55.0` is approved at integrity
`sha512-jxZfRtDMJHZvCHZg9Sa2tPTAhOBjZsGSTsHPijuoc8BKzpkMJsSc88fQVo0ya4MMSCa/QD9pWFSy03ptEGS08g==`
with SLSA provenance for source commit
`f6b9711f6e208d632703a03282717e63f2223710`. Its locked runtime dependencies
are `@narumitw/pi-tui-kit@0.59.0`, `smol-toml@1.8.0`, and `yaml@2.9.0`;
pi-tui-kit is now hoisted to the install root, and the installer copies all
three into pi-starship's package and generated-chunk module roots. The update
adds provider aliases, thinking styles, prompt-state and terminal-capability
handling, plus a manually invoked configuration skill whose guarded helper can
atomically write `pi-starship.toml`. Its existing optional GitHub module can
invoke authenticated `gh`; the default configuration does not enable it.

`@tintinweb/pi-subagents@0.19.0` is approved at integrity
`sha512-DZsU33Urfb9dhEsJmsmpx0dayIHMYUbxng6AA7B6+bIgspNcTckcSnQRsbrv+QCS7jVKYJTzHIT/j1SU2B/nVQ==`
and source commit `4f572eaa04c09d3dbc16e4a5f13a16b295e84e14`. npm publishes no provenance,
but all shipped source matched that commit and a clean build reproduced all
generated files. Its new `typebox@1.3.28` dependency validates workflow JSON
Schema and is distinct from retained `@sinclair/typebox@0.34.52`; the exact
version is signed, provenance-verified, scriptless, binless, and pure JS/TS.
The new default-on workflow tool runs model-authored scripts in a determinism
boundary, not a security sandbox. Workflows can launch many subagents, read
Nono-readable script paths, persist scripts and journals, and run gate commands
through `sh -c`. These capabilities and the existing transcript, scheduling,
memory, process, worktree, environment, and Pi/Git state authority are accepted
only inside the current Nono-confined single-user workflow. Pi 0.85.0 satisfies
the package's `>=0.84.0` Pi peer floor.

`pi-ask-user@0.15.0` is approved at integrity
`sha512-wmgcHUSGptAS+u+9AT4Fbjxo+iclOXERDym9m/VeX7pDcVs5vwloSKP+BcQ96beuxMEVEhFVydPkXzoYmIvpVQ==`
and source tag commit `705fdc60eaea5b9588f3aa6a6cb6a577516b17af`. npm publishes neither
provenance nor `gitHead`, but all seven signed-artifact files matched that
immutable source. It has no production dependency, lifecycle script, binary,
native code, or WASM. The update adds context-expansion preferences, TypeBox
shim compatibility, and keyboard repeat handling, and reduces answer data sent
to other extensions unless `PI_ASK_USER_EMIT_FULL_EVENTS=true` is set.

`pi-web-search@1.4.0` is approved at integrity
`sha512-PzOeHhadVvMgg3pJ942fT80u6lkud5KLCfYfhf+WChCFl9N1eYAXHZ/FZG7HsLl4ZXylX4iUD3gn8TuJVBrXBQ==`
and source commit `83ac115e87bce29cf4c93af329b94ce5c306eaa8`; all seven artifact files match
source, but npm publishes no provenance. It has no production dependency,
lifecycle script, binary, native code, or WASM. In addition to the existing
OpenAI, Anthropic, and Gemini search paths, it adds Azure OpenAI Responses and
validated GitHub Copilot Enterprise routing and displays collapsed tool results.
It reads Pi's provider credentials and optional web-search configuration and
sends user queries or supplied public URLs to the selected provider. Pi 0.85.0
satisfies its `>=0.80.3` peer floor.

The installer requires Bash 4 or newer; macOS also requires a separate review
and approval before activation. Re-review after changing any package, Pi,
operating system, Nono profile, or launcher. Registry signatures and exact
artifact/source matches establish identity, not benign intent; missing
provenance and unsigned source commits remain evidence limitations.

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
