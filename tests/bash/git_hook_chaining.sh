#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
pre_commit_hook="${repo_root}/home/private_dot_config/git/hooks/executable_pre-commit"
commit_msg_hook="${repo_root}/home/private_dot_config/git/hooks/executable_commit-msg"
tmpdir="$(mktemp -d)"

cleanup() {
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

export HOME="${tmpdir}/home"
export GIT_CONFIG_GLOBAL=/dev/null

mkdir -p "${HOME}"

assert_file_contains() {
  local file="${1}"
  local expected="${2}"
  local message="${3}"

  if [[ ! -f ${file} ]] || ! grep -qF -- "${expected}" "${file}"; then
    printf 'ASSERTION FAILED: %s\nexpected to find: %s\n' "${message}" "${expected}" >&2
    if [[ -f ${file} ]]; then
      printf 'actual:\n' >&2
      sed 's/^/  /' "${file}" >&2
    else
      printf 'actual: file missing\n' >&2
    fi
    exit 1
  fi
}

assert_eq() {
  local actual="${1}"
  local expected="${2}"
  local message="${3}"

  if [[ ${actual} != "${expected}" ]]; then
    printf 'ASSERTION FAILED: %s\nexpected: %s\nactual:   %s\n' "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

init_repo() {
  local repo="${1}"

  git init -b main "${repo}" >/dev/null
  git -C "${repo}" config user.name 'Test User'
  git -C "${repo}" config user.email test@example.com
  git -C "${repo}" config commit.gpgsign false
  printf 'hello\n' >"${repo}/README.md"
  git -C "${repo}" add README.md
  git -C "${repo}" commit -m init >/dev/null
}

write_local_hook() {
  local hook_path="${1}"
  local marker="${2}"
  local text="${3}"
  local quoted_marker
  local quoted_text

  printf -v quoted_marker '%q' "${marker}"
  printf -v quoted_text '%q' "${text}"

  mkdir -p "$(dirname "${hook_path}")"
  printf '%s\n' '#!/usr/bin/env bash' \
    "printf '%s\\n' ${quoted_text} >>${quoted_marker}" >"${hook_path}"
  chmod +x "${hook_path}"
}

write_commit_msg_hook() {
  local hook_path="${1}"
  local marker="${2}"
  local text="${3}"
  local expected_message_file="${4}"
  local quoted_expected_message_file
  local quoted_marker
  local quoted_text

  printf -v quoted_expected_message_file '%q' "${expected_message_file}"
  printf -v quoted_marker '%q' "${marker}"
  printf -v quoted_text '%q' "${text}"

  mkdir -p "$(dirname "${hook_path}")"
  printf '%s\n' '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    '[[ $# -eq 1 ]]' \
    "[[ \${1} == ${quoted_expected_message_file} ]]" \
    "grep -qF -- 'test message' \"\${1}\"" \
    "printf '%s\\n' ${quoted_text} >>${quoted_marker}" >"${hook_path}"
  chmod +x "${hook_path}"
}

write_failing_hook() {
  local hook_path="${1}"
  local status="${2}"

  mkdir -p "$(dirname "${hook_path}")"
  printf '%s\n' '#!/usr/bin/env bash' \
    "exit ${status}" >"${hook_path}"
  chmod +x "${hook_path}"
}

run_pre_commit_from() {
  local worktree="${1}"

  printf 'change\n' >"${worktree}/change.txt"
  git -C "${worktree}" add change.txt
  (cd "${worktree}" && bash "${pre_commit_hook}")
}

run_commit_msg_from() {
  local worktree="${1}"
  local message_file="${worktree}/COMMIT_EDITMSG.test"

  printf 'test message\n' >"${message_file}"
  (cd "${worktree}" && bash "${commit_msg_hook}" "${message_file}")
}

normal_repo="${tmpdir}/normal-repo"
normal_marker="${tmpdir}/normal-hooks.log"
normal_message_file="${normal_repo}/COMMIT_EDITMSG.test"
init_repo "${normal_repo}"
write_local_hook "${normal_repo}/.git/hooks/pre-commit" "${normal_marker}" 'normal pre-commit'
write_commit_msg_hook "${normal_repo}/.git/hooks/commit-msg" "${normal_marker}" 'normal commit-msg' "${normal_message_file}"

run_pre_commit_from "${normal_repo}"
run_commit_msg_from "${normal_repo}"
assert_file_contains "${normal_marker}" 'normal pre-commit' 'pre-commit chains local hook when .git is a directory'
assert_file_contains "${normal_marker}" 'normal commit-msg' 'commit-msg chains local hook when .git is a directory'

linked_repo="${tmpdir}/linked-repo"
linked_worktree="${tmpdir}/linked-feature"
linked_marker="${tmpdir}/linked-hooks.log"
linked_message_file="${linked_worktree}/COMMIT_EDITMSG.test"
init_repo "${linked_repo}"
git -C "${linked_repo}" branch feature
git -C "${linked_repo}" worktree add "${linked_worktree}" feature >/dev/null

linked_common_dir="$(git -C "${linked_worktree}" rev-parse --path-format=absolute --git-common-dir)"
write_local_hook "${linked_common_dir}/hooks/pre-commit" "${linked_marker}" 'linked pre-commit'
write_commit_msg_hook "${linked_common_dir}/hooks/commit-msg" "${linked_marker}" 'linked commit-msg' "${linked_message_file}"

run_pre_commit_from "${linked_worktree}"
run_commit_msg_from "${linked_worktree}"
assert_file_contains "${linked_marker}" 'linked pre-commit' 'pre-commit chains local hook when .git is a linked-worktree file'
assert_file_contains "${linked_marker}" 'linked commit-msg' 'commit-msg chains local hook when .git is a linked-worktree file'

failing_repo="${tmpdir}/failing-repo"
init_repo "${failing_repo}"
write_failing_hook "${failing_repo}/.git/hooks/pre-commit" 42
write_failing_hook "${failing_repo}/.git/hooks/commit-msg" 43

set +e
run_pre_commit_from "${failing_repo}"
failing_pre_commit_status="${?}"
set -e
assert_eq "${failing_pre_commit_status}" 42 'pre-commit propagates local hook failures'

set +e
run_commit_msg_from "${failing_repo}"
failing_commit_msg_status="${?}"
set -e
assert_eq "${failing_commit_msg_status}" 43 'commit-msg propagates local hook failures'

printf 'ok\n'
