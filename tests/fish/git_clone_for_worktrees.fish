#!/usr/bin/env fish

set -l repo_root (path dirname (path dirname (path dirname (status filename))))
set -l function_dir "$repo_root/home/private_dot_config/fish/custom_functions.d"
set -l tmpdir (mktemp -d)
set -l fakebin "$tmpdir/bin"
set -l mise_log "$tmpdir/mise.log"

mkdir -p "$fakebin" "$tmpdir/work" "$tmpdir/remotes"
mkdir -p "$tmpdir/no-hooks"

function cleanup --on-event fish_exit
    rm -rf "$tmpdir"
end

printf '%s\n' '#!/usr/bin/env bash' \
    'printf "%s\n" "$PWD $*" >>"$MISE_LOG"' >"$fakebin/mise"
chmod +x "$fakebin/mise"

set -gx PATH "$fakebin" $PATH
set -gx MISE_LOG "$mise_log"

function printf_info
    printf $argv
end

function printf_warn
    printf $argv
end

function printf_err
    printf $argv >&2
end

function assert_eq
    set -l actual "$argv[1]"
    set -l expected "$argv[2]"
    set -l message "$argv[3]"
    if test "$actual" != "$expected"
        printf 'ASSERTION FAILED: %s\nexpected: %s\nactual:   %s\n' "$message" "$expected" "$actual" >&2
        exit 1
    end
end

function assert_exists
    set -l path "$argv[1]"
    set -l message "$argv[2]"
    if not test -e "$path"
        printf 'ASSERTION FAILED: %s\nmissing: %s\n' "$message" "$path" >&2
        exit 1
    end
end

function assert_not_exists
    set -l path "$argv[1]"
    set -l message "$argv[2]"
    if test -e "$path"
        printf 'ASSERTION FAILED: %s\nunexpected: %s\n' "$message" "$path" >&2
        exit 1
    end
end

function assert_fails
    set -l message "$argv[1]"
    set -e argv[1]

    $argv >/dev/null 2>/dev/null
    if test $status -eq 0
        printf 'ASSERTION FAILED: %s\ncommand unexpectedly succeeded: %s\n' "$message" (string join ' ' -- $argv) >&2
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
    printf '[tools]\n' >"$remote/mise.toml"
    command git -C "$remote" add README.md mise.toml
    command git -C "$remote" commit -m init >/dev/null
end

source "$function_dir/_arg_req_gt_one.fish"
source "$function_dir/git_clone_for_worktrees.fish"

set -l remote "$tmpdir/remotes/demo"
set -l other_remote "$tmpdir/remotes/other"
set -l derived_remote "$tmpdir/remotes/derived-only.git"
make_remote "$remote"
make_remote "$other_remote"
make_remote "$derived_remote"

pushd "$tmpdir/work" >/dev/null
git_clone_for_worktrees "$remote" demo
popd >/dev/null

assert_exists "$tmpdir/work/demo/main/.git" 'default clone creates durable main checkout'
assert_not_exists "$tmpdir/work/demo/.bare" 'default clone does not create legacy .bare layout'
assert_eq (string trim -- (command cat "$mise_log")) "$tmpdir/work/demo/main trust" 'default clone trusts mise in durable main checkout'

pushd "$tmpdir/work" >/dev/null
git_clone_for_worktrees "$derived_remote"
popd >/dev/null
assert_exists "$tmpdir/work/derived-only/main/.git" 'default clone derives repo name from URL'

printf '' >"$mise_log"
pushd "$tmpdir/work" >/dev/null
git_clone_for_worktrees "$remote" demo
popd >/dev/null
assert_eq (string trim -- (command cat "$mise_log")) "$tmpdir/work/demo/main trust" 'default clone no-ops only for matching durable main checkout'

command git clone "$other_remote" "$tmpdir/work/demo-normal-mismatch/main" >/dev/null 2>/dev/null
pushd "$tmpdir/work" >/dev/null
assert_fails 'default clone rejects mismatched existing main checkout' git_clone_for_worktrees "$remote" demo-normal-mismatch
popd >/dev/null

mkdir -p "$tmpdir/work/demo-existing-bare"
command git clone --bare "$remote" "$tmpdir/work/demo-existing-bare/.bare" >/dev/null 2>/dev/null
pushd "$tmpdir/work" >/dev/null
assert_fails 'default clone rejects existing legacy .bare layout' git_clone_for_worktrees "$remote" demo-existing-bare
popd >/dev/null

printf '' >"$mise_log"
pushd "$tmpdir/work" >/dev/null
git_clone_for_worktrees --bare "$remote" demo-bare
popd >/dev/null

assert_exists "$tmpdir/work/demo-bare/.bare" 'bare mode creates legacy .bare repository'
assert_exists "$tmpdir/work/demo-bare/main/.git" 'bare mode creates initial main worktree'
assert_eq (string trim -- (command cat "$tmpdir/work/demo-bare/.git")) 'gitdir: ./.bare' 'bare mode writes gitdir pointer'
assert_eq (string trim -- (command cat "$mise_log")) "$tmpdir/work/demo-bare/main trust" 'bare mode trusts mise in initial main worktree'

mkdir -p "$tmpdir/work/demo-bare-mismatch"
command git clone --bare "$other_remote" "$tmpdir/work/demo-bare-mismatch/.bare" >/dev/null 2>/dev/null
pushd "$tmpdir/work" >/dev/null
assert_fails 'bare mode rejects mismatched existing .bare repository' git_clone_for_worktrees --bare "$remote" demo-bare-mismatch
popd >/dev/null

command git clone "$remote" "$tmpdir/work/demo-existing-normal/main" >/dev/null 2>/dev/null
pushd "$tmpdir/work" >/dev/null
assert_fails 'bare mode rejects existing normal main checkout' git_clone_for_worktrees --bare "$remote" demo-existing-normal
popd >/dev/null

printf 'ok\n'
