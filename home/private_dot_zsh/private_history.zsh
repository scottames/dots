#!/usr/bin/env zsh
# history
export HISTSIZE=10000
export SAVEHIST=9000
export HISTFILE=~/.zsh_history
export HISTFILESIZE=$HISTSIZE;
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help";

# if not using a plugin via zplug set some sane defaults
if [[ ! $HAS_ZPLUG ]]; then
  # better history management, using partial term and arrow keys
  # https://coderwall.com/p/jpj_6q
  autoload -U up-line-or-beginning-search
  autoload -U down-line-or-beginning-search
  zle -N up-line-or-beginning-search
  zle -N down-line-or-beginning-search
fi
