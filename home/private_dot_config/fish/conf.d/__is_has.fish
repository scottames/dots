set UNAME (uname)

set -g IS_LINUX false
set -g IS_MAC false

set -l _cat (which cat) # avoid race condition with cat.fish being used before HAS_BAT set

if [ $UNAME = "Linux" ]
  set -g IS_LINUX true

    if [ ($_cat /proc/version | grep arch) ]
      set -g DISTRO "arch"
    else if [ ($_cat /proc/version | grep Ubuntu) ]
      set -g DISTRO "ubuntu"
    end
else if [ $UNAME = "Darwin" ]
  set -g IS_MAC true
end

set has_bins \
  apt        \
  aqua       \
  aws-vault  \
  bat        \
  brew       \
  bob        \
  cargo      \
  exa        \
  fd         \
  direnv     \
  dyff       \
  git        \
  gh         \
  go         \
  hub        \
  kubectl    \
  mage       \
  nvim       \
  op         \
  paru       \
  rustup     \
  tldr       \
  vagrant    \
  vim        \
  virtualenv \
  xclip      \
  yum        \
  zoxide

for bin in $has_bins
  set _upper_bin (string upper $bin | string replace "-" "")

  type -q $bin \
    && set -gx "HAS_$_upper_bin" true \
    || set -gx "HAS_$_upper_bin" false
end
