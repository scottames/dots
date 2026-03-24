#!/usr/bin/env fish

set -l repo_root (path dirname (path dirname (status filename)))
set -l function_dir "$repo_root/home/private_dot_config/fish/custom_functions.d"
set -l tmpdir (mktemp -d)
set -l fakebin "$tmpdir/bin"
set -l log_file "$tmpdir/zellij.log"

mkdir -p "$fakebin" "$tmpdir/home" "$tmpdir/scratch/demo"

function cleanup --on-event fish_exit
    rm -rf "$tmpdir"
end

printf '#!/usr/bin/env bash\nprintf "%%s\n" "$*" >>"%s"\n' "$log_file" >"$fakebin/zellij"
chmod +x "$fakebin/zellij"

set -gx PATH "$fakebin" $PATH
set -gx HOME "$tmpdir/home"
set -gx DOTS "$tmpdir/dots"

command git init -b main "$DOTS" >/dev/null
command git -C "$DOTS" config user.name "Test User"
command git -C "$DOTS" config user.email "test@example.com"
command git -C "$DOTS" config commit.gpgsign false
printf 'hello\n' >"$DOTS/README.md"
command git -C "$DOTS" add README.md
command git -C "$DOTS" commit -m init >/dev/null
command git -C "$DOTS" branch feature-x >/dev/null
command git -C "$DOTS" worktree add "$tmpdir/feature-x" feature-x >/dev/null

printf 'demo\n' >"$DOTS/demo.txt"

source "$function_dir/zellij_tab_name.fish"
source "$function_dir/zellij_new_tab.fish"
source "$function_dir/zellij_rename_tab.fish"

function assert_eq
    set -l actual "$argv[1]"
    set -l expected "$argv[2]"
    set -l message "$argv[3]"
    if test "$actual" != "$expected"
        printf 'ASSERTION FAILED: %s\nexpected: %s\nactual:   %s\n' "$message" "$expected" "$actual" >&2
        exit 1
    end
end

assert_eq "$(zellij_tab_name "$HOME")" '~' 'home path maps to ~'
assert_eq "$(zellij_tab_name "$DOTS")" 'dots' 'default branch repo uses project name'
assert_eq "$(zellij_tab_name "$DOTS/demo.txt")" 'dots' 'file path uses parent repo name'
assert_eq "$(zellij_tab_name "$tmpdir/feature-x")" 'dots.feature-x' 'feature worktree gets branch suffix'
assert_eq "$(zellij_tab_name "$tmpdir/scratch/demo")" 'demo' 'non-git path uses basename'

zellij_new_tab "$tmpdir/feature-x"
set -l last_command (string trim -- (command tail -n 1 "$log_file"))
assert_eq "$last_command" "action new-tab --layout split-edit --cwd $tmpdir/feature-x --name dots.feature-x" 'new tab uses split-edit and derived name'

zellij_rename_tab "$tmpdir/feature-x"
set last_command (string trim -- (command tail -n 1 "$log_file"))
assert_eq "$last_command" "action rename-tab dots.feature-x" 'rename tab delegates to derived name'

printf 'ok\n'
