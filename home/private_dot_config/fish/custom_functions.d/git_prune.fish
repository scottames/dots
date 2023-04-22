#!/bin/env fish

function git_prune --description "Prune local branches no longer at origin"
  git remote prune origin
  git branch -vv | grep 'origin/.*: gone]' | awk '{print $1}' | xargs git branch -D
end
