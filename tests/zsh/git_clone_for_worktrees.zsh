#!/usr/bin/env zsh

set -e
set -o pipefail

repo_root="$(cd "$(dirname "${0}")/../.." && pwd)"
tmpdir="$(mktemp -d)"
fakebin="${tmpdir}/bin"
mise_log="${tmpdir}/mise.log"

cleanup() {
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

mkdir -p "${fakebin}" "${tmpdir}/work" "${tmpdir}/remotes" "${tmpdir}/no-hooks"

cat >"${fakebin}/mise" <<'EOF'
#!/usr/bin/env bash
printf "%s\n" "$PWD $*" >>"$MISE_LOG"
EOF
chmod +x "${fakebin}/mise"

export PATH="${fakebin}:${PATH}"
export MISE_LOG="${mise_log}"

print_info() { printf '%s\n' "$*"; }
print_warn() { printf '%s\n' "$*"; }
print_err() { printf '%s\n' "$*" >&2; }

assert_exists() {
  local path="${1}"
  local message="${2}"

  if [[ ! -e "${path}" ]]; then
    printf 'ASSERTION FAILED: %s\nmissing: %s\n' "${message}" "${path}" >&2
    exit 1
  fi
}

assert_not_exists() {
  local path="${1}"
  local message="${2}"

  if [[ -e "${path}" ]]; then
    printf 'ASSERTION FAILED: %s\nunexpected: %s\n' "${message}" "${path}" >&2
    exit 1
  fi
}

assert_eq() {
  local actual="${1}"
  local expected="${2}"
  local message="${3}"

  if [[ "${actual}" != "${expected}" ]]; then
    printf 'ASSERTION FAILED: %s\nexpected: %s\nactual:   %s\n' "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

assert_fails() {
  local message="${1}"
  shift

  if "$@" >/dev/null 2>/dev/null; then
    printf 'ASSERTION FAILED: %s\ncommand unexpectedly succeeded: %s\n' "${message}" "$*" >&2
    exit 1
  fi
}

make_remote() {
  local remote="${1}"

  git init -b main "${remote}" >/dev/null
  git -C "${remote}" config user.name "Test User"
  git -C "${remote}" config user.email "test@example.com"
  git -C "${remote}" config commit.gpgsign false
  git -C "${remote}" config core.hooksPath "${tmpdir}/no-hooks"
  printf 'hello\n' >"${remote}/README.md"
  printf '[tools]\n' >"${remote}/mise.toml"
  git -C "${remote}" add README.md mise.toml
  git -C "${remote}" commit -m init >/dev/null
}

source "${repo_root}/home/private_dot_zsh/private_functions.zsh"

remote="${tmpdir}/remotes/demo"
other_remote="${tmpdir}/remotes/other"
derived_remote="${tmpdir}/remotes/derived-only.git"
make_remote "${remote}"
make_remote "${other_remote}"
make_remote "${derived_remote}"

(
  cd "${tmpdir}/work"
  git_clone_for_worktrees "${remote}" demo
)

assert_exists "${tmpdir}/work/demo/main/.git" 'default clone creates durable main checkout'
assert_not_exists "${tmpdir}/work/demo/.bare" 'default clone does not create legacy .bare layout'
assert_eq "$(cat "${mise_log}")" "${tmpdir}/work/demo/main trust" 'default clone trusts mise in durable main checkout'

(
  cd "${tmpdir}/work"
  git_clone_for_worktrees "${derived_remote}"
)
assert_exists "${tmpdir}/work/derived-only/main/.git" 'default clone derives repo name from URL'

git clone "${other_remote}" "${tmpdir}/work/demo-normal-mismatch/main" >/dev/null 2>/dev/null
(
  cd "${tmpdir}/work"
  assert_fails 'default clone rejects mismatched existing main checkout' git_clone_for_worktrees "${remote}" demo-normal-mismatch
)

mkdir -p "${tmpdir}/work/demo-existing-bare"
git clone --bare "${remote}" "${tmpdir}/work/demo-existing-bare/.bare" >/dev/null 2>/dev/null
(
  cd "${tmpdir}/work"
  assert_fails 'default clone rejects existing legacy .bare layout' git_clone_for_worktrees "${remote}" demo-existing-bare
)

mkdir -p "${tmpdir}/work/demo-bare-mismatch"
git clone --bare "${other_remote}" "${tmpdir}/work/demo-bare-mismatch/.bare" >/dev/null 2>/dev/null
(
  cd "${tmpdir}/work"
  assert_fails 'bare mode rejects mismatched existing .bare repository' git_clone_for_worktrees --bare "${remote}" demo-bare-mismatch
)

printf '' >"${mise_log}"
(
  cd "${tmpdir}/work"
  git_clone_for_worktrees --bare "${remote}" demo-bare
)

assert_exists "${tmpdir}/work/demo-bare/.bare" 'bare mode creates legacy .bare repository'
assert_exists "${tmpdir}/work/demo-bare/main/.git" 'bare mode creates initial main worktree'
assert_eq "$(cat "${tmpdir}/work/demo-bare/.git")" 'gitdir: ./.bare' 'bare mode writes gitdir pointer'
assert_eq "$(cat "${mise_log}")" "${tmpdir}/work/demo-bare/main trust" 'bare mode trusts mise in initial main worktree'

git clone "${remote}" "${tmpdir}/work/demo-existing-normal/main" >/dev/null 2>/dev/null
(
  cd "${tmpdir}/work"
  assert_fails 'bare mode rejects existing normal main checkout' git_clone_for_worktrees --bare "${remote}" demo-existing-normal
)

printf 'ok\n'
