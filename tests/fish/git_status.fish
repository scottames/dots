#!/usr/bin/env fish

set -l repo_root (path dirname (path dirname (path dirname (status filename))))
set -l function_dir "$repo_root/home/private_dot_config/fish/custom_functions.d"
set -l tmpdir (mktemp -d)

mkdir -p "$tmpdir/remotes" "$tmpdir/github.com/scottames/dots" "$tmpdir/legacy/github.com/scottames/dots" "$tmpdir/no-hooks" "$tmpdir/home"

function cleanup --on-event fish_exit
    rm -rf "$tmpdir"
end

set -gx HOME "$tmpdir/home"
set -gx PATH /usr/bin /bin
set fish_function_path "$function_dir" $fish_function_path
set -e HAS_GT

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
