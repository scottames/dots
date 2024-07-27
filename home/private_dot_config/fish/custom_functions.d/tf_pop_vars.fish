#!/bin/env fish

function tf_pop_vars --description "Populate variables from Terraform files"
    set -l _variables_tf *.tf
    if test (count $argv) -ge 1
        set _variables_tf $argv
    end

    for var in (rg ^variable $_variables_tf | cut -d \" -f2)
        echo "$var = \"\" # FIXME"
    end
end
