#!/bin/env fish

function aqua \
  --description "Declarative CLI Version manager. Runs behind op, if installed for GitHub API auth." \
  --wraps aqua

  if $HAS_OP
    op run -- aqua $argv
  else
    command aqua $argv
  end
end
