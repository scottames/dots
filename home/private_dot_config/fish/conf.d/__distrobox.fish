#!/bin/env fish

# prompt to launch into distrobox container on shell start
#   if not launched from inside container
if status --is-login
    and not is_container >/dev/null

    if type -q distrobox-host-exec
        and type -q fzf

        set -l box (
          begin
            distrobox ls | tail -n +2 | tr -s ' ' | cut -d '|' -f 2,4 | string trim | sort
            echo "none | shell"
          end | ugum filter --timeout=10s --header="distrobox?" --placeholder="" | cut -d '|' -f 1 | string trim
        )

        if [ "$box" != none ]
            distrobox enter $box
        end
    else
        if not type -q distrobox-host-exec
            printf_warn "missing distrobox-host-exec\n"
        else if not type -q fzf
            printf_warn "missing fzf\n"
        end
    end
end
