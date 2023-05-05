#!/bin/env fish

# https://github.com/charmbracelet/gum/blob/main/examples/commit.sh
function  gum_commit --description "Interactively commit w/ conventional commit"
  if test -z "$(git status -s -uno | grep -v '^ ' | awk '{print $2}')"
    gum confirm "Stage all?" || return 1
    git add .
  end

  set -l _TYPE (gum choose "fix" "feat" "docs" "style" "refactor" "test" "chore" "revert")
  set -l _SCOPE (gum input --placeholder "scope")
  if test -n "$_SCOPE"
    set _SCOPE "($_SCOPE)"
    echo "Scope: $_SCOPE"
  end

  set -l _SUMMARY (gum input --value "$_TYPE$_SCOPE: " --placeholder "Summary of this change")
  set -l _DESCRIPTION (gum write --placeholder "Details of this change")

  gum confirm "Commit changes?" && git commit -m "$_SUMMARY" -m "$_DESCRIPTION"
end

