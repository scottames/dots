#!/bin/env fish

function git_clone_cd --description "Clone Git repository & cd into it" --wraps "git clone"
  set _url $argv[1]
  set _reponame (echo $_url | awk -F/ '{print $NF}' | sed -e 's/.git$//')
  git clone $_url $_reponame && cd $_reponame
end
