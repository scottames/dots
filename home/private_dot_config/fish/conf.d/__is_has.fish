set UNAME (uname)

set -g IS_LINUX false
set -g IS_MAC false

set -l _cat (which cat) # avoid race condition with cat.fish being used before HAS_BAT set

if [ $UNAME = Linux ]
    set -g IS_LINUX true

    if [ ($_cat /proc/version | grep arch) ]
        set -g DISTRO arch
    else if [ ($_cat /proc/version | grep Ubuntu) ]
        set -g DISTRO ubuntu
    else
        set -g DISTRO unknown
    end
else if [ $UNAME = Darwin ]
    set -g IS_MAC true
end

set -gx IS_LIGHT false
set -gx IS_DARK false
set -l h (date +%k)
if is_light >/dev/null
    set -gx IS_LIGHT true
else
    set -gx IS_DARK true
end

set has_bins \
    apt \
    aqua \
    aws-vault \
    bat \
    brew \
    bob \
    cargo \
    distrobox \
    distrobox-host-exec \
    eza \
    fd \
    fish \
    fzf \
    direnv \
    dyff \
    git \
    gh \
    gcloud \
    ghtkn \
    go \
    gobrew \
    gt \
    gum \
    hub \
    kubectl \
    nvim \
    op \
    podman \
    paru \
    rustup \
    tldr \
    ugum \
    vagrant \
    vim \
    virtualenv \
    xclip \
    yum \
    zoxide

for bin in $has_bins
    set _upper_bin (string upper $bin | string replace -a "-" "")

    type -q $bin \
        && set -gx "HAS_$_upper_bin" true \
        || set -gx "HAS_$_upper_bin" false
end
