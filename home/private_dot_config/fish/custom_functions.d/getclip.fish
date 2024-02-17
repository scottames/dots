#!/bin/env fish

function getclip --wraps xclip
    set -l loginctl
    set -l paste

    if $IS_LINUX
        set -l dbe
        set -l ls (login_session)

        if is_container >/dev/null
            set dbe distrobox-host-exec
        end

        if [ $ls = wayland ]
            set paste wl-paste
        else if [ $ls = x11 ]
            set paste "xclip -selection c -o"
        else
            echo "No clipboard handler found."
        end

    else if $IS_MAC
        set paste pbpaste
    else
        echo "Only Linux & Mac supported."
    end

    eval $dbe $paste $argv
end
