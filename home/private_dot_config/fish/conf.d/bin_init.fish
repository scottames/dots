#!/bin/env fish

if status --is-interactive

# ╭──────────────────────────────────────────────────────────╮
# │ direnv                                                   │
# ╰──────────────────────────────────────────────────────────╯
  if $HAS_DIRENV
    direnv hook fish | source
  else
      printf_warn "direnv not found\n"
  end

# ╭──────────────────────────────────────────────────────────╮
# │ pyenv                                                    │
# ╰──────────────────────────────────────────────────────────╯
  if test -d $PYENV_ROOT
    and type -q pyenv

    pyenv init - | source
    if test -d $PYENV_ROOT/plugins/pyenv-virtualenv
      pyenv virtualenv-init - | source
    end
  else
    if status --is-interactive
      printf_warn "pyenv not found\n"
    end
  end

# ╭──────────────────────────────────────────────────────────╮
# │ zoxide                                                   │
# │   https://github.com/ajeetdsouza/zoxide                  │
# ╰──────────────────────────────────────────────────────────╯
  if $HAS_ZOXIDE
    zoxide init fish | source
  else
    if status --is-interactive
      printf_warn "zoxide not found\n"
    end
  end

end
