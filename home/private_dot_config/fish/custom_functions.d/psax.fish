#!/bin/env fish

function psax --description "ps with a grep" --wraps grep
    ps auxwwwh | grep $argv | grep -v grep
end
