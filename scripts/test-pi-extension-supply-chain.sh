#!/usr/bin/env bash

# Verifies the reviewed Pi extension lock and installer keep package selection
# manifest-driven, so updates cannot silently diverge across the local workflow.
set -eufo pipefail

repo_root="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
extension_source="${repo_root}/home/dot_local/share/private_pi-extensions"
manifest="${extension_source}/package.json"
lockfile="${extension_source}/package-lock.json"
installer="${repo_root}/home/.chezmoiscripts/run_before_52_pi_extensions.sh.tmpl"
settings="${repo_root}/home/private_dot_pi/agent/settings.json.tmpl"
profile="${repo_root}/home/private_dot_config/nono/profiles/pi-local.json.tmpl"
wrapper="${repo_root}/home/dot_local/bin/executable_nono-pi"
local_path_wrapper="${repo_root}/home/dot_local/bin/executable_nono-with-local-path"

fail() {
  printf 'ASSERTION FAILED: %s\n' "$1" >&2
  exit 1
}

for required in "${manifest}" "${lockfile}" "${installer}" "${settings}" "${profile}" "${wrapper}" "${local_path_wrapper}"; do
  [[ -f ${required} ]] || fail "missing ${required#"${repo_root}/"}"
done

node - "${manifest}" "${lockfile}" <<'NODE'
const assert = require('node:assert/strict');
const fs = require('node:fs');

const manifest = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const lockfile = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));
const expected = manifest.dependencies;

assert.equal(manifest.private, true);
assert.ok(Object.keys(expected).length > 0, 'manifest has no extensions');
assert.deepEqual(manifest.dependencies, expected);
assert.deepEqual(lockfile.packages[''].dependencies, expected);
for (const version of Object.values(expected)) {
  assert.match(version, /^\d+\.\d+\.\d+$/, `${version} is not an exact version`);
}
for (const [location, pkg] of Object.entries(lockfile.packages)) {
  if (location === '') continue;
  assert.ok(pkg.integrity, `${location} has no integrity`);
  assert.match(pkg.resolved, /^https:\/\/registry\.npmjs\.org\//, `${location} is not an npmjs artifact`);
}
NODE

mapfile -t extension_packages < <(
  node - "${manifest}" <<'NODE'
const fs = require('node:fs');

const manifest = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
for (const name of Object.keys(manifest.dependencies)) console.log(name);
NODE
)

fixture_dir="$(mktemp -d)"
trap 'rm -rf -- "${fixture_dir}"' EXIT
fixture_home="${fixture_dir}/home"

render() {
  HOME="${fixture_home}" chezmoi --source "${repo_root}" execute-template <"$1"
}

settings_json="$(render "${settings}")"
profile_json="$(render "${profile}")"

SETTINGS_JSON="${settings_json}" PROFILE_JSON="${profile_json}" HOME_DIR="${fixture_home}" node - "${manifest}" <<'NODE'
const assert = require('node:assert/strict');
const fs = require('node:fs');

const settings = JSON.parse(process.env.SETTINGS_JSON);
const profile = JSON.parse(process.env.PROFILE_JSON);
const root = `${process.env.HOME_DIR}/.local/share/pi-extensions`;
const manifest = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));

assert.equal(settings.defaultProjectTrust, 'ask');
assert.ok(!Object.hasOwn(settings, 'npmCommand'));
assert.deepEqual(
  [...settings.packages].sort(),
  Object.keys(manifest.dependencies)
    .map((name) => `${root}/current/node_modules/${name}`)
    .sort(),
);
assert.equal(profile.extends, 'pi');
assert.ok(profile.filesystem.read.includes(root));
assert.ok(!profile.filesystem.allow.includes(root));
assert.ok(profile.filesystem.read.includes('/proc'));
assert.ok(profile.filesystem.read.includes(`${process.env.HOME_DIR}/.config/mise`));
assert.ok(profile.filesystem.read_file.includes(`${process.env.HOME_DIR}/.config/agents/AGENTS.md`));
assert.ok(profile.filesystem.allow.includes(`${process.env.HOME_DIR}/.npm`));
assert.ok(!Object.hasOwn(profile, 'groups'));
assert.deepEqual(profile.security, {
  signal_mode: 'allow_same_sandbox',
  capability_elevation: false,
});
assert.ok(!Object.hasOwn(profile, 'network'));
assert.ok(!Object.hasOwn(profile, 'workdir'));
assert.ok(!Object.hasOwn(profile, 'open_urls'));
assert.ok(!Object.hasOwn(profile, 'allow_launch_services'));
assert.ok(!Object.hasOwn(profile, 'rollback'));
assert.ok(!Object.hasOwn(profile, 'undo'));
NODE

extensions_dir="${fixture_home}/.local/share/pi-extensions"
old_build="${extensions_dir}/installs/old"
stub_bin="${fixture_dir}/bin"
mkdir -p "${old_build}/node_modules" "${stub_bin}" "${fixture_dir}/project"
ln -s "${old_build}" "${extensions_dir}/current"

installer_fixture="${fixture_dir}/installer.sh"
render "${installer}" >"${installer_fixture}"
installer_contents="$(<"${installer_fixture}")"
installer_template_contents="$(<"${installer}")"
[[ ${installer_contents} == *'mise exec -- npm'* ]] || fail 'installer does not use the Mise-managed npm version'
[[ ${installer_contents} == *'mise exec -- node'* ]] || fail 'installer does not use the Mise-managed Node version'
[[ ${installer_contents} == *"mise exec -- node - \"\${staging_dir}/package.json\""* ]] || fail 'installer does not validate the staged manifest'
[[ ${installer_contents} != *'node@'* ]] || fail 'installer pins a Node version outside Mise configuration'
[[ ${installer_contents} == *'fs.renameSync('* ]] || fail 'installer does not atomically replace current'
for package in "${extension_packages[@]}"; do
  [[ ${installer_template_contents} != *"${package}"* ]] || fail "installer duplicates manifest package ${package}"
done

package_list="${fixture_dir}/packages"
printf '%s\n' "${extension_packages[@]}" >"${package_list}"

cat >"${stub_bin}/mise" <<'STUB'
#!/usr/bin/env bash
[[ $1 == exec ]] || exit 2
shift
[[ $1 == -- ]] || exit 2
shift
[[ $1 == node ]] || exit 2
printf 'manifest runtime unavailable\n' >&2
exit 1
STUB
cat >"${stub_bin}/nono-with-local-path" <<'STUB'
#!/usr/bin/env bash
printf '%s\n%s\n%s\n' "${TMPDIR-}" "${PI_SUBAGENTS_WORKTREE_DIR-}" "${PI_SUBAGENT_PI_BINARY-}" >"${NONO_TMPDIR_MARKER}"
[[ -z "${NONO_REACHED_MARKER-}" ]] || touch "${NONO_REACHED_MARKER}"
STUB
real_git="$(command -v git)"
cat >"${stub_bin}/git" <<STUB
#!/usr/bin/env bash
if [[ \${STUB_GIT_FAIL-} == 1 ]]; then
  exit 1
fi
exec "${real_git}" "\$@"
STUB
cat >"${stub_bin}/realpath" <<'STUB'
#!/usr/bin/env bash
exit 127
STUB
chmod +x "${stub_bin}/mise" "${stub_bin}/nono-with-local-path" "${stub_bin}/git" "${stub_bin}/realpath"

local_path_capture="${fixture_dir}/local-path-args"
cat >"${stub_bin}/nono" <<'STUB'
#!/usr/bin/env bash
printf '%s\0' "$@" >"${NONO_ARGS_CAPTURE}"
STUB
chmod +x "${stub_bin}/nono"

local_path_repo_parent="${fixture_dir}/git-parent"
local_path_repo="${local_path_repo_parent}/main"
mkdir -p "${local_path_repo}/nested" "${fixture_dir}/project"
git -C "${local_path_repo}" init --quiet
(
  cd "${local_path_repo}/nested"
  BASH_ENV=/dev/null HOME="${fixture_home}" HOME_LOCAL_BIN="${stub_bin}/home-bin" MISE_SHIMS_DIR="${stub_bin}/mise-shims" PATH="${stub_bin}:${PATH}" NONO_ARGS_CAPTURE="${local_path_capture}" bash "${local_path_wrapper}" wrap --profile pi-local --allow-cwd -- pi --version
)
python - "${local_path_capture}" "${local_path_repo_parent}" <<'PY'
import sys
from pathlib import Path

args = Path(sys.argv[1]).read_bytes().split(b'\0')[:-1]
expected_parent = sys.argv[2].encode()
assert b'--allow-cwd' in args, args
allow_index = args.index(b'--allow')
separator_index = args.index(b'--')
assert allow_index < separator_index, args
assert args[allow_index + 1] == expected_parent, args
PY

(
  cd "${local_path_repo}/nested"
  BASH_ENV=/dev/null HOME="${fixture_home}" HOME_LOCAL_BIN="${stub_bin}/home-bin" MISE_SHIMS_DIR="${stub_bin}/mise-shims" PATH="${stub_bin}:${PATH}" NONO_ARGS_CAPTURE="${local_path_capture}" bash "${local_path_wrapper}" wrap --profile pi-local -- pi --version
)
python - "${local_path_capture}" <<'PY'
import sys
from pathlib import Path

args = Path(sys.argv[1]).read_bytes().split(b'\0')[:-1]
assert b'--allow' not in args, args
PY

(
  cd "${local_path_repo}/nested"
  BASH_ENV=/dev/null HOME="${fixture_home}" HOME_LOCAL_BIN="${stub_bin}/home-bin" MISE_SHIMS_DIR="${stub_bin}/mise-shims" PATH="${stub_bin}:${PATH}" NONO_ARGS_CAPTURE="${local_path_capture}" bash "${local_path_wrapper}" wrap --profile pi-local --allow-cwd --allow "${local_path_repo_parent}" -- pi --version
)
python - "${local_path_capture}" <<'PY'
import sys
from pathlib import Path

args = Path(sys.argv[1]).read_bytes().split(b'\0')[:-1]
assert args.count(b'--allow') == 1, args
PY

nono_tmpdir_marker="${fixture_dir}/nono-tmpdir"
(
  cd "${fixture_dir}/project"
  BASH_ENV=/dev/null HOME="${fixture_home}" PATH="${stub_bin}:${PATH}" NONO_TMPDIR_MARKER="${nono_tmpdir_marker}" STUB_GIT_FAIL=1 bash "${wrapper}"
)
expected_tmpdir="${fixture_home}/.pi/agent/tmp"
mapfile -t wrapper_environment <"${nono_tmpdir_marker}"
[[ ${wrapper_environment[0]} == "${expected_tmpdir}" ]] || fail 'wrapper does not use a private Pi temp directory'
[[ -z ${wrapper_environment[1]} ]] || fail 'wrapper sets PI_SUBAGENTS_WORKTREE_DIR'
[[ -z ${wrapper_environment[2]} ]] || fail 'wrapper sets PI_SUBAGENT_PI_BINARY'
node - "${expected_tmpdir}" <<'NODE'
const assert = require('node:assert/strict');
const fs = require('node:fs');

assert.equal(fs.statSync(process.argv[2]).mode & 0o777, 0o700, 'private Pi temp directory mode');
NODE

set +e
HOME="${fixture_home}" PATH="${stub_bin}:${PATH}" bash "${installer_fixture}" >"${fixture_dir}/installer-output" 2>&1
installer_status=$?
set -e
[[ ${installer_status} -ne 0 ]] || fail 'failed manifest inspection must fail the installer'
[[ $(<"${fixture_dir}/installer-output") == *'manifest runtime unavailable'* ]] || fail 'installer hid the manifest inspection failure'
[[ $(<"${fixture_dir}/installer-output") != *'Pi extension manifest has no dependencies'* ]] || fail 'installer masked the manifest inspection failure'
[[ $(readlink "${extensions_dir}/current") == "${old_build}" ]] || fail 'failed manifest inspection replaced current'

cat >"${stub_bin}/mise" <<'STUB'
#!/usr/bin/env bash
[[ $1 == exec ]] || exit 2
shift
[[ $1 == -- ]] || exit 2
shift
case "$1" in
  node)
    shift
    exec node "$@"
    ;;
  npm)
    printf 'npm install unavailable\n' >&2
    exit 1
    ;;
  *) exit 2 ;;
esac
STUB

set +e
HOME="${fixture_home}" PATH="${stub_bin}:${PATH}" bash "${installer_fixture}" >"${fixture_dir}/npm-output" 2>&1
installer_status=$?
set -e
[[ ${installer_status} -ne 0 ]] || fail 'failed npm install must fail the installer'
[[ $(<"${fixture_dir}/npm-output") == *'npm install unavailable'* ]] || fail 'installer did not reach npm install'
[[ $(readlink "${extensions_dir}/current") == "${old_build}" ]] || fail 'failed npm install replaced current'

cat >"${stub_bin}/mise" <<'STUB'
#!/usr/bin/env bash
[[ $1 == exec ]] || exit 2
shift
[[ $1 == -- ]] || exit 2
shift
case "$1" in
  npm)
    prefix=''
    while [[ $# -gt 0 ]]; do
      if [[ $1 == --prefix ]]; then
        prefix="$2"
        shift 2
      else
        shift
      fi
    done
    while IFS= read -r package; do
      mkdir -p "${prefix}/node_modules/${package}"
    done <"${PI_EXTENSION_PACKAGES_FILE}"
    ;;
  node)
    shift
    exec node "$@"
    ;;
  *) exit 2 ;;
esac
STUB

PI_EXTENSION_PACKAGES_FILE="${package_list}" HOME="${fixture_home}" PATH="${stub_bin}:${PATH}" bash "${installer_fixture}" >"${fixture_dir}/success-output" 2>&1
[[ $(readlink "${extensions_dir}/current") != "${old_build}" ]] || fail "successful install did not replace current: $(<"${fixture_dir}/success-output")"
for package in "${extension_packages[@]}"; do
  [[ -d ${extensions_dir}/current/node_modules/${package} ]] || fail "current is missing ${package}"
done

set +e
(
  cd "${fixture_home}"
  HOME="${fixture_home}" PATH="${stub_bin}:${PATH}" NONO_REACHED_MARKER="${fixture_dir}/nono-reached" bash "${wrapper}"
) >"${fixture_dir}/wrapper-output" 2>&1
wrapper_status=$?
set -e
[[ ${wrapper_status} -ne 0 ]] || fail 'wrapper accepted an extension-tree ancestor as cwd'
[[ $(<"${fixture_dir}/wrapper-output") == *'refusing writable access to the Pi extension tree'* ]] || fail 'wrapper did not reach the overlap check'
[[ ! -e ${fixture_dir}/nono-reached ]] || fail 'wrapper reached nono with writable extension-tree access'

printf 'Pi extension supply-chain checks passed\n'
