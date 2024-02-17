#!/bin/env fish

function bat_install_catppuccins \
    --description "Install Catppuccin themes for 🦇 | https://github.com/catppuccin/bat"

    set -l _catppuccin_bat_dir $SRC_DIR/pub/catppuccin/bat
    set -l _catppuccin_bat_git_url https://github.com/catppuccin/bat

    if not test -d "$_catppuccin_bat_dir/.git"
        if test -d $_catppuccin_bat_dir
            rm -rf $_catppuccin_bat_dir
        end

        printf_info "Cloning $catppuccin_bat_git_url"
        git clone https://github.com/catppuccin/bat.git $_catppuccin_bat_dir
    end

    printf_info "Pulling latest...\n"
    pushd $_catppuccin_bat_dir
    git pull

    set -l _bat_themes_dir "$(bat --config-dir)/themes"
    printf_info "Installing to '$_bat_themes_dir'\n"
    mkdir -p $_bat_themes_dir
    find . -name "*.tmTheme" -type f -exec cp {} "$_bat_themes_dir/" \;

    popd

    printf_info "Rebuilding 🦇 cache\n"
    bat cache --build
end
