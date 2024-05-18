#!/bin/env fish

function git_clone_for_worktrees \
    --description "Clone Git repository for working with worktrees"
    # Examples:
    #   git_clone_for_worktrees git@github.com:name/repo.git
    #     => clones to a /repo directory
    #
    #   git_clone_for_worktrees git@github.com:name/repo.git my-repo
    #     => clones to a /my-repo directory

    _arg_req_one $argv || return 1

    set -l url $argv[1]
    set -l name (basename (string replace ".git" "" $url))

    mkdir -p $name
    if not test -d $name
        printf_err "Unable to create directory '$name'\n"
        return 1
    end

    # Moves all the administrative git files (a.k.a $GIT_DIR) under .bare directory.
    #
    # Plan is to create worktrees as siblings of this directory.
    # Example targeted structure:
    # .bare
    # main
    # new-awesome-feature
    # hotfix-bug-12
    # ...
    printf_info "Cloning to .bare in $name\n"
    pushd $name

    if not test -d .bare
        git clone --bare $url .bare
    else
        printf_warn ".bare directory exists, skipping clone\n"
    end

    echo "gitdir: ./.bare" >.git

    printf_info "Setting up origin\n"
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*" # set remote origin fetch to fetch remote branches
    git fetch origin # fetch all branches from origin

    set -l _git_main_branch (git remote show origin | sed -n '/HEAD branch/s/.*: //p')
    if not test -d $_git_main_branch
        printf_info "Creating initial worktree for main branch: $_git_main_branch\n"
        git worktree add $_git_main_branch $_git_main_branch

        if not test -d $_git_main_branch
            printf_err "Unable to create initial worktree for '$_git_main_branch'\n"
            return 1
        end
        cd $_git_main_branch
        git branch --set-upstream-to=origin/$_git_main_branch $_git_main_branch
    else
        printf_warn "Directory for branch '$_git_main_branch' exists, skipping initial worktree creation\n"
    end

    popd

    # source inspiration:
    #   https://morgan.cugerone.com/blog/workarounds-to-git-worktree-using-bare-repository-and-cannot-fetch-remote-branches/
end
