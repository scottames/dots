#!/usr/bin/env fish

set -l repo_root (path dirname (path dirname (path dirname (status filename))))
set -l function_dir "$repo_root/home/private_dot_config/fish/custom_functions.d"
set -l tmpdir (mktemp -d)
set -g batch_log "$tmpdir/batch.log"

mkdir -p "$tmpdir/list/alpha" "$tmpdir/list/beta"
printf '' >"$batch_log"

function cleanup --on-event fish_exit
    rm -rf "$tmpdir"
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

function git_clone_for_worktrees
    printf '%s\n' (string join '|' -- $argv) >>"$batch_log"
end

source "$function_dir/git_clone_for_worktrees_from_ls.fish"

pushd "$tmpdir/list" >/dev/null
git_clone_for_worktrees_from_ls --bare scottames example.com
popd >/dev/null

set -l batch_lines (string join \n -- (sort "$batch_log"))
set -l expected_lines (string join \n -- \
    '--bare|git@example.com/scottames/alpha.git' \
    '--bare|git@example.com/scottames/beta.git')
assert_eq "$batch_lines" "$expected_lines" 'batch clone forwards selected bare mode'

printf '' >"$batch_log"
pushd "$tmpdir/list" >/dev/null
git_clone_for_worktrees_from_ls scottames
popd >/dev/null

set batch_lines (string join \n -- (sort "$batch_log"))
set expected_lines (string join \n -- \
    'git@github.com/scottames/alpha.git' \
    'git@github.com/scottames/beta.git')
assert_eq "$batch_lines" "$expected_lines" 'batch clone defaults to normal mode without mode flag'

printf 'ok\n'
