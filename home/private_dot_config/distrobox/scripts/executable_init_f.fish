#!/usr/bin/env fish

function print_info
    printf "\nℹ  INFO: %s\n\n" $argv
end

function print_warn
    printf "\n⚠ WARN: %s\n\n" $argv
end

function fix_npm_permissions
    sudo chown -R $USER:$USER "$HOME/.npm"
    sudo chown -R $USER:$USER "$HOME/.npm-global/"
end

set -l host_exec_commands \
    docker \
    flatpak \
    hostnamectl \
    loginctl \
    niri \
    nmcli \
    op \
    podman \
    reboot \
    rpm-ostree \
    systemctl \
    transactional-update \
    ugum \
    ujust \
    ydotool \
    xclip \
    xdg-open

function create_host_exec_symlinks
    for cmd in $argv
        ln -sf /usr/bin/distrobox-host-exec /usr/local/bin/$cmd
    end
end

create_host_exec_symlinks $host_exec_commands

fix_npm_permissions
