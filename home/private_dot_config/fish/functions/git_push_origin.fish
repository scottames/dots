#!/bin/env fish

function git_push_origin
  git push --set-upstream origin (git branch | grep \* | cut -d ' ' -f2)
end
