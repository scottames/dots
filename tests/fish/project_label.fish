#!/usr/bin/env fish

set -l repo_root (path dirname (path dirname (path dirname (status filename))))
set -l function_dir "$repo_root/home/private_dot_config/fish/custom_functions.d"
set -l tmpdir (mktemp -d)

mkdir -p "$tmpdir/remotes" "$tmpdir/work" "$tmpdir/home" "$tmpdir/no-hooks"

function cleanup --on-event fish_exit
    rm -rf "$tmpdir"
end

set -gx HOME "$tmpdir/home"

function assert_eq
    set -l actual "$argv[1]"
    set -l expected "$argv[2]"
    set -l message "$argv[3]"
    if test "$actual" != "$expected"
        printf 'ASSERTION FAILED: %s\nexpected: %s\nactual:   %s\n' "$message" "$expected" "$actual" >&2
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

function make_normal_layout
    set -l remote "$argv[1]"
    set -l target "$argv[2]"

    mkdir -p "$target"
    command git clone "$remote" "$target/main" >/dev/null 2>/dev/null
    command git -C "$target/main" config remote.origin.url git@github.com:scottames/(basename "$target").git
    command git -C "$target/main" branch feature-x
    command git -C "$target/main" worktree add "$target/feature-x" feature-x >/dev/null
    printf 'demo\n' >"$target/main/demo.txt"
end

function make_legacy_layout
    set -l remote "$argv[1]"
    set -l target "$argv[2]"

    mkdir -p "$target"
    command git clone --bare "$remote" "$target/.bare" >/dev/null 2>/dev/null
    command git --git-dir="$target/.bare" config remote.origin.url git@github.com:scottames/(basename "$target").git
    command git --git-dir="$target/.bare" worktree add "$target/main" main >/dev/null
    command git --git-dir="$target/.bare" worktree add -b feature-x "$target/feature-x" main >/dev/null
    printf 'demo\n' >"$target/main/demo.txt"
end

source "$function_dir/project_label.fish"
or exit 1

set -l remote "$tmpdir/remotes/dots"
set -l normal "$tmpdir/work/normal/dots"
set -l legacy "$tmpdir/work/legacy/dots"
set -l example_remote "$tmpdir/remotes/example.project"
set -l example_normal "$tmpdir/work/normal/example.project"
make_remote "$remote"
make_remote "$example_remote"
make_normal_layout "$remote" "$normal"
make_normal_layout "$example_remote" "$example_normal"
make_legacy_layout "$remote" "$legacy"

mkdir -p "$tmpdir/scratch/demo"

assert_eq "$(project_label "$HOME")" '~' 'home path maps to ~'
assert_eq "$(project_label "$normal/main")" dots 'normal main checkout uses repo directory name'
assert_eq "$(project_label "$normal/main/demo.txt")" dots 'normal file path uses parent checkout label'
assert_eq "$(project_label "$normal/feature-x")" dots:feature-x 'normal sibling worktree uses default branch suffix'
assert_eq "$(project_label --separator=/ "$normal/feature-x")" dots/feature-x 'separator flag supports slash branch suffix'
assert_eq "$(project_label "$legacy/main")" dots 'legacy main checkout keeps repo label'
assert_eq "$(project_label "$legacy/main/demo.txt")" dots 'legacy file path uses parent checkout label'
assert_eq "$(project_label "$legacy/feature-x")" dots:feature-x 'legacy sibling worktree keeps default branch suffix'
assert_eq "$(project_label --separator=/ "$legacy/feature-x")" dots/feature-x 'legacy slash separator keeps existing zw convention'
assert_eq "$(project_label "$tmpdir/scratch/demo")" demo 'non-git path uses basename'

set -gx PROJECT_LABEL_SUBSTITUTIONS 'example.project=ex'
assert_eq "$(project_label "$example_normal/main")" ex 'project label substitutions shorten project-only labels'

set -gx PROJECT_LABEL_SUBSTITUTIONS 'example.project/=ex/ example.project=ex'
assert_eq "$(project_label --separator=/ "$example_normal/feature-x")" ex/feature-x 'project label substitutions shorten rendered slash prefixes'

set -gx PROJECT_LABEL_SUBSTITUTIONS 'example.project/=ex/ example=bad'
assert_eq "$(project_label --separator=/ "$example_normal/feature-x")" ex/feature-x 'project label substitutions use first matching prefix'
set -e PROJECT_LABEL_SUBSTITUTIONS

printf 'ok\n'
