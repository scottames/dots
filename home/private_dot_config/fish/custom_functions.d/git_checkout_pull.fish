#!/bin/env fish

function git_checkout_pull \
  --description "Git checkout branch (1 - default: head branch) and pull"

  _arg_req_one $argv || return 1

  git checkout $argv[1] && \
    git pull
end
