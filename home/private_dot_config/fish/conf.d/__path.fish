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

set -a _bin_dirs \
    $AQUA_ROOT_DIR \
    $AQUA_ROOT_DIR/bin \
    $BOB_BIN \
    $HOME/.npm-global/bin \
    $KREW_ROOT/bin \
    $HOME/.cargo/bin \
    $HOME/.gobrew/current/bin \
    $HOME/.gobrew/bin \
    $GOPATH/bin \
    $HOME/.local/bin \
    $HOME/bin \
    $HOME/src/bin

for dir in $_bin_dirs
    if test -d $dir
        fish_add_path -m $dir
    end
end
