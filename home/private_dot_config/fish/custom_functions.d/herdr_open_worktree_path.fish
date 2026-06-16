#!/usr/bin/env fish

function herdr_open_worktree_path \
    --description "Open an existing Git worktree under a Herdr parent workspace."

    # Low-level helper used by herdr_wt_switch.
    #
    # Usage:
    #   herdr_open_worktree_path <main-checkout-path> <worktree-path>
    #
    # Examples:
    #   herdr_open_worktree_path ~/src/github.com/scottames/copr/main \
    #       ~/src/github.com/scottames/copr/foo
    #
    #   herdr_open_worktree_path ~/src/github.com/scottames/dots/main \
    #       ~/src/github.com/scottames/dots/foo
    #
    # The second example works for legacy .bare repos too: when the supplied
    # main checkout is itself a linked worktree, this function uses the .bare Git
    # common dir as Herdr's source --cwd because Herdr rejects linked-worktree
    # sources for worktree open/create actions.

    argparse -n herdr_open_worktree_path -- $argv
    or return 1

    if test (count $argv) -ne 2
        printf 'Usage: herdr_open_worktree_path <main-checkout-path> <worktree-path>\n' >&2
        return 1
    end

    set -l main_checkout $argv[1]
    set -l worktree_path $argv[2]

    if not test -e "$main_checkout"
        printf 'herdr_open_worktree_path: main checkout path not found: %s\n' "$main_checkout" >&2
        return 1
    end

    if not test -e "$worktree_path"
        printf 'herdr_open_worktree_path: worktree path not found: %s\n' "$worktree_path" >&2
        return 1
    end

    if test -f "$main_checkout"
        set main_checkout (path dirname "$main_checkout")
    end
    set main_checkout (path resolve "$main_checkout")

    set -l herdr_source "$main_checkout"
    set -l common_dir (command git -C "$main_checkout" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if test (path basename -- "$common_dir") = .bare
        set herdr_source "$common_dir"
    end

    if test -f "$worktree_path"
        set worktree_path (path dirname "$worktree_path")
    end
    set worktree_path (path resolve "$worktree_path")

    set -l label (project_label "$worktree_path")

    set -l worktree_result (command herdr worktree open \
        --cwd "$herdr_source" \
        --path "$worktree_path" \
        --label "$label" \
        --focus \
        --json)
    or return 1

    set -l workspace_id (_herdr_response_id workspace_id "$worktree_result" 2>/dev/null)
    or begin
        printf 'herdr_open_worktree_path: workspace_id missing from herdr response\n' >&2
        return 1
    end

    set -l tab_id (_herdr_response_id tab_id "$worktree_result" 2>/dev/null)
    or begin
        printf 'herdr_open_worktree_path: tab_id missing from herdr response\n' >&2
        return 1
    end

    set -l pane_id (_herdr_response_id pane_id "$worktree_result" 2>/dev/null)
    or begin
        printf 'herdr_open_worktree_path: pane_id missing from herdr response\n' >&2
        return 1
    end

    herdr_layout_default \
        --workspace "$workspace_id" \
        --tab "$tab_id" \
        --pane "$pane_id" \
        --cwd "$worktree_path"
end
