#!/bin/env fish

function login_session \
    --description "Returns the current login session - uses distrobox-host-exec if running in distrobox."

    set -l dbe
    set -l loginctl

    if is_container >/dev/null
        set dbe distrobox-host-exec
        set loginctl $dbe loginctl
    else
        set loginctl loginctl
    end

    set -l login_session_type ($loginctl show-session ($loginctl | grep (whoami) | awk '{print $1}') -p Type)
    printf (string split = $login_session_type)[2]
end
