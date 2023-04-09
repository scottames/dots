#!/bin/env fish

function grep
    command grep --color=auto --exclude-dir="{.git}" $argv
end
