#!/bin/env fish

function chezmoi_add_and_unlink --description "chezmoi: add & unlink existing symlink"
  _arg_req_one $argv || return 1

  set -l _target $argv[1]
  if not test -L $_target
    printf_err "'$_target' is not a link"
    return 1
  end

  chezmoi add -f $_target && unlink $_target

  chezmoi diff
end
