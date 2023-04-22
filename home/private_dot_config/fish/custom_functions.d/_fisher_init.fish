#!/bin/env fish

function _fisher_init --description "Install fisher + run fisher install on $FISH_CONFIG/fish_plugins"
  if type -q fisher
    printf_info "fisher already installed 😕\n ..installing plugins\n\n"
  else
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish \
      | source

    if not type -q fisher
      printf_err "something went wrong sourcing fisher from remote\n"
      return 1
    end
  end

  fisher install (cat $FISH_CONFIG/fish_plugins)
end
