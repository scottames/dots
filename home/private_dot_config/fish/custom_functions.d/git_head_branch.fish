#!/bin/env fish

function git_head_branch --description "Returns the head branch"
  git remote show origin | grep "HEAD branch" | cut -d ":" -f 2 | xargs
end
