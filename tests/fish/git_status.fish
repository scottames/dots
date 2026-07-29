#!/usr/bin/env fish

set -l repo_root (path dirname (path dirname (path dirname (status filename))))
set -l function_dir "$repo_root/home/private_dot_config/fish/custom_functions.d"
set -l tmpdir (mktemp -d)
set -l fakebin "$tmpdir/bin"
set -l gh_log "$tmpdir/gh.log"
set -l gt_log "$tmpdir/gt.log"

mkdir -p "$fakebin" "$tmpdir/remotes" "$tmpdir/github.com/scottames/dots" "$tmpdir/legacy/github.com/scottames/dots" "$tmpdir/no-hooks" "$tmpdir/home"

function cleanup --on-event fish_exit
    rm -rf "$tmpdir"
end

set -gx HOME "$tmpdir/home"
set -gx PATH "$fakebin" /usr/bin /bin
set -gx GIT_STATUS_TEST_GH_LOG "$gh_log"
set -gx GIT_STATUS_TEST_GT_LOG "$gt_log"
set fish_function_path "$function_dir" $fish_function_path

printf '%s\n' '#!/usr/bin/env bash' \
    'printf "%s\n" "$*" >>"$GIT_STATUS_TEST_GH_LOG"' \
    'if [[ "$*" == "stack view --short" ]]; then printf "stack-short-output\n"; exit "${GIT_STATUS_TEST_GH_EXIT:-0}"; fi' >"$fakebin/gh"
chmod +x "$fakebin/gh"
printf '%s\n' '#!/usr/bin/env bash' \
    'printf "%s\n" "$*" >>"$GIT_STATUS_TEST_GT_LOG"' \
    'printf "graphite-output\n"' \
    'exit "${GIT_STATUS_TEST_GT_EXIT:-0}"' >"$fakebin/gt"
chmod +x "$fakebin/gt"

function printf_green_bold
    printf '%s' $argv
end

function printf_color
    argparse c/color= b/bold -- $argv
    printf '[%s]' (string join ' ' -- $argv)
end

function assert_contains
    set -l actual "$argv[1]"
    set -l expected "$argv[2]"
    set -l message "$argv[3]"
    if not string match -q "*$expected*" -- "$actual"
        printf 'ASSERTION FAILED: %s\nexpected to contain: %s\nactual: %s\n' "$message" "$expected" "$actual" >&2
        exit 1
    end
end

function assert_not_contains
    set -l actual "$argv[1]"
    set -l unexpected "$argv[2]"
    set -l message "$argv[3]"
    if string match -q "*$unexpected*" -- "$actual"
        printf 'ASSERTION FAILED: %s\nunexpected: %s\nactual: %s\n' "$message" "$unexpected" "$actual" >&2
        exit 1
    end
end

function make_remote
    set -l remote "$argv[1]"
    command git init -b main "$remote" >/dev/null
    command git -C "$remote" config user.name "Test User"
    command git -C "$remote" config user.email "test@example.com"
    command git -C "$remote" config commit.gpgsign false
    command git -C "$remote" config core.hooksPath "$tmpdir/no-hooks"
    printf 'hello\n' >"$remote/README.md"
    command git -C "$remote" add README.md
    command git -C "$remote" commit -m init >/dev/null
end

source "$function_dir/project_label.fish"
or exit 1
source "$function_dir/git_status.fish"
or exit 1

set -l remote "$tmpdir/remotes/dots"
make_remote "$remote"

set -l normal_main "$tmpdir/github.com/scottames/dots/main"
set -l normal_feature "$tmpdir/github.com/scottames/dots/feature-x"
command git clone "$remote" "$normal_main" >/dev/null 2>/dev/null
command git -C "$normal_main" config remote.origin.url git@github.com:scottames/dots.git
command git -C "$normal_main" branch feature-x
command git -C "$normal_main" worktree add "$normal_feature" feature-x >/dev/null

pushd "$normal_main" >/dev/null
set -l normal_output (git_status --short)
popd >/dev/null
set -l normal_path_line (string match -r '^📂 .*' -- $normal_output)
assert_contains "$normal_output" "$normal_main" 'fallback git worktree list includes normal main checkout'
assert_contains "$normal_output" "$normal_feature" 'fallback git worktree list includes normal sibling worktree'
assert_contains "$normal_path_line" '[dots]' 'normal main path highlights repo name'
assert_not_contains "$normal_path_line" '[main]' 'normal main path does not highlight main as project'

set -gx GH_STACK_ENABLED true
set -gx HAS_GH true
set -gx HAS_GH_STACK true
set -gx GRAPHITE_ENABLED true
set -gx HAS_GT true
pushd "$normal_main" >/dev/null
set -l stack_output (git_status --short)
popd >/dev/null
assert_contains "$stack_output" 'stack-short-output' 'enabled gh-stack status uses short view'
assert_not_contains "$stack_output" 'graphite-output' 'GitHub Stack takes precedence over Graphite'
set -l gh_calls (string trim -- (command cat "$gh_log"))
if test "$gh_calls" != 'stack view --short'
    printf 'ASSERTION FAILED: git_status invokes exactly gh stack view --short\nactual: %s\n' "$gh_calls" >&2
    exit 1
end
if test -e "$gt_log"
    printf 'ASSERTION FAILED: git_status does not invoke Graphite when GitHub Stack is selected\n' >&2
    exit 1
end

command truncate -s 0 "$gh_log"
set -gx HAS_GH false
pushd "$normal_main" >/dev/null
set -l graphite_output (git_status --short)
popd >/dev/null
assert_contains "$graphite_output" 'graphite-output' 'Graphite is used when GitHub Stack capability is incomplete'
if test -s "$gh_log"
    printf 'ASSERTION FAILED: git_status requires HAS_GH before invoking gh stack\n' >&2
    exit 1
end

command truncate -s 0 "$gt_log"
set -gx HAS_GH true
set -gx GIT_STATUS_TEST_GH_EXIT 1
touch "$normal_main/status-proof"
pushd "$normal_main" >/dev/null
set -l failed_gh_output (git_status --short)
popd >/dev/null
assert_contains "$failed_gh_output" '?? status-proof' 'failed gh stack display continues to git status'
assert_not_contains "$failed_gh_output" 'graphite-output' 'failed selected GitHub Stack mode does not switch modes'
if test -s "$gt_log"
    printf 'ASSERTION FAILED: git_status does not invoke Graphite after selected gh stack fails\n' >&2
    exit 1
end

set -e GIT_STATUS_TEST_GH_EXIT
set -gx GH_STACK_ENABLED false
set -gx GIT_STATUS_TEST_GT_EXIT 1
pushd "$normal_main" >/dev/null
set -l failed_gt_output (git_status --short)
popd >/dev/null
assert_contains "$failed_gt_output" '?? status-proof' 'failed Graphite display continues to git status'

set -l legacy_root "$tmpdir/legacy/github.com/scottames/dots"
command git clone --bare "$remote" "$legacy_root/.bare" >/dev/null 2>/dev/null
command git --git-dir="$legacy_root/.bare" config remote.origin.url git@github.com:scottames/dots.git
command git --git-dir="$legacy_root/.bare" worktree add "$legacy_root/main" main >/dev/null
command git --git-dir="$legacy_root/.bare" worktree add -b legacy-feature "$legacy_root/legacy-feature" main >/dev/null

pushd "$legacy_root/legacy-feature" >/dev/null
set -l legacy_output (git_status --short)
popd >/dev/null
set -l legacy_path_line (string match -r '^📂 .*' -- $legacy_output)
assert_not_contains "$legacy_output" '.bare' 'fallback git worktree list hides legacy bare admin directory'
assert_contains "$legacy_path_line" '[dots]' 'legacy worktree path highlights repo name'
assert_contains "$legacy_path_line" '[legacy-feature]' 'legacy worktree path highlights branch worktree segment'

printf 'ok\n'
