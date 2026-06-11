#!/bin/env fish

function git_clone_for_worktrees \
    --description "Clone Git repository for working with worktrees"
    # Examples:
    #   git_clone_for_worktrees git@github.com:name/repo.git
    #     => clones durable main checkout to /repo/main
    #
    #   git_clone_for_worktrees git@github.com:name/repo.git my-repo
    #     => clones durable main checkout to /my-repo/main
    #
    #   git_clone_for_worktrees --bare git@github.com:name/repo.git
    #     => clones legacy .bare layout to /repo

    argparse b/bare -- $argv || return 1

    if test (count $argv) -lt 1 -o (count $argv) -gt 2
        printf_err "Usage: git_clone_for_worktrees [--bare] <url> [name]\n"
        return 1
    end

    set -l url $argv[1]
    set -l name $argv[2]
    if test -z "$name"
        set name (basename (string replace ".git" "" $url))
    end

    if not set -q _flag_bare
        set -l main_dir "$name/main"

        if test -d "$name/.bare"
            printf_err "Legacy .bare layout exists at '$name'. Use --bare for that layout.\n"
            return 1
        end

        if test -e "$main_dir"
            set -l existing_url (git -C "$main_dir" config --get remote.origin.url 2>/dev/null)
            if test "$existing_url" = "$url"
                printf_warn "Durable main checkout exists at '$main_dir', skipping clone\n"
                if test -f "$main_dir/mise.toml"
                    pushd "$main_dir" >/dev/null
                    mise trust
                    popd >/dev/null
                end
                return 0
            end

            printf_err "Existing path '$main_dir' is not a matching git checkout for '$url'\n"
            return 1
        end

        mkdir -p "$name"
        if not test -d "$name"
            printf_err "Unable to create directory '$name'\n"
            return 1
        end

        printf_info "Cloning durable main checkout to $main_dir\n"
        git clone "$url" "$main_dir"; or return 1

        if test -f "$main_dir/mise.toml"
            pushd "$main_dir" >/dev/null
            mise trust
            popd >/dev/null
        end

        printf_info "Durable main checkout lives at $main_dir; create sibling worktrees under $name\n"
        return 0
    end

    if test -d "$name/main/.git"; and not test -d "$name/.bare"
        printf_err "Normal layout exists at '$name/main'. Omit --bare for that layout.\n"
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
    mkdir -p "$name"
    if not test -d "$name"
        printf_err "Unable to create directory '$name'\n"
        return 1
    end

    pushd "$name" >/dev/null

    if not test -d .bare
        git clone --bare "$url" .bare; or begin
            popd >/dev/null
            return 1
        end
    else
        set -l existing_url (git --git-dir=.bare config --get remote.origin.url 2>/dev/null)
        if test "$existing_url" != "$url"
            printf_err "Existing .bare repository is not a matching clone for '$url'\n"
            popd >/dev/null
            return 1
        end

        printf_warn ".bare directory exists, skipping clone\n"
    end

    echo "gitdir: ./.bare" >.git

    printf_info "Setting up origin\n"
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*" # set remote origin fetch to fetch remote branches
    git fetch origin # fetch all branches from origin

    set -l _git_main_branch (git remote show origin | sed -n '/HEAD branch/s/.*: //p')
    if not test -d "$_git_main_branch"
        printf_info "Creating initial worktree for main branch: $_git_main_branch\n"
        git worktree add "$_git_main_branch" "$_git_main_branch"; or begin
            popd >/dev/null
            return 1
        end

        if not test -d "$_git_main_branch"
            printf_err "Unable to create initial worktree for '$_git_main_branch'\n"
            popd >/dev/null
            return 1
        end
        cd "$_git_main_branch"
        git branch --set-upstream-to="origin/$_git_main_branch" "$_git_main_branch"

        if test -f mise.toml
            mise trust
        end
    else
        printf_warn "Directory for branch '$_git_main_branch' exists, skipping initial worktree creation\n"
    end

    popd >/dev/null

    # source inspiration:
    #   https://morgan.cugerone.com/blog/workarounds-to-git-worktree-using-bare-repository-and-cannot-fetch-remote-branches/
end
