#!/usr/bin/env fish

set -l repo_root (path dirname (path dirname (path dirname (status filename))))
set -l function_dir "$repo_root/home/private_dot_config/fish/custom_functions.d"
set -l tmpdir (mktemp -d)
set -l fakebin "$tmpdir/bin"
set -l stax_log "$tmpdir/stax.log"
set -l gt_log "$tmpdir/gt.log"

mkdir -p "$fakebin" "$tmpdir/remotes" "$tmpdir/github.com/scottames/dots" "$tmpdir/legacy/github.com/scottames/dots" "$tmpdir/no-hooks" "$tmpdir/home"

function cleanup --on-event fish_exit
    rm -rf "$tmpdir"
end

set -gx HOME "$tmpdir/home"
set -gx PATH "$fakebin" /usr/bin /bin
set -gx GIT_STATUS_TEST_STAX_LOG "$stax_log"
set -gx GIT_STATUS_TEST_GT_LOG "$gt_log"
set fish_function_path "$function_dir" $fish_function_path

printf '%s\n' '#!/usr/bin/env bash' \
    'printf "%s\n" "$*" >>"$GIT_STATUS_TEST_STAX_LOG"' \
    'if [[ "$*" == "status --current --quiet" ]]; then printf "stax-status-output\n"; exit "${GIT_STATUS_TEST_STAX_EXIT:-0}"; fi' >"$fakebin/stax"
chmod +x "$fakebin/stax"
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

mkdir -p "$normal_main/.git/stax"
set -gx GRAPHITE_ENABLED true
set -gx HAS_GT true
pushd "$normal_main" >/dev/null
set -l uninitialized_output (git_status --short)
popd >/dev/null
assert_contains "$uninitialized_output" 'graphite-output' 'uninitialized repo uses Graphite even when stax cache exists'
if test -e "$stax_log"
    printf 'ASSERTION FAILED: git_status does not invoke stax before init\n' >&2
    exit 1
end

command truncate -s 0 "$gt_log"
set -l trunk_blob (printf 'main' | command git -C "$normal_main" hash-object -w --stdin)
command git -C "$normal_main" update-ref refs/stax/trunk "$trunk_blob"
pushd "$normal_main" >/dev/null
set -l stack_output (git_status --short)
popd >/dev/null
assert_contains "$stack_output" 'stax-status-output' 'stax status uses current stack view'
assert_not_contains "$stack_output" 'graphite-output' 'stax takes precedence over Graphite'
set -l stax_calls (string trim -- (command cat "$stax_log"))
if test "$stax_calls" != 'status --current --quiet'
    printf 'ASSERTION FAILED: git_status invokes exactly stax status --current --quiet\nactual: %s\n' "$stax_calls" >&2
    exit 1
end
if test -s "$gt_log"
    printf 'ASSERTION FAILED: git_status does not invoke Graphite when stax is selected\n' >&2
    exit 1
end

command truncate -s 0 "$stax_log"
pushd "$normal_feature" >/dev/null
set -l worktree_output (git_status --short)
popd >/dev/null
assert_contains "$worktree_output" 'stax-status-output' 'linked worktree sees shared stax initialization'
if test (string trim -- (command cat "$stax_log")) != 'status --current --quiet'
    printf 'ASSERTION FAILED: linked worktree invokes stax exactly once\n' >&2
    exit 1
end

command truncate -s 0 "$stax_log"
mv "$fakebin/stax" "$tmpdir/stax"
pushd "$normal_main" >/dev/null
set -l graphite_output (git_status --short)
popd >/dev/null
assert_contains "$graphite_output" 'graphite-output' 'Graphite is used when stax is unavailable'
if test -s "$stax_log"
    printf 'ASSERTION FAILED: git_status does not invoke stax when unavailable\n' >&2
    exit 1
end

command truncate -s 0 "$gt_log"
mv "$tmpdir/stax" "$fakebin/stax"
set -gx GIT_STATUS_TEST_STAX_EXIT 1
touch "$normal_main/status-proof"
pushd "$normal_main" >/dev/null
set -l failed_stax_output (git_status --short)
popd >/dev/null
assert_contains "$failed_stax_output" '?? status-proof' 'failed stax display continues to git status'
assert_not_contains "$failed_stax_output" 'graphite-output' 'failed selected stax mode does not switch modes'
if test -s "$gt_log"
    printf 'ASSERTION FAILED: git_status does not invoke Graphite after selected stax fails\n' >&2
    exit 1
end

set -e GIT_STATUS_TEST_STAX_EXIT
mv "$fakebin/stax" "$tmpdir/stax"
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
