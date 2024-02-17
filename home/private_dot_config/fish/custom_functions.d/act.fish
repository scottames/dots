#!/bin/env fish

function act \
    --description "Run your GitHub Actions locally 🚀 | but w/ podman" \
    --wraps act

    if $HAS_PODMAN
        command act --container-daemon-socket \
            unix:////run/user/$(id -u (whoami))/podman/podman.sock \
            $argv
    else
        command act $argv
    end
end
