#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
watcher="${repo_root}/home/dot_local/bin/executable_git-stack-watch"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT
mkdir -p "${tmpdir}/bin"

cat >"${tmpdir}/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf 'gh %s\n' "$*" >>"${WATCH_LOG}"
case "$*" in
  'stack --help') exit "${GH_HELP_EXIT:-0}" ;;
  'stack view --short') printf 'github-stack\n'; exit "${GH_VIEW_EXIT:-0}" ;;
esac
EOF
cat >"${tmpdir}/bin/gt" <<'EOF'
#!/usr/bin/env bash
printf 'gt %s\n' "$*" >>"${WATCH_LOG}"
printf 'graphite-stack\n'
exit "${GT_EXIT:-0}"
EOF
cat >"${tmpdir}/bin/git" <<'EOF'
#!/usr/bin/env bash
printf 'git %s\n' "$*" >>"${WATCH_LOG}"
printf 'git-graph\n'
EOF
cat >"${tmpdir}/bin/sleep" <<'EOF'
#!/usr/bin/env bash
printf 'sleep %s\n' "$*" >>"${WATCH_LOG}"
kill -TERM "$PPID"
EOF
chmod +x "${tmpdir}/bin/"*

run_watch() {
  : >"${WATCH_LOG}"
  PATH="${tmpdir}/bin:/usr/bin:/bin" bash "${watcher}" 7 2>/dev/null || true
}

export WATCH_LOG="${tmpdir}/watch.log"

output="$(GH_STACK_ENABLED=true GRAPHITE_ENABLED=true run_watch)"
[[ ${output} == *github-stack* ]] || {
  printf 'ASSERTION FAILED: GitHub Stack has precedence\n' >&2
  exit 1
}
grep -Fq 'gh stack view --short' "${WATCH_LOG}"
grep -Fq 'gt ls' "${WATCH_LOG}" && exit 1
grep -Fq 'sleep 7' "${WATCH_LOG}"

output="$(GH_STACK_ENABLED=false GRAPHITE_ENABLED=true run_watch)"
[[ ${output} == *graphite-stack* ]] || {
  printf 'ASSERTION FAILED: Graphite mode is selected\n' >&2
  exit 1
}
grep -Fq 'gt ls' "${WATCH_LOG}"

output="$(GH_STACK_ENABLED=false GRAPHITE_ENABLED=false run_watch)"
[[ ${output} == *git-graph* ]] || {
  printf 'ASSERTION FAILED: Git graph is the default\n' >&2
  exit 1
}

output="$(GH_STACK_ENABLED=true GRAPHITE_ENABLED=true GH_VIEW_EXIT=1 run_watch)"
[[ ${output} == *git-graph* ]] || {
  printf 'ASSERTION FAILED: failed GitHub Stack display falls back to Git graph\n' >&2
  exit 1
}
grep -Fq 'gt ls' "${WATCH_LOG}" && exit 1

output="$(GH_STACK_ENABLED=false GRAPHITE_ENABLED=true GT_EXIT=1 run_watch)"
[[ ${output} == *git-graph* ]] || {
  printf 'ASSERTION FAILED: failed Graphite display falls back to Git graph\n' >&2
  exit 1
}

printf 'ok\n'
