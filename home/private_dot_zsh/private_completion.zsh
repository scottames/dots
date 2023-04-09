#!/usr/bin/env zsh
# completions

# if not using a plugin via zplug set some sane defaults
if [[ ! $HAS_ZPLUG ]]; then

  # Add path to completions
  fpath=(${HOME}/.zsh/zsh-completions/src $fpath)
  # Load the [zsh/complist Module](http://zsh.sourceforge.net/Doc/Release/Zsh-Modules.html#The-zsh_002fcomplist-Module)
  zmodload -i zsh/complist
  # Enable the famous zsh tab-completion system
  autoload -U compinit && compinit
  # may have to force rebuild zcompdump:
  if [[ -f ${HOME}/.zcompdump ]]; then
    rm -f ${HOME}/.zcompdump
    compinit
  fi

  # man zshcontrib
  zstyle ':vcs_info:*' actionformats '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{3}|%F{1}%a%F{5}]%f '
  zstyle ':vcs_info:*' formats '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{5}]%f '
  zstyle ':vcs_info:*' enable git #svn cvs

  # Enable completion caching, use rehash to clear
  zstyle ':completion::complete:*' use-cache on
  zstyle ':completion::complete:*' cache-path ~/.zsh/cache/$HOST

  # Fallback to built in ls colors
  zstyle ':completion:*' list-colors ''

  # Make the list prompt friendly
  zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more, or the character to insert%s'

  # Make the selection prompt friendly when there are a lot of choices
  zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'

  # Add simple colors to kill
  zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

  # list of completers to use
  zstyle ':completion:*::::' completer _expand _complete _ignored _approximate

  zstyle ':completion:*' menu select=1 _complete _ignored _approximate

  # insert all expansions for expand completer
  # zstyle ':completion:*:expand:*' tag-order all-expansions

  # match uppercase from lowercase
  zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

  # offer indexes before parameters in subscripts
  zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

  # formatting and messages
  zstyle ':completion:*' verbose yes
  zstyle ':completion:*:descriptions' format '%B%d%b'
  zstyle ':completion:*:messages' format '%d'
  zstyle ':completion:*:warnings' format 'No matches for: %d'
  zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
  zstyle ':completion:*' group-name ''

  # ignore completion functions (until the _ignored completer)
  zstyle ':completion:*:functions' ignored-patterns '_*'
  zstyle ':completion:*:scp:*' tag-order files users 'hosts:-host hosts:-domain:domain hosts:-ipaddr"IP\ Address *'
  zstyle ':completion:*:scp:*' group-order files all-files users hosts-domain hosts-host hosts-ipaddr
  zstyle ':completion:*:ssh:*' tag-order users 'hosts:-host hosts:-domain:domain hosts:-ipaddr"IP\ Address *'
  zstyle ':completion:*:ssh:*' group-order hosts-domain hosts-host users hosts-ipaddr
  zstyle '*' single-ignored show
fi

# shellcheck disable=SC1090
[[ $(command -v aqua) ]] && source <(aqua completion zsh)
# aws completion
if [[ -f /usr/local/share/zsh/site-functions/_aws ]]; then
  source /usr/local/share/zsh/site-functions/_aws
elif [[ -f /usr/bin/aws_zsh_completer.sh ]]; then
  source /usr/bin/aws_zsh_completer.sh
elif [[ -f /usr/bin/aws_completer ]]; then
  complete -C '/usr/bin/aws_completer' aws
elif [[ -f /usr/local/bin/aws_completer ]]; then
  complete -C '/usr/local/bin/aws_completer' aws
fi

if [[ -f /usr/share/doc/git-extras/git-extras-completion.zsh ]]; then
  source /usr/share/doc/git-extras/git-extras-completion.zsh
fi

# fzf completion
if [[ -f /usr/share/fzf/completion.zsh ]]; then
  source /usr/share/fzf/completion.zsh
fi

# google cloud sdk / gcloud
if [[ -f /opt/google-cloud-sdk/completion.zsh.inc ]]; then
  source /opt/google-cloud-sdk/completion.zsh.inc
fi

# terraform completion
[[ $(command -v terraform) ]] && complete -o nospace -C $(which terraform) terraform

# https://manicli.com/
[[ $(command -v mani) ]] && eval "$(mani completion zsh)"

[[ $(command -v aqua) ]]&& source <(aqua completion zsh)

# gt (graphite)
if [[ $(command -v gt) ]]; then
  _gt_yargs_completions()
  {
    local reply
    local si=$IFS
    IFS=$'
    ' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" gt --get-yargs-completions "${words[@]}"))
    IFS=$si
    _describe 'values' reply
  }
  compdef _gt_yargs_completions gt
fi
