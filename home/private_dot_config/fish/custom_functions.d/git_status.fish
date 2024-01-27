#!/bin/env fish

function git_status --description "Git project status" --wraps "git status"
    set -l _is_inside_git_repo (git rev-parse --is-inside-work-tree 2>/dev/null)

    if [ $_is_inside_git_repo ]
        printf_green_bold "\n🌳 worktrees\n\n"
        git worktree list | string replace $HOME '~' | string replace /var ""

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
            | awk "{
        sub(\"$_org\",  \"$(set_color cyan -o  )$_org$( set_color normal)\"); \
        sub(\"$_proj\", \"$(set_color magenta -o )$_proj$(set_color normal)\"); \
        sub(\"$_base_pwd\", \"$(set_color yellow -o )$_base_pwd$(set_color normal)\"); \
      print }"
        printf "\n"
        # "$(set_color magenta)foo$(set_color cyan)bar$(set_color yellow)bam$(set_color normal)\n"
    end

    git status $argv
end
