#!/bin/env fish

function is_distrobox \
    --description "Returns whether the existing shell is running in a distrobox container"

    if is_container >/dev/null
        and test "$DISTROBOX_ENTER_PATH" != ""

        printf true
        return 0
    end

    printf false
    return 1
end
