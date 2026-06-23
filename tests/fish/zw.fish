#!/usr/bin/env fish

set -l repo_root (path dirname (path dirname (path dirname (status filename))))
set -l function_dir "$repo_root/home/private_dot_config/fish/custom_functions.d"
set -l tmpdir (mktemp -d)
set -l fakebin "$tmpdir/bin"
set -l log_file "$tmpdir/zellij.log"

mkdir -p "$fakebin" "$tmpdir/remotes" "$tmpdir/github.com/scottames/dots" "$tmpdir/no-hooks"

function cleanup --on-event fish_exit
    rm -rf "$tmpdir"
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

printf '%s\n' '#!/usr/bin/env bash' \
    'case "$*" in' \
    '  "list --format=json") printf '\''[{"branch":"feature-x","path":"%s"}]\n'\'' "$ZW_TEST_WORKTREE_PATH" ;;' \
    '  *) exit 1 ;;' \
    'esac' >"$fakebin/wt"
chmod +x "$fakebin/wt"

printf '%s\n' '#!/usr/bin/env bash' \
    'if [[ "$1" == "-r" && "$2" == "--arg" && "$4" == "feature-x" ]]; then' \
    '  printf "%s\n" "$ZW_TEST_WORKTREE_PATH"' \
    'elif [[ "$1" == "-r" ]]; then' \
    '  printf "feature-x\n"' \
    'fi' >"$fakebin/jq"
chmod +x "$fakebin/jq"

printf '%s\n' '#!/usr/bin/env bash' \
    'printf "%s\n" "$*" >>"$ZW_TEST_ZELLIJ_LOG"' \
    'while [[ $# -gt 0 ]]; do' \
    '  if [[ "$1" == "--layout" && $# -gt 1 ]]; then' \
    '    printf "\n--- layout ---\n" >>"$ZW_TEST_ZELLIJ_LOG"' \
    '    cat "$2" >>"$ZW_TEST_ZELLIJ_LOG"' \
    '    break' \
    '  fi' \
    '  shift' \
    'done' >"$fakebin/zellij"
chmod +x "$fakebin/zellij"

set -gx PATH "$fakebin" $PATH
set -gx ZELLIJ 1
set -gx ZW_TEST_ZELLIJ_LOG "$log_file"
set fish_function_path "$function_dir" $fish_function_path

set -l remote "$tmpdir/remotes/dots"
command git init -b main "$remote" >/dev/null
command git -C "$remote" config user.name "Test User"
command git -C "$remote" config user.email "test@example.com"
command git -C "$remote" config commit.gpgsign false
command git -C "$remote" config core.hooksPath "$tmpdir/no-hooks"
printf 'hello\n' >"$remote/README.md"
command git -C "$remote" add README.md
command git -C "$remote" commit -m init >/dev/null

set -l main_checkout "$tmpdir/github.com/scottames/dots/main"
set -l feature_checkout "$tmpdir/github.com/scottames/dots/feature-x"
command git clone "$remote" "$main_checkout" >/dev/null 2>/dev/null
command git -C "$main_checkout" config remote.origin.url git@github.com:scottames/dots.git
command git -C "$main_checkout" branch feature-x
command git -C "$main_checkout" worktree add "$feature_checkout" feature-x >/dev/null
set -gx ZW_TEST_WORKTREE_PATH "$feature_checkout"

source "$function_dir/project_label.fish"
or exit 1
source "$function_dir/zw.fish"
or exit 1

pushd "$main_checkout" >/dev/null
zw feature-x
popd >/dev/null

set -l command_log (string trim -- (command cat "$log_file"))
assert_contains "$command_log" "-c $feature_checkout" 'zw opens the selected worktree path'
assert_contains "$command_log" '--name dots/feature-x' 'zw uses layout-aware slash-separated tab name'
assert_not_contains "$command_log" '--name main/feature-x' 'zw does not label normal-layout tabs as main'
assert_contains "$command_log" 'plugin location="status-bar"' 'zw generated layout uses built-in status bar'
assert_not_contains "$command_log" 'zellij-status' 'zw generated layout does not use retired zellij-status plugin'

printf 'ok\n'
