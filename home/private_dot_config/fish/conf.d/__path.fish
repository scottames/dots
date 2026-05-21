function addpaths
    contains -- $argv $fish_user_paths
    or set -U fish_user_paths $fish_user_paths $argv
    echo "Updated PATH: $PATH"
end

function removepath
    if set -l index (contains -i $argv[1] $PATH)
        set --erase --universal fish_user_paths[$index]
        echo "Updated PATH: $PATH"
    else
        echo "$argv[1] not found in PATH: $PATH"
    end
end

set _bin_dirs

if $IS_MAC
    set -a _bin_dirs \
        /usr/local/bin \
        $HOME/.node/bin \
        /usr/bin \
        /bin \
        /usr/sbin \
        /sbin \
        /opt/X11/bin \
        /usr/local/MacGPG2/bin \
        /usr/local/sbin \
        /run/current-system/sw/bin \
        /usr/local/packer

else if $IS_LINUX

    set -a _bin_dirs \
        /usr/bin \
        /usr/sbin \
        /usr/local/sbin \
        /usr/local/bin \
        /var/lib/snapd/snap/bin \
        /usr/local/packer

end

set -l _mise_shims "$MISE_SHIMS_DIR"
if test -z "$_mise_shims"
    set _mise_shims "$HOME/.local/share/mise/shims"
end

set -a _bin_dirs \
    $AQUA_ROOT_DIR \
    $AQUA_ROOT_DIR/bin \
    $_mise_shims \
    $HOME/.local/bin \
    $HOME/bin \
    $HOME/src/bin \
    $HOME/.npm-global/bin \
    $HOME/.cargo/bin \
    $GOPATH/bin \
    /opt/homebrew/bin

for dir in $_bin_dirs
    if test -n "$dir"; and test -d "$dir"
        fish_add_path --path -m "$dir"
    end
end
