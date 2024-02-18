#!/bin/env fish

function is_container \
    --description "Returns whether the existing shell is running in a container"

    if test -f /run/.dockerenv
        or test -f /run/.containerenv

        printf true
        return 0
    end

    printf false
    return 1
end
