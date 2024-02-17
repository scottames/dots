#!/bin/env fish

function is_container \
    --description "Returns whether the existing shell is running in a container"

    if ! test -f /run/.containerenv
        printf false
        return 1
    end

    printf true
    return 0
end
