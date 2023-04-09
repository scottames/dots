#!/usr/bin/env zsh

# zplug - manage itself
zplug 'zplug/zplug', hook-build:'zplug --self-manage'

case "${DISTRO}" in
  "arch")
    zplug "plugins/archlinux", from:'oh-my-zsh', if:"[[ "${DISTRO}" == "arch" ]]"
    ;;
esac

# oh-my-zsh
## libs
zplug "lib/completion",   from:'oh-my-zsh'
zplug "lib/directories",  from:'oh-my-zsh'
zplug "lib/history",      from:'oh-my-zsh'
zplug "lib/key-bindings", from:'oh-my-zsh'
zplug "lib/termsupport",  from:'oh-my-zsh'
zplug "plugins/docker", from:'oh-my-zsh', if:"[[ $commands[docker] ]]"
zplug "plugins/docker-compose", from:'oh-my-zsh', if:"[[ $commands[docker-compose] ]]"
zplug "plugins/extract", from:'oh-my-zsh'
zplug "plugins/fzf", from:'oh-my-zsh'
zplug "plugins/terraform", from:'oh-my-zsh'

if [[ -f "${HOME}/.asdf/asdf.sh" ]]; then
  zplug "plugins/asdf", from:'oh-my-zsh'
  fpath=(${HOME}/.asdf/completions ${fpath})
else
  print_warn "asdf not found!"
fi

# zplug "plugins/magic-enter", from:'oh-my-zsh'
# play with oh-my-zsh themes | `theme <theme_name>` (random w/o) --> `lstheme` to list all
zplug "plugins/themes", from:'oh-my-zsh'

# zsh-users
## defer:2 means syntax-highlighting gets loaded after completions
zplug "zsh-users/zsh-syntax-highlighting", defer:2
## defer:3 means history-substring search gets loaded after syntax-highlighting
zplug 'zsh-users/zsh-history-substring-search', defer:3
zplug 'zsh-users/zsh-autosuggestions'
zplug 'zsh-users/zsh-completions', depth:1 # more completions

zplug "jeffreytse/zsh-vi-mode"
function zvm_config() {
  ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
  ZVM_VI_INSERT_ESCAPE_BINDKEY=kj
}

# git
## forgit is a utility tool for git taking advantage of fuzzy finder fzf
zplug 'wfxr/forgit'
## Quickly navigate to GitHub from the command line.
zplug 'peterhurford/git-it-on.zsh', use:'git-it-on.plugin.zsh'

if [[ ! $(command -v zoxide) ]]; then
  ## disable filtering on .. + home
  ENHANCD_DISABLE_DOT=1
  ENHANCD_DISABLE_HOME=1
  # A next-generation cd command with an interactive filter :sparkles: | https://github.com/b4b4r07/enhancd
  zplug "b4b4r07/enhancd", use:'init.sh'
fi

# improve the output of ls | made better when exa is installed https://github.com/ogham/exa
zplug "zpm-zsh/ls", use:'ls.plugin.zsh'

# Terminal/tmux titles based on current location and task
zplug "jreese/zsh-titles", use:'titles.plugin.zsh'

# Replace zsh's default completion selection menu with fzf!
zplug 'Aloxaf/fzf-tab', use:'fzf-tab.zsh'

if [[ -n "${TMUX}" ]] && [[ "${DISTRO}" == "arch" ]]; then # tmux version >= 3.2 required
  zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
fi

# auto-close quotes and brackets like a pro
zplug 'hlissner/zsh-autopair', defer:2

# eye candy
zplug 'zdharma-continuum/fast-syntax-highlighting', defer:2, hook-load:'FAST_HIGHLIGHT=()'
zplug 'chrissicool/zsh-256color'

# there's an alias for that!
zplug "MichaelAquilina/zsh-you-should-use"
