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

function install_npms

    if command -v npm
        set -l npm_registry_ping "https://registry.npmjs.org/-/ping?write=true"
        if ! curl --fail --silent --show-error --connect-timeout 5 $npm_registry_ping >/dev/null
            print_warn "npm ping failed. Skipping installing npm packages."
            return 0
        end
    else
        print_warn "no npm found. Skipping installing npm packages."
        return 0
    end

    function npm_install
        npm install -g $argv

    end

    set npm_packages_to_install \
        @anthropic-ai/claude-code \
        @google/gemini-cli \
        @openai/codex

    for pkg in $npm_packages_to_install
        print_info "npm install $pkg"
        npm_install $pkg
    end

end

fix_npm_permissions
install_npms
