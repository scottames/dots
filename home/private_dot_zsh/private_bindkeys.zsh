#!/usr/bin/env zsh

# To see the key combo you want to use just do:
# cat > /dev/null
# And press it

# if not using a plugin via zplug set some sane defaults
if [[ ! $HAS_ZPLUG ]]; then
  bindkey "^K"      kill-whole-line                      # ctrl-k
  bindkey "^R"      history-incremental-search-backward  # ctrl-r
  bindkey '^S'      history-incremental-search-forward   # ctrl-s
  bindkey "^A"      beginning-of-line                    # ctrl-a
  bindkey "^E"      end-of-line                          # ctrl-e
  bindkey "[B"      history-search-forward               # down arrow
  bindkey "[A"      history-search-backward              # up arrow
  bindkey "^D"      delete-char                          # ctrl-ds
  bindkey "^F"      forward-char                         # ctrl-f
  bindkey "^B"      backward-char                        # ctrl-b
  # bindkey -v   # Default to standard vi bindings, regardless of editor string

  # default additions...
  bindkey '^W' vi-backward-kill-word
  # set del key to act like a del key...
  bindkey    "^[[3~"          delete-char
  bindkey    "^[3;5~"         delete-char

  # make search up and down work, so partially type and hit up/down to find relevant stuff
  bindkey '^[[A' up-line-or-search
  bindkey '^[[B' down-line-or-search
fi

if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
fi
