#!/usr/bin/env zsh

#  ╭──────────────────────────────────────────────────────────╮
#  │ general                                                  │
#  ╰──────────────────────────────────────────────────────────╯
alias rm='rm -i' # make rm command (potentially) less destructive
alias sudo='nocorrect sudo' # use nocorrect alias to prevent auto correct from "fixing" these
alias nosleep='systemd-inhibit --what=handle-lid-switch sleep 2592000' # disable systemd sleep

alias grep='grep  --color=auto --exclude-dir={.git}'
## global alias, can be piped to, e.g. $ ls -l G foo
alias -g G='| grep -i'
alias watch='watch --color'
if [[ $(command -v bat) ]]; then
  alias cat='bat'
fi

[[ $(command -v zoxide) ]] && alias cd=z

if [[ $(command -v xdg-open) ]]; then
  alias open="xdg-open"
fi
[[ $(alias o) ]] || alias o=open
alias oo='open .' # open current directory in OS X Finder

# history Exclusion - prevent commands from being saved to history
alias exit=" exit"
alias history=" history"


if [[ $HAS_OP -eq true ]]; then
  [[ $(command -v aqua) ]] && alias aqua='op run -- aqua'
  [[ $HAS_GH -eq true ]]      && alias gh="op plugin run -- gh"
fi

if [[ $(command -v aws-vault) ]]; then
  alias avl="aws-vault login"
  alias ave="aws-vault exec"
fi

#  ╭──────────────────────────────────────────────────────────╮
#  │ editor                                                   │
#  ╰──────────────────────────────────────────────────────────╯
if [[ $(command -v nvim) ]]; then
  alias 'vim'='nvim'
fi
alias v='vim'
alias vi='vim'

# alias code to codium if installed
if [[ ! "$(command -v code)" ]] && [[ "$(command -v codium)" ]]
then
  alias code="codium"
fi

#  ╭──────────────────────────────────────────────────────────╮
#  │ clipboard                                                │
#  ╰──────────────────────────────────────────────────────────╯
if [[ $IS_LINUX -eq true ]]; then
  alias fonts="fc-list | awk '{\$1=\"\"}1' | cut -d: -f1 | sort| uniq" # list installed fonts
  alias setclip="xclip -selection c"
  alias sclip=setclip
  alias getclip="xclip -selection c -o"
  alias gclip=getclip
fi

#  ╭──────────────────────────────────────────────────────────╮
#  │ cd                                                       │
#  ╰──────────────────────────────────────────────────────────╯
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

[[ ! $(command -v dots) ]] && alias dots="cd ${DOTS}"

#  ╭──────────────────────────────────────────────────────────╮
#  │ dir info                                                 │
#  ╰──────────────────────────────────────────────────────────╯
alias lsd="ls -ld *" # show directories
# these require zsh
alias ltd='ls *(m0)' # files & directories modified in last day
alias lt='ls *(.m0)' # files (no directories) modified in last day
alias lnew='ls *(.om[1,3])' # list three newest
alias drs='dirs -v' # list recent directories - use ~ to select

# if ls is using exa, ignore setting ls functions
if [[ ! $(which ls | grep exa) ]]; then
  if [[ $IS_MAC -eq true ]]; then
    alias lh='ls -d .*'          # show hidden files/directories only
    alias lsd='ls -aFhl'
    alias l='ls -al'
    alias ls='ls -Fh'            # Colorize output, add file type indicator, and put sizes in human readable format
    alias ll='ls -Fhl'           # Same as above, but in long listing format
  fi
  if [[ $IS_LINUX -eq true ]]; then
    alias lh='ls -d .* --color'  # show hidden files/directories only
    alias lsd='ls -aFhl --color'
    alias l='ls -al --color'
    alias ls='ls --color'        # Colorize output
    alias ll='ls -Fhl --color'   # Colorize output, add file type indicator, and put sizes in human readable format and long listing format
  fi
fi

[[ ! $(command -v tree ) ]] && \
  alias tree="ls -R | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/'"

#  ╭──────────────────────────────────────────────────────────╮
#  │ git                                                      │
#  ╰──────────────────────────────────────────────────────────╯
[[ $(alias g) ]] || alias g='git'

# if not using forgit plugin w/ zplug
[[ $(alias ga) ]] || alias ga='git add'  && alias ga.='git add'
[[ $(alias gd) ]] || alias gd='git diff' && alias gdi='git diff'
[[ $(alias gref) ]] || alias gref=gitref

alias gaa='git add .'
alias gaaa='git add --all'
alias gau='git add --update'
alias gb='git branch'
alias gbd='git branch --delete '
alias gbr='git branch --sort=-committerdate | fzf --header "checkout recent branch" --preview "git -c color.ui=always diff {1}" --pointer "" | xargs git checkout'
alias gc='git checkout'
alias gcb='git checkout -b'
alias gcl='git clone'
alias gcm='git commit'
alias gda='git diff HEAD'
alias gdb='git diff master..`git rev-parse --abbrev-ref HEAD`'
alias gf='git reflog'
alias ghpr="GH_FORCE_TTY=100% gh pr list | fzf --ansi --preview 'GH_FORCE_TTY=100% gh pr view {1}' --preview-window down --header-lines 3 | awk '{print $1}'"
alias ginit='git init'
alias gitref='git rev-parse --short HEAD && git rev-parse HEAD'
alias gl='git log'
alias glg='git log --graph --oneline --decorate --all'
alias gm='git commit -m'
alias gma='git commit -am'
alias gmn='git commit -n -m'
alias gp='git push'
alias gpl="git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gpu='git pull'
alias gr='git rebase'
alias gra='git remote add'
alias grf='git checkout --'
alias grhard='git reset HEAD --hard'
alias grr='git remote rm'
alias grs='git restore'
alias grsh='git reset --soft HEAD~'
alias gs='git-status'
alias gst='git stash'
alias gsta='git stash apply'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash save'
alias gsw='git switch'
alias gta='git tag -a -m'
alias gu="git shortlog | grep -E '^[^ ]'" # list contibutors
alias gv='git log --pretty=format:'%s' | cut -d " " -f 1 | sort | uniq -c | sort -nr'
alias gwtls='git worktree list'
alias gwtrm='git worktree remove'
alias tasks='git grep -EI "TODO|FIXME"'

[[ $(command -v lazygit) ]] && alias lg='lazygit'

# leverage aliases from ~/.gitconfig
[[ $(which gh) ]] && alias ghist='git hist' || alias gh='git hist'
[[ $(command -v gt) ]] || alias gt='git today'

#  ╭──────────────────────────────────────────────────────────╮
#  │ kubectl                                                  │
#  ╰──────────────────────────────────────────────────────────╯
if [[ $(command -v kubectl) ]]; then
  alias k="kubectl"
  alias kctl=kubectl
  alias ketall="kubectl get-all"
  alias kubectx="kubectl ctx"
  alias kubens="kubectl ns"
fi

#  ╭──────────────────────────────────────────────────────────╮
#  │ tmux                                                     │
#  ╰──────────────────────────────────────────────────────────╯
alias tmux='tmux -u'
alias tm='tmux attach || tmux'
alias takeover="tmux detach -a"
alias attach="tmux attach -t base || tmux new -s base"
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tls='tmux ls'
alias tk='tmux kill-session -t'
[[ $(command -v tmuxinator) ]] && alias mux=tmuxinator

#  ╭──────────────────────────────────────────────────────────╮
#  │ zellij                                                   │
#  ╰──────────────────────────────────────────────────────────╯
[[ $(command -v zellij) ]] && [[ ! $(command -v zj) ]] && alias zj=zellij

#  ╭──────────────────────────────────────────────────────────╮
#  │ vagrant                                                  │
#  ╰──────────────────────────────────────────────────────────╯
if [[ $(command -v vagrant) ]]; then
  alias vs='vagrant ssh'
  alias vst='vagrant status'
  alias vu='vagrant up'
  alias vp='vagrant provision'
  alias vh='vagrant halt'
  alias vr='vagrant reload'
  alias vd='vagrant destroy'
fi

#  ╭───────────────────────────────────────────────────────────────────────────────────╮
#  │ nmap - some useful nmap aliases for scan modes                                    │
#  │   source: https://github.com/robbyrussell/oh-my-zsh/blob/master/plugins/nmap/nmap.plugin.zsh│
#  │                                                                                   │
#  │  Nmap options are:                                                                │
#  │   -sS - TCP SYN scan                                                              │
#  │   -v - verbose                                                                    │
#  │   -T1 - timing of scan. Options are paranoid (0), sneaky (1), polite (2),         │
#  │  normal (3), aggressive (4), and insane (5)                                       │
#  │   -sF - FIN scan (can sneak through non-stateful firewalls)                       │
#  │   -PE - ICMP echo discovery probe                                                 │
#  │   -PP - timestamp discovery probe                                                 │
#  │   -PY - SCTP init ping                                                            │
#  │   -g - use given number as source port                                            │
#  │   -A - enable OS detection, version detection, script scanning, and               │
#  │  traceroute (aggressive)                                                          │
#  │   -O - enable OS detection                                                        │
#  │   -sA - TCP ACK scan                                                              │
#  │   -F - fast scan                                                                  │
#  │   --script=vuln - also access vulnerabilities in target                           │
#  ╰───────────────────────────────────────────────────────────────────────────────────╯
alias nmap_open_ports="nmap --open"
alias nmap_list_interfaces="nmap --iflist"
alias nmap_slow="sudo nmap -sS -v -T1"
alias nmap_fin="sudo nmap -sF -v"
alias nmap_full="sudo nmap -sS -T4 -PE -PP -PS80,443 -PY -g 53 -A -p1-65535 -v"
alias nmap_check_for_firewall="sudo nmap -sA -p1-65535 -v -T4"
alias nmap_ping_through_firewall="nmap -PS -PA"
alias nmap_fast="nmap -F -T5 --version-light --top-ports 300"
alias nmap_detect_versions="sudo nmap -sV -p1-65535 -O --osscan-guess -T4 -Pn"
alias nmap_check_for_vulns="nmap --script=vuln"
alias nmap_full_udp="sudo nmap -sS -sU -T4 -A -v -PE -PS22,25,80 -PA21,23,80,443,3389 "
alias nmap_traceroute="sudo nmap -sP -PE -PS22,25,80 -PA21,23,80,3389 -PU -PO --traceroute "
alias nmap_full_with_scripts="sudo nmap -sS -sU -T4 -A -v -PE -PP -PS21,22,23,25,80,113,31339 -PA80,113,443,10042 -PO --script all "
alias nmap_web_safe_osscan="sudo nmap -p 80,443 -O -v --osscan-guess --fuzzy "

#  ╭──────────────────────────────────────────────────────────╮
#  │ random                                                   │
#  ╰──────────────────────────────────────────────────────────╯
alias makepass="openssl rand -base64 12"
alias tf='terraform'
alias tfc='rm -rf .terraform'
alias tfver='terraform version'
alias tfv='terraform validate'
alias vf='fd --type f --hidden --exclude .git | fzf-tmux -p --reverse | xargs nvim'
# mage
if [[ $(command -v mage) ]]; then
  [[ $(command -v mg) ]] || alias mg=mage
  [[ $(command -v mgt) ]] || alias mgt='mage go:test'
fi
# rg
[[ $(command -v rg) ]] && alias todos="rg 'TODO|FIXME'"
# tldr
[[ $(command -v tldr) ]] && \
  alias tldrf='tldr --list | fzf --preview "tldr {1} --color=always" --preview-window=right,70% | xargs tldr'

#  ╭─────────────────────────────────────────────────────────────╮
#  │ random fun                                                  │
#  │ http://aur.archlinux.org/packages/lolbash/lolbash/lolbash.sh│
#  ╰─────────────────────────────────────────────────────────────╯
alias please='sudo !!'
alias adventure='emacs -batch -l dunnet' # play adventure in the console
alias wtf='dmesg'
alias onoz='cat /var/log/errors.log'
alias rtfm='man'
alias visible='echo'
alias invisible='cat'
alias moar='more'
alias icanhas='mkdir'
alias donotwant='rm'
alias dowant='cp'
alias gtfo='mv'
alias hai='cd'
alias plz='pwd'
alias inur='locate'
alias nomz='ps aux | less'
alias nomnom='killall'
alias cya='reboot'
alias kthxbai='halt'

#  ╭──────────────────────────────────────────────────────────╮
#  │ linux                                                    │
#  ╰──────────────────────────────────────────────────────────╯
if [[ $IS_LINUX -eq true ]]; then
  if [[ $(command -v dbus-send) ]]; then
    alias lockscreen='dbus-send --type=method_call --dest=org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver.Lock'
  fi
fi

#  ╭──────────────────────────────────────────────────────────╮
#  │ mac                                                      │
#  ╰──────────────────────────────────────────────────────────╯
if [[ $IS_MAC -eq true ]]; then
  alias brewupdate='brew update; brew upgrade; brew cleanup; brew doctor'
  alias brewrefresh='brew outdated | while read cask; do brew upgrade $cask; done'
  alias ql='qlmanage -p 2>/dev/null' # OS X Quick Look
  alias today='calendar -A 0 -f /usr/share/calendar/calendar.mark | sort'
  alias smart='diskutil info disk0 | grep SMART' # display SMART status of hard drive
  alias wifi="networksetup -setairportpower en0"
fi
