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

fix_npm_permissions
