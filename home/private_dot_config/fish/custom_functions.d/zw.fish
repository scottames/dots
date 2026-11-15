#!/bin/env fish

# zw: Open a git worktree in a new Zellij tab with auto-derived naming
#
# Combines Stax and zellij to reduce friction when spinning up
# worktree tabs for parallel work.
#
# Usage: zw [OPTIONS] [BRANCH]
#
# Options:
#   -c/--create       Create a new worktree
#   -a/--agent        Start an agent in the tab (default: opencode)
#   --agent=NAME      Specify which agent (opencode, claude, etc.)
#   -b/--base=REF     Base branch for creation
#   -n/--name=NAME    Override the auto-derived tab name
#   -h/--help         Show usage
#
# Tab Naming:
#   Derives tab name as: ${TAB_PREFIX}${project}/${branch}
#   - TAB_PREFIX: from environment (e.g. set via direnv), defaults to empty
#   - project: basename of the repo root directory
#   - For the default branch, omits the branch suffix: ${TAB_PREFIX}${project}
#   - Override with --name
#
# Examples:
#   zw feature-a                    # open existing worktree in tab
#   zw                              # fuzzy pick from worktrees
#   zw -c my-feature                # create worktree + tab
#   zw -ca my-feature               # create worktree + tab + start opencode
#   zw -c --agent=claude my-feature # create worktree + tab + start claude
#   zw -c -b develop my-feature     # create worktree from 'develop' branch
#   zw -n "custom-name" feature-a   # override tab name
#
# Requirements:
#   - zellij (must be inside a zellij session)
#   - Stax

function zw --description "Open a git worktree in a new Zellij tab"
    argparse \
        'c/create' \
        'a/agent=?' \
        'b/base=' \
        'n/name=' \
        'h/help' \
        -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: zw [OPTIONS] [BRANCH]"
        echo ""
        echo "Options:"
        echo "  -c/--create       Create a new worktree"
        echo "  -a/--agent        Start an agent in the tab (default: opencode)"
        echo "  --agent=NAME      Specify which agent"
        echo "  -b/--base=REF     Base branch for creation"
        echo "  -n/--name=NAME    Override the auto-derived tab name"
        echo "  -h/--help         Show this help"
        return 0
    end

    # --- Guards ---

    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        printf_err "not inside a git repository\n"
        return 1
    end

    if not set -q ZELLIJ
        printf_err "not inside a zellij session\n"
        return 1
    end

    if not type -q stax
        printf_err "Stax is required but not found\n"
        return 1
    end

    set -l options
    set -q _flag_create; and set -a options --create
    set -q _flag_base; and set -a options --base "$_flag_base"
    set -l worktree_path (_stax_worktree_path $options $argv)
    or return $status
    test -n "$worktree_path"; or return 0

    # --- Derive tab name ---

    set -l tab_name
    if set -q _flag_name
        set tab_name "$_flag_name"
    else
        set -l prefix "$TAB_PREFIX"
        set tab_name "$prefix"(project_label --separator=/ "$worktree_path")
    end

    # --- Generate layout and open tab ---

    set -l agent_pane "pane"
    if set -q _flag_agent
        set -l agent_cmd opencode
        if test -n "$_flag_agent"
            set agent_cmd "$_flag_agent"
        end
        set agent_pane "pane command=\"$agent_cmd\""
    end

    set -l status_pane "
        pane size=1 borderless=true {
            plugin location=\"status-bar\"
        }"

    set -l layout_content "
layout {
    tab {
        pane split_direction=\"vertical\" {
            pane stacked=true {
                pane
                $agent_pane
            }
            pane command=\"nvim\" start_suspended=true
        }
        $status_pane
    }
}
"

    set -l layout_file (mktemp)
    printf '%s' "$layout_content" >"$layout_file"

    zellij action new-tab -c "$worktree_path" --layout "$layout_file" --name "$tab_name"
    set -l tab_result $status

    rm -f "$layout_file"

    return $tab_result
end
