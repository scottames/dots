#!/bin/env fish

function def --description "define a word"
  _arg_req_one $argv || return 1

  curl -Ss "dict://dict.org/d:$argv[1]" | $PAGER
end
