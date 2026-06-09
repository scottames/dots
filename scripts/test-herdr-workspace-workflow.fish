#!/usr/bin/env fish

set -l repo_root (path dirname (path dirname (status filename)))
set -l function_dir "$repo_root/home/private_dot_config/fish/custom_functions.d"
set -l tmpdir (mktemp -d)
set -l fakebin "$tmpdir/bin"
set -l log_file "$tmpdir/herdr.log"
set -l pane_list_file "$tmpdir/pane-list.json"

mkdir -p "$fakebin" "$tmpdir/home" "$tmpdir/scratch/demo"

function cleanup --on-event fish_exit
    rm -rf "$tmpdir"
end

printf '%s\n' '#!/usr/bin/env bash' \
    'printf "%s\n" "$*" >>"$HERDR_LOG"' \
    'case "$*" in' \
    '  "workspace create"*)' \
    '    printf '\''{"result":{"workspace":{"workspace_id":"w-test"},"tab":{"tab_id":"w-test:1"},"root_pane":{"pane_id":"w-test-1"}}}\n'\''' \
    '    ;;' \
    '  "pane split w-test-1"*)' \
    '    printf '\''{"result":{"pane":{"pane_id":"w-test-2"}}}\n'\''' \
    '    ;;' \
    '  "pane split w-test-2"*)' \
    '    printf '\''{"result":{"pane":{"pane_id":"w-test-3"}}}\n'\''' \
    '    ;;' \
    '  "tab create"*)' \
    '    printf '\''{"result":{"tab":{"tab_id":"w-test:2"},"pane":{"pane_id":"w-test-4"}}}\n'\''' \
    '    ;;' \
    '  "pane list"*)' \
    '    cat "$HERDR_PANE_LIST"' \
    '    ;;' \
    'esac' >"$fakebin/herdr"
chmod +x "$fakebin/herdr"

printf '%s\n' '#!/usr/bin/env python3' \
    'import json' \
    'import sys' \
    '' \
    'args = sys.argv[1:]' \
    'field = None' \
    'if "--arg" in args:' \
    '    arg_index = args.index("--arg")' \
    '    field = args[arg_index + 2]' \
    '' \
    'payload = json.load(sys.stdin)' \
    '' \
    'def values(value, key):' \
    '    if isinstance(value, dict):' \
    '        if key in value:' \
    '            yield value[key]' \
    '        for child in value.values():' \
    '            yield from values(child, key)' \
    '    elif isinstance(value, list):' \
    '        for child in value:' \
    '            yield from values(child, key)' \
    '' \
    'if field is not None:' \
    '    for result in values(payload, field):' \
    '        print(result)' \
    '    sys.exit(0)' \
    '' \
    'panes = payload["result"]["panes"]' \
    'focused = [pane for pane in panes if pane.get("focused") is True]' \
    'if len(focused) != 1:' \
    '    sys.exit(0)' \
    'pane = focused[0]' \
    'first_pane = next(candidate for candidate in panes if candidate["tab_id"] == pane["tab_id"])' \
    'is_first = "1" if pane["pane_id"] == first_pane["pane_id"] else "0"' \
    'print("\t".join([pane["pane_id"], pane["tab_id"], pane["workspace_id"], is_first]))' \
    >"$fakebin/jq"
chmod +x "$fakebin/jq"

set -gx PATH "$fakebin" $PATH
set -gx HERDR_LOG "$log_file"
set -gx HERDR_PANE_LIST "$pane_list_file"
set -gx HOME "$tmpdir/home"
set -gx DOTS "$tmpdir/dots"
set -gx SHELL /usr/bin/fish
set -e HERDR_ENV \
    __herdr_dynamic_title_pane_id \
    __herdr_dynamic_title_tab_id \
    __herdr_dynamic_title_is_first_pane \
    __herdr_dynamic_title_restore_label

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
source "$function_dir/_herdr_response_id.fish"
source "$function_dir/_herdr_current_pane_context.fish"
source "$function_dir/_herdr_command_label.fish"
source "$function_dir/herdr_layout_default.fish"
source "$function_dir/herdr_new_workspace.fish"
source "$repo_root/home/private_dot_config/fish/conf.d/herdr_dynamic_titles.fish"

if not functions -q _herdr_response_id
    printf 'ASSERTION FAILED: hidden Herdr response helper is available\n' >&2
    exit 1
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

herdr_new_workspace "$tmpdir/feature-x" --simple
set -l last_command (string trim -- (command tail -n 1 "$log_file"))
assert_eq "$last_command" "workspace create --cwd $tmpdir/feature-x --label dots.feature-x --focus" 'simple workspace uses derived worktree label'
assert_eq (command wc -l <"$log_file" | string trim) 1 'long simple flag skips layout commands'

printf '' >"$log_file"
herdr_new_workspace "$DOTS/demo.txt" -s --label docs
set last_command (string trim -- (command tail -n 1 "$log_file"))
assert_eq "$last_command" "workspace create --cwd $DOTS --label docs --focus" 'short simple flag supports explicit label and file cwd parent'
assert_eq (command wc -l <"$log_file" | string trim) 1 'short simple flag skips layout commands'

printf '' >"$log_file"
herdr_new_workspace "$tmpdir/feature-x"
set -l command_log (string join \n (string trim -- (command cat "$log_file")))
set -l expected_log (string join \n \
    "workspace create --cwd $tmpdir/feature-x --label dots.feature-x --focus" \
    "pane split w-test-1 --direction right --cwd $tmpdir/feature-x --no-focus" \
    "pane split w-test-2 --direction down --cwd $tmpdir/feature-x --no-focus" \
    "tab create --workspace w-test --cwd $tmpdir/feature-x --no-focus" \
    "tab focus w-test:1")
assert_eq "$command_log" "$expected_log" 'default workspace applies reusable split layout and refocuses first tab'

printf '' >"$log_file"
herdr_layout_default --workspace w-test --tab w-test:1 --pane w-test-1 --cwd "$tmpdir/feature-x"
set command_log (string join \n (string trim -- (command cat "$log_file")))
set expected_log (string join \n \
    "pane split w-test-1 --direction right --cwd $tmpdir/feature-x --no-focus" \
    "pane split w-test-2 --direction down --cwd $tmpdir/feature-x --no-focus" \
    "tab create --workspace w-test --cwd $tmpdir/feature-x --no-focus" \
    "tab focus w-test:1")
assert_eq "$command_log" "$expected_log" 'default layout can be called independently'

printf '' >"$log_file"
set -e HERDR_ENV
__herdr_dynamic_title_preexec 'nvim README.md'
__herdr_dynamic_title_postexec
assert_eq (command wc -l <"$log_file" | string trim) 0 'dynamic title hooks no-op outside Herdr'

set -gx HERDR_ENV 1
printf '%s\n' '{"result":{"panes":[{"pane_id":"w-test-1","tab_id":"w-test:1","workspace_id":"w-test","focused":true},{"pane_id":"w-test-2","tab_id":"w-test:1","workspace_id":"w-test","focused":false}]}}' >"$pane_list_file"
printf '' >"$log_file"
pushd "$tmpdir/feature-x" >/dev/null
__herdr_dynamic_title_preexec 'nvim README.md'
__herdr_dynamic_title_postexec
popd >/dev/null
set command_log (string join \n (string trim -- (command cat "$log_file")))
set expected_log (string join \n \
    'pane list' \
    'pane report-metadata w-test-1 --source fish-command --title nvim --ttl-ms 300000' \
    'tab rename w-test:1 nvim' \
    'pane report-metadata w-test-1 --source fish-command --clear-title' \
    'tab rename w-test:1 fish')
assert_eq "$command_log" "$expected_log" 'first pane restores tab label to shell after command lifecycle'

printf '%s\n' '{"result":{"panes":[{"pane_id":"w-test-1","tab_id":"w-test:1","workspace_id":"w-test","focused":false},{"pane_id":"w-test-2","tab_id":"w-test:1","workspace_id":"w-test","focused":true}]}}' >"$pane_list_file"
printf '' >"$log_file"
__herdr_dynamic_title_preexec 'git status --short'
__herdr_dynamic_title_postexec
set command_log (string join \n (string trim -- (command cat "$log_file")))
set expected_log (string join \n \
    'pane list' \
    'pane report-metadata w-test-2 --source fish-command --title git --ttl-ms 300000' \
    'pane report-metadata w-test-2 --source fish-command --clear-title')
assert_eq "$command_log" "$expected_log" 'non-first pane updates pane metadata without tab rename'

printf '%s\n' '{"result":{"panes":[{"pane_id":"w-test-1","tab_id":"w-test:1","workspace_id":"w-test","focused":true},{"pane_id":"w-test-2","tab_id":"w-test:1","workspace_id":"w-test","focused":true}]}}' >"$pane_list_file"
printf '' >"$log_file"
__herdr_dynamic_title_preexec 'nvim README.md'
__herdr_dynamic_title_postexec
set command_log (string join \n (string trim -- (command cat "$log_file")))
assert_eq "$command_log" 'pane list' 'ambiguous focused pane resolution avoids metadata and tab updates'

printf 'ok\n'
