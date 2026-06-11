#!/bin/env fish

function git_status --description "Git project status" --wraps "git status"
    set -l _is_inside_git_repo (git rev-parse --is-inside-work-tree 2>/dev/null)

    if [ $_is_inside_git_repo ]
        printf_green_bold "\n🌳 worktrees\n\n"
        if type -q wt
            wt list 2>/dev/null
            or command git worktree list \
                | string match -v -r '\.bare' \
                | string replace $HOME '~' \
                | string replace /var ""
        else
            command git worktree list \
                | string match -v -r '\.bare' \
                | string replace $HOME '~' \
                | string replace /var ""
        end

        set -l _org "$( dirname (
      git config --get remote.origin.url \
      | string replace 'git@github.com:' '' \
      | string replace 'https://github.com/' ''
    ))"
        set -l _proj (project_label --project-only "$PWD")
        if test -z "$_proj"
            set _proj "$( basename (
          git config --get remote.origin.url
        ) | string replace '.git' ''
      )"
        end
        set -l _git_toplevel (git rev-parse --show-toplevel)
        set -l _base_pwd

        if test (project_label "$PWD") != "$_proj" # worktree sub-dir
            set _base_pwd "$(basename $_git_toplevel)"
        end

        printf "\n📂 "
        pwd | string replace $HOME '~' | string replace /var "" \
            | string replace -r "\/$_org\/([^/\s]+)" \
            "/$(printf_color -c cyan -b $_org)/$(printf_color -c magenta -b $_proj)" \
            | string replace "$_base_pwd" (printf_color -c yellow -b $_base_pwd)
    end

    set -q HAS_GT && PAGER="" gt ls
    git status $argv
end
