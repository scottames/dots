#!/bin/env fish

function mkdir_cd --description "mkdir -p and cd into it" --wraps mkdir
    mkdir -p $argv \
        && builtin cd $argv[1]
end
