#!/bin/env fish

# prompt to launch into distrobox container on shell start
#   if not launched from inside container
if status --is-login
    and not is_container >/dev/null
    and not $IS_MAC

    if type -q gum
        and type -q distrobox-host-exec

        set -l box (
          begin
            distrobox ls --no-color | grep -v Exited | tail -n +2 | tr -s ' ' | cut -d '|' -f 2,4 | string trim | sort
            echo "none | default shell"
          end | gum filter --timeout=10s --header="distrobox?" --placeholder="" \
              | cut -d '|' -f 1 | string trim
        )

        if test -n "$box"
            and test "$box" != none
            distrobox enter $box
        end
    else
        if not type -q gum
            printf "\n$WARNING missing gum\n"
        else if not type -q distrobox-host-exec
            printf "\n$WARNING missing distrobox-host-exec\n"
        end
    end
end
