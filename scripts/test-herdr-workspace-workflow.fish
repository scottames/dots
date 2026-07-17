#!/usr/bin/env fish

set -l repo_root (path dirname (path dirname (status filename)))
set -l function_dir "$repo_root/home/private_dot_config/fish/custom_functions.d"
set -l tmpdir (mktemp -d)
set -l fakebin "$tmpdir/bin"
set -l log_file "$tmpdir/herdr.log"
set -l wt_log_file "$tmpdir/wt.log"
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
    '  "worktree open"*)' \
    '    if [[ -n "$HERDR_WORKTREE_OPEN_EXIT" ]]; then exit "$HERDR_WORKTREE_OPEN_EXIT"; fi' \
    '    if [[ -n "$HERDR_WORKTREE_OPEN_RESPONSE" ]]; then printf '\''%s\n'\'' "$HERDR_WORKTREE_OPEN_RESPONSE"; else printf '\''{"result":{"workspace":{"workspace_id":"w-test"},"tab":{"tab_id":"w-test:1"},"root_pane":{"pane_id":"w-test-1"}}}\n'\''; fi' \
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

printf '%s\n' '#!/usr/bin/env bash' \
    'printf "%s\n" "$*" >>"$WT_LOG"' \
    'if [[ "$*" == "switch --no-cd --format json" ]]; then' \
    '  printf '\''{"action":"switched","branch":"feature-x","path":"%s"}\n'\'' "$WT_WORKTREE_PATH"' \
    '  exit 0' \
    'fi' \
    'if [[ "$*" == "step eval {{ primary_worktree_path }}" ]]; then' \
    '  printf '\''%s\n'\'' "$WT_PRIMARY_WORKTREE_PATH"' \
    '  exit 0' \
    'fi' \
    'execute=""' \
    'args=()' \
    'while (($#)); do' \
    '  case "$1" in' \
    '    -x|--execute)' \
    '      execute="$2"' \
    '      shift 2' \
    '      ;;' \
    '    --)' \
    '      shift' \
    '      while (($#)); do' \
    '        case "$1" in' \
    '          "{{ primary_worktree_path }}") args+=("$WT_PRIMARY_WORKTREE_PATH") ;;' \
    '          "{{ worktree_path }}") args+=("$WT_WORKTREE_PATH") ;;' \
    '          *) args+=("$1") ;;' \
    '        esac' \
    '        shift' \
    '      done' \
    '      break' \
    '      ;;' \
    '    *) shift ;;' \
    '  esac' \
    'done' \
    'if [[ -n "$execute" ]]; then' \
    '  if [[ "$execute" == fish ]]; then' \
    '    command_text="${args[1]}"' \
    '    command_args=("${args[@]:2}")' \
    '    PATH="$TEST_PATH" "$execute" --no-config -c '\''set -l function_dir "$argv[1]"; set -l command_text "$argv[2]"; set -e argv[1]; set -e argv[1]; source "$function_dir/project_label.fish"; source "$function_dir/zellij_tab_name.fish"; source "$function_dir/_herdr_response_id.fish"; source "$function_dir/herdr_layout_default.fish"; source "$function_dir/herdr_open_worktree_path.fish"; eval "$command_text"'\'' -- "$TEST_FUNCTION_DIR" "$command_text" "${command_args[@]}"' \
    '    exit $?' \
    '  fi' \
    '  "$execute" "${args[@]}"' \
    'fi' >"$fakebin/wt"
chmod +x "$fakebin/wt"

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
    'if args == ["-r", ".path // empty"]:' \
    '    print(payload.get("path", ""))' \
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
set -gx WT_LOG "$wt_log_file"
set -gx HERDR_PANE_LIST "$pane_list_file"
set -gx HOME "$tmpdir/home"
set -gx DOTS "$tmpdir/dots"
set -gx LEGACY_DOTS "$tmpdir/legacy-dots"
set -gx SHELL /usr/bin/fish
set -gx WT_PRIMARY_WORKTREE_PATH "$DOTS"
set -gx WT_WORKTREE_PATH "$tmpdir/feature-x"
set -gx TEST_FUNCTION_DIR "$function_dir"
set -gx TEST_PATH "$fakebin:"(string join : $PATH)
set -gx COMMAND_LABEL_SUBSTITUTIONS ''
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

command git clone --bare "$DOTS" "$LEGACY_DOTS/.bare" >/dev/null 2>&1
command git -C "$LEGACY_DOTS/.bare" worktree add "$LEGACY_DOTS/main" main >/dev/null
command git -C "$LEGACY_DOTS/.bare" worktree add "$LEGACY_DOTS/foo" feature-x >/dev/null

printf 'demo\n' >"$DOTS/demo.txt"
printf 'feature demo\n' >"$tmpdir/feature-x/demo.txt"

source "$function_dir/project_label.fish"
source "$function_dir/zellij_tab_name.fish"
source "$function_dir/_herdr_response_id.fish"
source "$function_dir/_herdr_current_pane_context.fish"
source "$function_dir/_herdr_command_label.fish"
source "$function_dir/herdr_layout_default.fish"
source "$function_dir/herdr_new_workspace.fish"
source "$function_dir/herdr_open_worktree_path.fish"
source "$function_dir/herdr_wt_switch.fish"
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
herdr_open_worktree_path "$DOTS" "$tmpdir/feature-x"
set command_log (string join \n (string trim -- (command cat "$log_file")))
set expected_log (string join \n \
    "worktree open --cwd $DOTS --path $tmpdir/feature-x --label dots:feature-x --focus --json" \
    "pane split w-test-1 --direction right --cwd $tmpdir/feature-x --no-focus" \
    "pane split w-test-2 --direction down --cwd $tmpdir/feature-x --no-focus" \
    "tab create --workspace w-test --cwd $tmpdir/feature-x --no-focus" \
    "tab focus w-test:1")
assert_eq "$command_log" "$expected_log" 'opening a worktree uses main cwd, target path, derived label, and default layout'

printf '' >"$log_file"
herdr_open_worktree_path "$LEGACY_DOTS/main" "$LEGACY_DOTS/foo"
set command_log (string join \n (string trim -- (command cat "$log_file")))
set expected_log (string join \n \
    "worktree open --cwd $LEGACY_DOTS/.bare --path $LEGACY_DOTS/foo --label legacy-dots:feature-x --focus --json" \
    "pane split w-test-1 --direction right --cwd $LEGACY_DOTS/foo --no-focus" \
    "pane split w-test-2 --direction down --cwd $LEGACY_DOTS/foo --no-focus" \
    "tab create --workspace w-test --cwd $LEGACY_DOTS/foo --no-focus" \
    "tab focus w-test:1")
assert_eq "$command_log" "$expected_log" 'legacy bare repos use the bare common dir as Herdr source'

printf '' >"$log_file"
herdr_open_worktree_path "$DOTS/demo.txt" "$tmpdir/feature-x/demo.txt"
set command_log (string join \n (string trim -- (command cat "$log_file")))
set expected_log (string join \n \
    "worktree open --cwd $DOTS --path $tmpdir/feature-x --label dots:feature-x --focus --json" \
    "pane split w-test-1 --direction right --cwd $tmpdir/feature-x --no-focus" \
    "pane split w-test-2 --direction down --cwd $tmpdir/feature-x --no-focus" \
    "tab create --workspace w-test --cwd $tmpdir/feature-x --no-focus" \
    "tab focus w-test:1")
assert_eq "$command_log" "$expected_log" 'file arguments are normalized to their parent checkout directories'

printf '' >"$log_file"
not herdr_open_worktree_path "$tmpdir/missing-main" "$tmpdir/feature-x" >/dev/null 2>&1
assert_eq $status 0 'missing main checkout path returns non-zero'

printf '' >"$log_file"
not herdr_open_worktree_path "$DOTS" "$tmpdir/missing-feature" >/dev/null 2>&1
assert_eq $status 0 'missing worktree path returns non-zero'

printf '' >"$log_file"
set -gx HERDR_WORKTREE_OPEN_EXIT 42
not herdr_open_worktree_path "$DOTS" "$tmpdir/feature-x" >/dev/null 2>&1
assert_eq $status 0 'herdr worktree open failures return non-zero'
assert_eq (command wc -l <"$log_file" | string trim) 1 'failed herdr open does not run layout commands'
set -e HERDR_WORKTREE_OPEN_EXIT

printf '' >"$log_file"
set -gx HERDR_WORKTREE_OPEN_RESPONSE '{"result":{"workspace":{"workspace_id":"w-test"}}}'
not begin
    herdr_open_worktree_path "$DOTS" "$tmpdir/feature-x"
end >/dev/null 2>&1
assert_eq $status 0 'missing herdr response IDs return non-zero'
assert_eq (command wc -l <"$log_file" | string trim) 1 'missing response IDs do not run layout commands'
set -e HERDR_WORKTREE_OPEN_RESPONSE

printf '' >"$log_file"
printf '' >"$wt_log_file"
herdr_wt_switch feature-x
assert_eq (string trim -- (command cat "$wt_log_file")) "switch --no-cd feature-x -x fish -- -lc herdr_open_worktree_path \"\$argv[1]\" \"\$argv[2]\" {{ primary_worktree_path }} {{ worktree_path }}" 'Worktrunk switch uses primary worktree and destination templates'
set command_log (string join \n (string trim -- (command cat "$log_file")))
set expected_log (string join \n \
    "worktree open --cwd $DOTS --path $tmpdir/feature-x --label dots:feature-x --focus --json" \
    "pane split w-test-1 --direction right --cwd $tmpdir/feature-x --no-focus" \
    "pane split w-test-2 --direction down --cwd $tmpdir/feature-x --no-focus" \
    "tab create --workspace w-test --cwd $tmpdir/feature-x --no-focus" \
    "tab focus w-test:1")
assert_eq "$command_log" "$expected_log" 'Worktrunk switch opens the resolved worktree in Herdr'

printf '' >"$log_file"
printf '' >"$wt_log_file"
herdr_wt_switch
set -l wt_log (string join \n (string trim -- (command cat "$wt_log_file")))
set -l expected_wt_log (string join \n \
    "switch --no-cd --format json" \
    "step eval {{ primary_worktree_path }}")
assert_eq "$wt_log" "$expected_wt_log" 'no branch uses Worktrunk JSON picker flow'
set command_log (string join \n (string trim -- (command cat "$log_file")))
set expected_log (string join \n \
    "worktree open --cwd $DOTS --path $tmpdir/feature-x --label dots:feature-x --focus --json" \
    "pane split w-test-1 --direction right --cwd $tmpdir/feature-x --no-focus" \
    "pane split w-test-2 --direction down --cwd $tmpdir/feature-x --no-focus" \
    "tab create --workspace w-test --cwd $tmpdir/feature-x --no-focus" \
    "tab focus w-test:1")
assert_eq "$command_log" "$expected_log" 'no branch opens the Worktrunk picker selection in Herdr'

printf '' >"$log_file"
printf '' >"$wt_log_file"
herdr_wt_switch --create --base main feature-y
assert_eq (string trim -- (command cat "$wt_log_file")) "switch --no-cd --create --base main feature-y -x fish -- -lc herdr_open_worktree_path \"\$argv[1]\" \"\$argv[2]\" {{ primary_worktree_path }} {{ worktree_path }}" 'create and base flags are forwarded to Worktrunk'

set -l abbrs_file "$repo_root/home/private_dot_config/fish/conf.d/abbrs.fish"
if command grep -q '^abbr -a hwo' "$abbrs_file"
    printf 'ASSERTION FAILED: hwo abbreviation is removed\n' >&2
    exit 1
end
command grep -q '^abbr -a hwt herdr_wt_switch$' "$abbrs_file"
or begin
    printf 'ASSERTION FAILED: hwt abbreviation points at herdr_wt_switch\n' >&2
    exit 1
end
command grep -q '^abbr -a hwtc "herdr_wt_switch --create"$' "$abbrs_file"
or begin
    printf 'ASSERTION FAILED: hwtc abbreviation creates through herdr_wt_switch\n' >&2
    exit 1
end

set -l herdr_config "$repo_root/home/private_dot_config/herdr/config.toml"
command grep -q 'key = "prefix+alt+w"' "$herdr_config"
or begin
    printf 'ASSERTION FAILED: herdr Worktrunk keybind uses prefix+alt+w\n' >&2
    exit 1
end
command grep -q 'command = "fish -lc '\''herdr_wt_switch'\''"' "$herdr_config"
or begin
    printf 'ASSERTION FAILED: herdr Worktrunk keybind launches hwt picker\n' >&2
    exit 1
end

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

set -gx COMMAND_LABEL_SUBSTITUTIONS 'nono-with-local-path=oc opencode=oc'
assert_eq (_herdr_command_label nono-with-local-path wrap --profile opencode-local --allow-cwd -- opencode --continue) oc 'nono opencode wrapper labels as command substitution'
assert_eq (_herdr_command_label nono wrap --profile opencode-local --allow-cwd -- opencode --continue) oc 'raw nono opencode wrapper labels as command substitution'
assert_eq (_herdr_command_label nono-with-local-path wrap --profile claude-code --allow-cwd -- claude) claude 'nono claude wrapper labels as wrapped command'
assert_eq (_herdr_command_label nono-pi --continue) pi 'nono-pi wrapper labels as pi'
set -e COMMAND_LABEL_SUBSTITUTIONS

set -l isolated_label (env COMMAND_LABEL_SUBSTITUTIONS='opencode=oc' fish --no-config -c 'source "$argv[1]"; _herdr_command_label nono-with-local-path wrap --profile opencode-local --allow-cwd -- opencode' -- "$function_dir/_herdr_command_label.fish")
assert_eq "$isolated_label" oc 'command label helper loads substitutions helper when sourced alone'

printf 'ok\n'
