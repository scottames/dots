#!/bin/env fish

function git_status --description "Git project status" --wraps "git status"
    set -l _is_inside_git_repo (git rev-parse --is-inside-work-tree 2>/dev/null)

    if [ $_is_inside_git_repo ]
        printf_green_bold "\n🌳 worktrees\n\n"
        git worktree list | grep -v '.bare' | string replace $HOME '~' | string replace /var ""

        set -l _org "$( dirname (
      git config --get remote.origin.url \
      | string replace 'git@github.com:' '' \
      | string replace 'https://github.com/' ''
    ))"
        set -l _proj "$( basename (
        git config --get remote.origin.url
      ) | string replace '.git' ''
    )"
        set -l _git_toplevel (git rev-parse --show-toplevel)
        set -l _base_pwd

        if [ $_proj != "$(basename $_git_toplevel)" ] # worktree sub-dir
            set _base_pwd "$(basename $_git_toplevel)"
        end

        printf "\n📂 "
        pwd | string replace $HOME '~' | string replace /var "" \
            | string replace -r "\/$_org\/([^/\s]+)" \
            "/$(printf_color -c cyan -b $_org)/$(printf_color -c magenta -b $_proj)" \
            | string replace "$_base_pwd" (printf_color -c yellow -b $_base_pwd)
    end

    git status $argv
end
