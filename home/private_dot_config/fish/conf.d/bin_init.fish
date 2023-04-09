#!/bin/env fish

# ╭──────────────────────────────────────────────────────────╮
# │ cht.sh                                                   │
# ╰──────────────────────────────────────────────────────────╯
function _chtsh_install
  curl -fsSL -o "$HOME/.local/bin/cht.sh" https://cht.sh/:cht.sh
  chmod +x "$HOME/.local/bin/cht.sh"
end

if not type -q cht.sh
  if _read_confirm -m "'cht.sh' not found. Install? [y/n]"
    _chtsh_install
  end
end

# ╭──────────────────────────────────────────────────────────╮
# │ direnv                                                   │
# ╰──────────────────────────────────────────────────────────╯
if [ $HAS_DIRENV ]
  direnv hook fish | source
end

# ╭──────────────────────────────────────────────────────────╮
# │ pyenv                                                    │
# ╰──────────────────────────────────────────────────────────╯
function _pyenv_install --description "Install pyenv"
  if ! test -d $PYENV_ROOT
    print_info "pyenv root not found $ARROW_RIGHT installing$ELLIPSIS\n"

    if [ $HAS_GIT ]
      git clone https://github.com/pyenv/pyenv.git \
        $HOME/.pyenv
      git clone https://github.com/pyenv/pyenv-virtualenv.git \
        $PYENV_ROOT/plugins/pyenv-virtualenv
    else
      printf_err "Missing package: git$ELLIPSIS"
    end
    printf_warn "** reload of shell required**"
  else if ! type -q pyenv
    and type -d $PYENV_ROOT

    printf_err "pyenv not found, but dir '$PYENV_ROOT' found\n"
  end
end

if not type -q pyenv
  if _read_confirm -m "'pyenv' not found. Install? [y/n]"
    _pyenv_install
  end
end

if test -d $PYENV_ROOT
  pyenv init - | source
  if test -d $PYENV_ROOT/plugins/pyenv-virtualenv
    pyenv virtualenv-init - | source
  end
end

# ╭──────────────────────────────────────────────────────────╮
# │ trunk                                                    │
# │  .. because trunk's installer is way too opinionated     │
# ╰──────────────────────────────────────────────────────────╯
function _trunk_install
  set -l _trunk_bin "$HOME_LOCAL_BIN/trunk"

  if test -d $HOME_LOCAL_BIN
    mkdir -p $HOME_LOCAL_BIN
  end
  curl -fsSL "https://trunk.io/releases/trunk" -o $_trunk_bin

  chmod +x $_trunk_bin
end

if not type -q trunk
  if _read_confirm -m "'trunk' not found. Install? [y/n]"
    _trunk_install
  end
end

# ╭──────────────────────────────────────────────────────────╮
# │ zoxide                                                   │
# │   https://github.com/ajeetdsouza/zoxide                  │
# ╰──────────────────────────────────────────────────────────╯
if $HAS_ZOXIDE
  zoxide init fish | source
end
