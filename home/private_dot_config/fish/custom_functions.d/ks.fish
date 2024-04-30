#!/bin/env fish

function ks \
    --wraps switcher \
    --description "The kubectx for operators."
    switcher $argv
end
