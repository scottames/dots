#!/usr/bin/env bash
# Exercise the real rendered installer without installing or executing plugins.
set -eufo pipefail
repo_root="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
chezmoi_bin="$(command -v chezmoi)"
fixture="$(mktemp -d)"
trap 'rm -rf -- "${fixture}"' EXIT
home="${fixture}/home"
plugin_root="${home}/.local/share/herdr-annotate"
installer="${repo_root}/home/.chezmoiscripts/run_onchange_after_54_herdr_plugins.sh.tmpl"
wrapper="${repo_root}/home/dot_local/share/herdr-annotate/scripts/executable_plannotator-tui.sh"
mkdir -p "${plugin_root}" "${fixture}/bin" "${fixture}/source/home" "${fixture}/source/mise"
fail() {
	printf 'ASSERTION FAILED: %s\n' "$*" >&2
	exit 1
}
python3 - "${repo_root}/mise/config.toml" >"${fixture}/pins" <<'PY'
import sys, tomllib
with open(sys.argv[1], 'rb') as source:
    tools = tomllib.load(source)['tools']
for tool in ('plannotator/herdr-annotate', 'plannotator/plannotator-tui', 'ogulcancelik/herdr'):
    pin = tools['github:' + tool]
    print(pin['version'] if isinstance(pin, dict) else pin)
PY
mapfile -t pins <"${fixture}/pins"
[[ ${#pins[@]} == 3 ]] || fail 'could not read mise pins'
[[ -f ${wrapper} ]] || fail 'missing plannotator-tui wrapper'
annotate_version="${pins[0]}" tui_version="${pins[1]}" herdr_version="${pins[2]}"
render() {
	env -i HOME="${home}" PATH=/usr/bin:/bin BASH_ENV=/dev/null "${chezmoi_bin}" \
		--config /dev/null --config-format toml --source "$1" --destination "${home}" \
		--override-data '{"me":{"user":"root","git":{"transport":"https"},"gravatar":{"id":"fixture"}}}' \
		execute-template <"$2"
}
render "${repo_root}" "${installer}" >"${fixture}/installer.sh"
render "${repo_root}" "${repo_root}/home/.chezmoiexternals/herdr.toml.tmpl" >"${fixture}/external.toml"

# A build hook must never run; the fake herdr rejects install, not just its effects.
printf '%s\n' '[plugin]' 'name = "annotate"' 'version = "0.0.0"' \
	'[build]' 'command = "exit 97"' >"${plugin_root}/herdr-plugin.toml"
cat >"${fixture}/forbidden" <<'STUB'
#!/usr/bin/env bash
touch "${FIXTURE}/executed"; exit 99
STUB
cat >"${fixture}/herdr" <<'STUB'
#!/usr/bin/env bash
set -eufo pipefail
[[ $# == 3 && $1 == plugin && $2 == link && $3 == "${PLUGIN_ROOT}" ]] || exit 98
printf 'linked\n' >>"${FIXTURE}/registered"
[[ ${FAULT} != registration ]] || { printf 'registration failed\n' >&2; exit 43; }
STUB
cat >"${fixture}/bin/mise" <<'STUB'
#!/usr/bin/env bash
set -eufo pipefail
[[ $# == 4 && $1 == which && $2 == --tool ]] || exit 98
case "$3 $4" in
  "github:plannotator/herdr-annotate@${ANNOTATE_VERSION} herdr-annotate") version="${ANNOTATE_VERSION}" ;;
  "github:plannotator/plannotator-tui@${TUI_VERSION} plannotator-tui") version="${TUI_VERSION}" ;;
  "github:ogulcancelik/herdr@${HERDR_VERSION} herdr") version="${HERDR_VERSION}" ;;
  *) printf 'unexpected mise arguments: %s\n' "$*" >&2; exit 98 ;;
esac
[[ ${FAULT} != "resolve:$4" ]] || { printf 'resolution failed\n' >&2; exit 42; }
bin="${FIXTURE}/versions/${version}/$4"
[[ ${FAULT} != "missing:$4" ]] || bin="${bin}.missing"
printf '%s\n' "${bin}"
STUB
chmod +x "${fixture}/bin/mise"
seed() {
	printf '%s\n' "${annotate_version#rust-lite-v}" >"${plugin_root}/herdr-annotate.version"
	printf '%s\n' "${tui_version#v}" >"${plugin_root}/plannotator-tui.version"
	for entry in "${annotate_version}/herdr-annotate" "${tui_version}/plannotator-tui" "${herdr_version}/herdr"; do
		mkdir -p "${fixture}/versions/${entry%/*}"
		cp "${fixture}/forbidden" "${fixture}/versions/${entry}"
		chmod +x "${fixture}/versions/${entry}"
	done
	cp "${fixture}/herdr" "${fixture}/versions/${herdr_version}/herdr"
}
run() {
	status=0
	env -i HOME="${home}" PATH="${fixture}/bin:/usr/bin:/bin" BASH_ENV=/dev/null \
		FIXTURE="${fixture}" PLUGIN_ROOT="${plugin_root}" FAULT="${1-}" \
		ANNOTATE_VERSION="${annotate_version}" TUI_VERSION="${tui_version}" HERDR_VERSION="${herdr_version}" \
		bash "${fixture}/installer.sh" >"${fixture}/output" 2>&1 || status=$?
	[[ ! -e ${fixture}/executed ]] || fail 'provisioning executed a plugin binary'
}
links() {
	python3 - "${plugin_root}/bin" <<'PY'
import sys
from pathlib import Path
for path in sorted(Path(sys.argv[1]).iterdir()):
    print(path.name, path.lstat().st_ino, path.readlink())
PY
}
assert_targets() {
	[[ $(readlink "${plugin_root}/bin/herdr-annotate.exe") == "${fixture}/versions/${annotate_version}/herdr-annotate" ]] || fail 'wrong annotate target'
	[[ $(readlink "${plugin_root}/bin/plannotator-tui.exe") == "${fixture}/versions/${tui_version}/plannotator-tui" ]] || fail 'wrong tui target'
}
seed
run missing:herdr
[[ ${status} != 0 && ! -e ${fixture}/registered && ! -e ${plugin_root}/bin ]] || fail 'missing binary changed a fresh installation'
run
[[ ${status} == 0 && $(<"${fixture}/registered") == linked ]] || fail "first registration: $(<"${fixture}/output")"
assert_targets
run
[[ ${status} == 0 && $(<"${fixture}/registered") == $'linked\nlinked' ]] || fail 'repeat registration failed'
assert_targets
before="$(links)"
registered="$(<"${fixture}/registered")"
# A destination override must not mutate the original HOME's plugin registration.
cp "${fixture}/installer.sh" "${fixture}/installer.saved"
env -i HOME="${home}" PATH=/usr/bin:/bin BASH_ENV=/dev/null "${chezmoi_bin}" \
	--config /dev/null --config-format toml --source "${repo_root}" \
	--destination "${fixture}/other-home" execute-template <"${installer}" >"${fixture}/installer.sh"
run
[[ ${status} != 0 && $(<"${fixture}/output") == *'destination to be HOME'* ]] || fail 'alternate destination was accepted'
after="$(links)"
[[ ${after} == "${before}" && $(<"${fixture}/registered") == "${registered}" ]] || fail 'alternate destination changed installation'
mv "${fixture}/installer.saved" "${fixture}/installer.sh"
for name in herdr-annotate plannotator-tui herdr; do
	for mode in missing resolve; do
		run "${mode}:${name}"
		[[ ${status} != 0 ]] || fail "${mode}:${name} succeeded"
		[[ ${mode} != resolve || ${status} == 42 ]] || fail 'mise failure status lost'
		after="$(links)"
		[[ ${after} == "${before}" && $(<"${fixture}/registered") == "${registered}" ]] || fail "${mode}:${name} changed installation"
		[[ ${mode} != missing || $(<"${fixture}/output") == *'Missing mise binary:'* ]] || fail 'missing binary diagnosis lost'
	done
done
for name in herdr-annotate plannotator-tui; do
	cp "${plugin_root}/${name}.version" "${fixture}/version.saved"
	printf '0.0.0-mismatch\n' >"${plugin_root}/${name}.version"
	run
	[[ ${status} != 0 && $(<"${fixture}/output") == *'source and mise binary pins do not match'* ]] || fail "${name} mismatch diagnosis lost"
	after="$(links)"
	[[ ${after} == "${before}" && $(<"${fixture}/registered") == "${registered}" ]] || fail 'metadata mismatch changed installation'
	cp "${fixture}/version.saved" "${plugin_root}/${name}.version"
done
run registration
[[ ${status} == 43 && $(<"${fixture}/output") == *'registration failed'* ]] || fail 'registration failure not propagated'

# Minimal copied source keeps mutation tests offline and leaves the repository intact.
mkdir -p "${fixture}/source/home/.chezmoiexternals"
cp "${repo_root}/home/.chezmoiexternals/herdr.toml.tmpl" "${fixture}/source/home/.chezmoiexternals/"
cp "${repo_root}/mise/mise.lock" "${fixture}/source/mise/"
annotate_version="${annotate_version}-fixture" tui_version="${tui_version}-fixture"
printf '[tools]\n"github:plannotator/herdr-annotate" = { version = "%s" }\n"github:plannotator/plannotator-tui" = { version = "%s" }\n"github:ogulcancelik/herdr" = "%s"\n' \
	"${annotate_version}" "${tui_version}" "${herdr_version}" >"${fixture}/source/mise/config.toml"
render "${fixture}/source/home" "${installer}" >"${fixture}/updated.sh"
cmp -s "${fixture}/installer.sh" "${fixture}/updated.sh" && fail 'binary pin change did not alter rendered installer'
mv "${fixture}/updated.sh" "${fixture}/installer.sh"
seed
run
[[ ${status} == 0 ]] || fail "version update: $(<"${fixture}/output")"
assert_targets
python3 - "${fixture}/source/home/.chezmoiexternals/herdr.toml.tmpl" <<'PY'
import re, sys
from pathlib import Path
path = Path(sys.argv[1])
source, count = re.subn(r'(\$herdrAnnotateRef := ")[0-9a-f]{40}', r'\g<1>' + 'f' * 40, path.read_text())
assert count == 1, 'expected one source pin'
path.write_text(source)
PY
render "${fixture}/source/home" "${installer}" >"${fixture}/updated.sh"
python3 - "${fixture}/installer.sh" "${fixture}/updated.sh" <<'PY'
import sys
from pathlib import Path
before, after = (Path(p).read_text().splitlines() for p in sys.argv[1:])
changes = [(a, b) for a, b in zip(before, after) if a != b]
assert len(before) == len(after) and len(changes) == 1, 'source pin must alter render checksum'
assert all(line.startswith('# External source pins: ') for line in changes[0])
PY

# Exercise chezmoi's real archive filtering without downloads or apply.
python3 - "${fixture}" <<'PY'
import io, json, sys, tarfile, tomllib
from pathlib import Path
root = Path(sys.argv[1])
external = tomllib.loads((root / 'external.toml').read_text())['.local/share/herdr-annotate']
assert external['type'] == 'archive' and external['stripComponents'] == 1
assert not external.get('exact', False), 'external would remove installer-owned bin symlinks'
assert set(external['include']) == {
    '*/herdr-plugin.toml', '*/herdr-annotate.version',
    '*/plannotator-tui.version',
}, 'external must exclude upstream build scripts and binaries'
with tarfile.open(root / 'upstream.tar.gz', 'w:gz') as archive:
    for name in ('herdr-plugin.toml', 'herdr-annotate.version', 'plannotator-tui.version',
                 'scripts/plannotator-tui.sh', 'scripts/build.sh', 'bin/herdr-annotate.exe'):
        entry = tarfile.TarInfo('upstream/' + name)
        entry.size = len(b'fixture\n')
        archive.addfile(entry, io.BytesIO(b'fixture\n'))
external['url'] = (root / 'upstream.tar.gz').as_uri()
source = root / 'external-source'
source.mkdir()
(source / '.chezmoiexternal.toml').write_text('[".local/share/herdr-annotate"]\n' +
    ''.join(f'{key} = {json.dumps(value)}\n' for key, value in external.items()))
wrapper = source / 'dot_local/share/herdr-annotate/scripts/executable_plannotator-tui.sh'
wrapper.parent.mkdir(parents=True)
wrapper.write_text('#!/usr/bin/env bash\nexit 0\n')
PY
before="$(links)"
env -i HOME="${home}" PATH=/usr/bin:/bin BASH_ENV=/dev/null "${chezmoi_bin}" \
	--config /dev/null --config-format toml --source "${fixture}/external-source" \
	--destination "${home}" --no-pager apply --dry-run "${plugin_root}" >"${fixture}/apply"
for operation in archive diff; do
	env -i HOME="${home}" PATH=/usr/bin:/bin BASH_ENV=/dev/null "${chezmoi_bin}" \
		--config /dev/null --config-format toml --source "${fixture}/external-source" \
		--destination "${home}" --no-pager "${operation}" "${plugin_root}" >"${fixture}/${operation}"
done
python3 - "${fixture}/archive" "${fixture}/diff" <<'PY'
import sys, tarfile
from pathlib import Path
with tarfile.open(sys.argv[1]) as archive:
    names = {member.name.removeprefix('.local/share/herdr-annotate/') for member in archive if member.isfile()}
assert names == {'herdr-plugin.toml', 'herdr-annotate.version', 'plannotator-tui.version', 'scripts/plannotator-tui.sh'}, names
assert 'bin/' not in Path(sys.argv[2]).read_text(), 'external diff would modify bin symlinks'
PY
after="$(links)"
[[ ${after} == "${before}" ]] || fail 'external inspection modified links'
printf 'Herdr plugin provisioning checks passed\n'
