#!/bin/env fish

function gh \
  --description "GitHub CLI. Runs behind op, if installed for GitHub API auth."
  if [ $HAS_OP ]
    op run -- gh $argv
  else
    command gh $argv
  end
end
