#!/bin/env fish

# zw: Open a git worktree in a new Zellij tab with auto-derived naming
#
# Combines worktrunk (wt), zellij, and optionally graphite (gt) to reduce
# friction when spinning up worktree tabs for parallel work.
#
# Usage: zw [OPTIONS] [BRANCH]
#
# Options:
#   -c/--create       Create a new worktree (passes -c to wt switch)
#   -g/--graphite     Create as graphite-tracked branch (uses gt-wt-create)
#   -a/--agent        Start an agent in the tab (default: opencode)
#   --agent=NAME      Specify which agent (opencode, claude, etc.)
#   -b/--base=REF     Base branch for creation (passed to wt switch -b / gt-wt-create -b)
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
#   zw -cg my-feature               # create graphite-tracked worktree + tab
#   zw -cga my-feature              # create graphite-tracked worktree + tab + opencode
#   zw -c --agent=claude my-feature # create worktree + tab + start claude
#   zw -c -b develop my-feature     # create worktree from 'develop' branch
#   zw -n "custom-name" feature-a   # override tab name
#
# Requirements:
#   - zellij (must be inside a zellij session)
#   - worktrunk (wt)
#   - jq
#   - ugum or gum (for picker mode)
#   - graphite (gt) + gt-wt-create (only with -g flag)

function zw --description "Open a git worktree in a new Zellij tab"
    argparse \
        'c/create' \
        'g/graphite' \
        'a/agent' \
        'agent=?' \
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
        echo "  -g/--graphite     Create as graphite-tracked branch"
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

    if not type -q wt
        printf_err "worktrunk (wt) is required but not found\n"
        return 1
    end

    # --- Repo detection ---

    set -l repo_root (dirname (git rev-parse --path-format=absolute --git-common-dir))
    set -l project (basename "$repo_root")
    set -l default_branch (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@refs/remotes/origin/@@')
    if test -z "$default_branch"
        set default_branch main
    end

    # --- Resolve branch ---

    set -l branch
    if test (count $argv) -ge 1
        set branch $argv[1]
    else
        # Picker mode
        if not type -q jq
            printf_err "jq is required for picker mode\n"
            return 1
        end

        set -l gum_bin ugum
        if not type -q $gum_bin
            set gum_bin gum
        end
        if not type -q $gum_bin
            printf_err "ugum or gum is required for picker mode\n"
            return 1
        end

        set -l branches (wt list --format=json | jq -r '.[].branch')
        if test -z "$branches"
            printf_err "no worktrees found\n"
            return 1
        end

        set branch (printf '%s\n' $branches | $gum_bin filter --header="pick a worktree...")
        if test -z "$branch"
            return 0
        end
    end

    # --- Create worktree if needed ---

    set -l worktree_path (wt list --format=json | jq -r --arg b "$branch" '.[] | select(.branch == $b) | .path')

    if test -z "$worktree_path"
        # Worktree doesn't exist — create it
        if set -q _flag_graphite
            # Graphite-tracked creation
            if not type -q gt-wt-create
                printf_err "gt-wt-create is required with -g flag\n"
                return 1
            end

            set -l gt_args --no-cd
            if set -q _flag_base
                set -a gt_args -b "$_flag_base"
            end
            set -a gt_args "$branch"

            gt-wt-create $gt_args
            or return 1
        else
            # Standard wt creation
            set -l wt_args --no-cd
            if set -q _flag_create
                set -a wt_args -c
            end
            if set -q _flag_base
                set -a wt_args -b "$_flag_base"
            end
            set -a wt_args "$branch"

            command wt switch $wt_args
            or return 1
        end

        # Query the path after creation
        set worktree_path (wt list --format=json | jq -r --arg b "$branch" '.[] | select(.branch == $b) | .path')
        if test -z "$worktree_path"
            printf_err "worktree created but could not resolve path for '$branch'\n"
            return 1
        end
    end

    # --- Derive tab name ---

    set -l tab_name
    if set -q _flag_name
        set tab_name "$_flag_name"
    else
        set -l prefix "$TAB_PREFIX"
        if test "$branch" = "$default_branch"
            set tab_name "$prefix$project"
        else
            set tab_name "$prefix$project/$branch"
        end
    end

    # --- Generate layout and open tab ---

    set -l agent_pane "pane"
    if set -q _flag_agent; or set -q _flag_agent_value
        set -l agent_cmd opencode
        if set -q _flag_agent_value; and test -n "$_flag_agent_value"
            set agent_cmd "$_flag_agent_value"
        end
        set agent_pane "pane command=\"$agent_cmd\""
    end

    set -l status_pane ""
    if test -f "$HOME/.config/zellij/plugins/zellij-status.wasm"
        set status_pane "
        pane size=1 borderless=true {
            plugin location=\"zellij-status\"
        }"
    end

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
