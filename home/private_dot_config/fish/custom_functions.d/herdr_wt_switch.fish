#!/usr/bin/env fish

function herdr_wt_switch \
    --description "Switch/create a Worktrunk worktree and open it in Herdr."

    # Abbreviations:
    #   hw = herdr_new_workspace
    #   hwt = herdr_wt_switch
    #   hwtc = herdr_wt_switch --create
    #
    # User workflow:
    #   herdr_new_workspace
    #       Open the repo's main Herdr workspace first. Abbreviation: hw.
    #
    #   herdr_wt_switch
    #       Open Worktrunk's picker. Press Enter on an existing worktree to open
    #       it in Herdr. To create from the picker, type the new branch/worktree
    #       name first, then press Alt-c. Alt-c uses the current filter text; it
    #       is not a separate prompt. Abbreviation: hwt.
    #
    #   herdr_wt_switch foo
    #       Open the existing foo worktree directly.
    #
    #   herdr_wt_switch --create fix-herdr-flow
    #       Create fix-herdr-flow through Worktrunk, then open it in Herdr.
    #       Abbreviation: hwtc fix-herdr-flow.
    #
    #   herdr_wt_switch --create --base @ fix-from-current
    #       Create from the current branch shortcut. Other Worktrunk --base
    #       values, such as main or pr:123, are forwarded to wt. Abbreviation:
    #       hwtc --base @ fix-from-current.
    #
    # Herdr keybind:
    #   prefix+alt+w runs this function with no arguments, so it starts the same
    #   picker flow as herdr_wt_switch.

    argparse -n herdr_wt_switch 'c/create' 'b/base=' 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        printf 'Usage: herdr_wt_switch [--create] [--base BASE] [BRANCH]\n'
        return 0
    end

    set -l wt_args switch --no-cd

    if set -q _flag_create
        set -a wt_args --create
    end

    if set -q _flag_base
        set -a wt_args --base "$_flag_base"
    end

    if test (count $argv) -gt 1
        printf 'Usage: herdr_wt_switch [--create] [--base BASE] [BRANCH]\n' >&2
        return 1
    end

    if set -q argv[1]
        set -a wt_args $argv[1]
    else
        if not type -q jq
            printf 'herdr_wt_switch: jq is required for picker mode\n' >&2
            return 1
        end

        set -l switch_result (command wt $wt_args --format json)
        or return 1

        set -l worktree_path (printf '%s\n' "$switch_result" | command jq -r '.path // empty')
        or return 1

        if test -z "$worktree_path"
            return 0
        end

        set -l primary_worktree_path (command wt step eval '{{ primary_worktree_path }}')
        or return 1

        herdr_open_worktree_path "$primary_worktree_path" "$worktree_path"
        return
    end

    command wt $wt_args \
        -x fish \
        -- \
        -lc 'herdr_open_worktree_path "$argv[1]" "$argv[2]"' \
        '{{ primary_worktree_path }}' \
        '{{ worktree_path }}'
end
