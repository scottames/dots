#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="${repo_root}/home/dot_local/bin/executable_tuicr-current"
tmpdir="$(mktemp -d)"
fakebin="${tmpdir}/bin"
repo="${tmpdir}/repo"
tuicr_log="${tmpdir}/tuicr.log"
git_log="${tmpdir}/git.log"
real_jq="$(command -v jq)"

cleanup() { rm -rf "${tmpdir}"; }
trap cleanup EXIT

mkdir -p "${fakebin}" "${repo}" "${tmpdir}/no-hooks"

cat >"${fakebin}/gh" <<'EOF'
#!/usr/bin/env bash
case "$*" in
"pr view --json number -q .number")
  [[ -n ${TEST_PR_NUMBER-} ]] && printf '%s\n' "${TEST_PR_NUMBER}"
  ;;
"stack --help")
  [[ ${TEST_STACK_AVAILABLE-true} == true ]]
  ;;
"stack view --json")
  [[ ${TEST_STACK_VIEW_FAILURE-false} == false ]] || exit 1
  printf '%s\n' "${TEST_STACK_JSON-}"
  ;;
"repo view --json defaultBranchRef -q .defaultBranchRef.name")
  [[ ${TEST_REPO_AUTH_FAILURE-false} == false ]] || exit 1
  printf '%s\n' "${TEST_DEFAULT_BRANCH-main}"
  ;;
*)
  exit 1
  ;;
esac
EOF

cat >"${fakebin}/git" <<'EOF'
#!/usr/bin/env bash
if [[ ${1-} == merge-base ]]; then
  printf '%s\n' "$*" >>"${TEST_GIT_LOG}"
fi
exec /usr/bin/git "$@"
EOF

cat >"${fakebin}/tuicr" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >"${TEST_TUICR_LOG}"
EOF

chmod +x "${fakebin}/gh" "${fakebin}/git" "${fakebin}/tuicr"
ln -s "${real_jq}" "${fakebin}/jq"

export PATH="${fakebin}:/usr/bin:/bin"
export TEST_GIT_LOG="${git_log}"
export TEST_TUICR_LOG="${tuicr_log}"

git -C "${repo}" init -b main >/dev/null
git -C "${repo}" config user.name 'Test User'
git -C "${repo}" config user.email test@example.com
git -C "${repo}" config commit.gpgsign false
git -C "${repo}" config core.hooksPath "${tmpdir}/no-hooks"
printf 'main\n' >"${repo}/file"
git -C "${repo}" add file
git -C "${repo}" commit -m main >/dev/null
main_sha="$(git -C "${repo}" rev-parse HEAD)"
git -C "${repo}" update-ref refs/remotes/origin/main "${main_sha}"
git -C "${repo}" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main

git -C "${repo}" switch -c stack-bottom >/dev/null
printf 'bottom\n' >>"${repo}/file"
git -C "${repo}" commit -am bottom >/dev/null
bottom_sha="$(git -C "${repo}" rev-parse HEAD)"

git -C "${repo}" switch -c stack-upper >/dev/null
printf 'upper\n' >>"${repo}/file"
git -C "${repo}" commit -am upper >/dev/null
upper_sha="$(git -C "${repo}" rev-parse HEAD)"

stack_json="$(printf '{"trunk":"main","currentBranch":"stack-upper","branches":[{"name":"stack-bottom","head":"%s","base":"%s","isCurrent":false},{"name":"stack-upper","head":"%s","base":"%s","isCurrent":true}]}' "${bottom_sha}" "${main_sha}" "${upper_sha}" "${bottom_sha}")"

assert_tuicr() {
  local expected=$1 message=$2 actual
  actual="$(<"${tuicr_log}")"
  if [[ ${actual} != "${expected}" ]]; then
    printf 'ASSERTION FAILED: %s\nexpected: %s\nactual: %s\n' "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

run_review() {
  : >"${tuicr_log}"
  : >"${git_log}"
  (
    cd "${repo}"
    GH_STACK_ENABLED="${GH_STACK_ENABLED-true}" \
      TEST_STACK_AVAILABLE="${TEST_STACK_AVAILABLE-true}" \
      TEST_STACK_VIEW_FAILURE="${TEST_STACK_VIEW_FAILURE-false}" \
      TEST_STACK_JSON="${TEST_STACK_JSON-${stack_json}}" \
      TEST_PR_NUMBER="${TEST_PR_NUMBER-}" \
      TEST_REPO_AUTH_FAILURE="${TEST_REPO_AUTH_FAILURE-false}" \
      TEST_DEFAULT_BRANCH="${TEST_DEFAULT_BRANCH-main}" \
      bash "${script}" "${1-auto}"
  )
}

# Dirty worktrees always use the WIP review before querying PR or stack state.
printf 'dirty\n' >>"${repo}/file"
run_review auto
assert_tuicr '-w' 'dirty worktree uses WIP review'
git -C "${repo}" restore file

# Existing PRs take precedence over stack ranges.
TEST_PR_NUMBER=42 run_review auto
assert_tuicr 'pr 42' 'existing PR uses PR review'

# The bottom stack layer uses the trunk branch as its direct parent.
git -C "${repo}" switch stack-bottom >/dev/null
bottom_json="$(printf '{"trunk":"main","currentBranch":"stack-bottom","branches":[{"name":"stack-bottom","head":"%s","base":"%s","isCurrent":true},{"name":"stack-upper","head":"%s","base":"%s","isCurrent":false}]}' "${bottom_sha}" "${main_sha}" "${upper_sha}" "${bottom_sha}")"
TEST_STACK_JSON="${bottom_json}" run_review range
assert_tuicr "-r ${main_sha}..HEAD" 'bottom stack layer compares against trunk'
[[ $(<"${git_log}") == 'merge-base main HEAD' ]] || {
  printf 'ASSERTION FAILED: bottom layer resolves the trunk branch name\nactual: %s\n' "$(<"${git_log}")" >&2
  exit 1
}

# The upper layer uses the previous branch name, never its .base commit SHA.
git -C "${repo}" switch stack-upper >/dev/null
run_review range
assert_tuicr "-r ${bottom_sha}..HEAD" 'upper stack layer compares against previous branch'
[[ $(<"${git_log}") == 'merge-base stack-bottom HEAD' ]] || {
  printf 'ASSERTION FAILED: upper layer resolves previous branch name, not .base SHA\nactual: %s\n' "$(<"${git_log}")" >&2
  exit 1
}

# A branch absent from the stack falls back to the repository default branch.
git -C "${repo}" switch -c outside main >/dev/null
printf 'outside\n' >>"${repo}/file"
git -C "${repo}" commit -am outside >/dev/null
non_stack_json="$(printf '{"trunk":"main","currentBranch":"outside","branches":[{"name":"stack-bottom","head":"%s","base":"%s","isCurrent":false},{"name":"stack-upper","head":"%s","base":"%s","isCurrent":false}]}' "${bottom_sha}" "${main_sha}" "${upper_sha}" "${bottom_sha}")"
TEST_STACK_JSON="${non_stack_json}" run_review range
assert_tuicr "-r ${main_sha}..HEAD" 'non-stack branch uses default branch'

# A structurally valid stack can reference a stale branch that no longer exists.
missing_parent_json="$(printf '{"trunk":"main","currentBranch":"outside","branches":[{"name":"missing-parent","head":"%s","base":"%s","isCurrent":false},{"name":"outside","head":"%s","base":"%s","isCurrent":true}]}' "${bottom_sha}" "${main_sha}" "$(git -C "${repo}" rev-parse HEAD)" "${bottom_sha}")"
TEST_STACK_JSON="${missing_parent_json}" run_review range
assert_tuicr "-r ${main_sha}..HEAD" 'missing stack parent uses default branch'
[[ $(<"${git_log}") == 'merge-base origin/main HEAD' ]] || {
  printf 'ASSERTION FAILED: missing stack parent resolves the usable default ref\nactual: %s\n' "$(<"${git_log}")" >&2
  exit 1
}

TEST_STACK_JSON="${missing_parent_json}" TEST_DEFAULT_BRANCH=missing-default run_review range
assert_tuicr '' 'missing stack parent and default preserve plain tuicr fallback'
[[ ! -s ${git_log} ]] || {
  printf 'ASSERTION FAILED: plain fallback does not try an unusable ref\nactual: %s\n' "$(<"${git_log}")" >&2
  exit 1
}

# Missing extension capability, invalid JSON, and auth failures are suppressed.
TEST_STACK_AVAILABLE=false run_review range
assert_tuicr "-r ${main_sha}..HEAD" 'unavailable gh-stack uses default branch'

TEST_STACK_JSON='not-json' run_review range
assert_tuicr "-r ${main_sha}..HEAD" 'malformed stack JSON uses default branch'

TEST_STACK_VIEW_FAILURE=true TEST_REPO_AUTH_FAILURE=true run_review range
assert_tuicr "-r ${main_sha}..HEAD" 'auth failures use origin default branch'

# Stack mode remains opt-in, and lack of jq safely preserves default behavior.
GH_STACK_ENABLED=false run_review range
assert_tuicr "-r ${main_sha}..HEAD" 'disabled stack mode uses default branch'

nojqbin="${tmpdir}/nojq-bin"
mkdir -p "${nojqbin}"
for command in bash gh git sed tuicr; do
  ln -s "$(command -v "${command}")" "${nojqbin}/${command}"
done
PATH="${nojqbin}" run_review range
assert_tuicr "-r ${main_sha}..HEAD" 'missing jq uses default branch'

# Outside a repository, preserve the plain selector fallback.
(
  cd "${tmpdir}"
  bash "${script}" selector
)
assert_tuicr '' 'selector mode preserves plain tuicr fallback'

printf 'ok\n'
