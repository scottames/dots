#!/usr/bin/env zsh

# -------------------------------------------------------------------
# helpers
# -------------------------------------------------------------------
function one-arg-req() {
  if [[ $# -ne 1 ]]; then
    print_err "Exactly one argument required. Got: $# ($@)"
    return 1
  fi
}

function two-args-req() {
  if [[ $# -ne 2 ]]; then
    print_err "Exactly two arguments required. Got: $# ($@)"
    return 1
  fi
}

function gt-one-arg-req() {
  if [[ $# -lt 1 ]]; then
    print_err "At least one argument required."
    return 1
  fi
}

function add_to_known_hosts() {
  host=${1}
  fingerprint=${2}

  ip=$(getent hosts ${1} | awk '{ print $1 }')
  keys=$(ssh-keyscan -t rsa ${host} ${ip})

  # Iterate over keys (host and ip)
  while IFS= read -r key; do
    # Extract Host name (or IP)
    key_host=$(echo ${key} | awk '{ print $1 }')

    # Extracting fingerprint of key
    key_fingerprint=$(echo ${key} | ssh-keygen -lf - | awk '{ print $2 }')

    # Check that fingerprint matches one provided as second parameter
    if [[ "${fingerprint}" != "${key_fingerprint}" ]]; then
      print_err "Fingerprint match failed: '${fingerprint}' (expected) != '${key_fingerprint}' (got)";
      return 1;
    fi

    # Add key to known_hosts if it doesn't exist
    if [[ ! $(grep "${key_host}" ~/.ssh/known_hosts > /dev/null) ]]
    then
      print_info "Adding fingerprint ${key_fingerprint} for ${key_host} to ~/.ssh/known_hosts"
      echo ${key} >> ~/.ssh/known_hosts
    fi
  done <<< "${keys}"
}

# verbose alias printing
function preexec(){ [ $1 != $2 ] && print -r -- "${POINTER} ${fg[white]}${2}${reset_color}" }


function sh_startup_time() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do /usr/bin/time ${shell} -i -c exit; done
}
# -------------------------------------------------------------------
# add_github_to_known_hosts
#
# -------------------------------------------------------------------
function add_github_to_known_hosts() {
  # https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
  add_to_known_hosts "github.com" "SHA256:nThbg6kXUpJWGl7E1IGOCspRomTxdCARLviKw6E5SY8"
}
# -------------------------------------------------------------------
# any
# search for running processes
#  - source: from http://onethingwell.org/post/14669173541/any
# -------------------------------------------------------------------
function any() {
  one-arg-req "${@}" || return 1

  emulate -L zsh
  unsetopt KSH_ARRAYS

  ps xauwww | grep -i --color=auto "[${1[1]}]${1[2,-1]}"
}
# -------------------------------------------------------------------
# e
#   edit file in a new multiplexer pane using the default $EDITOR
#     closes the pane when done
# -------------------------------------------------------------------
function e() {
  if [[ -v ZELLIJ ]]; then
    zellij edit "${@}"
  elif [[ TMUX ]]; then
    tmux split-window "${EDITOR} ${@}"
  fi
}

# -------------------------------------------------------------------
# ex
#   compressed file expander
#    - source: https://github.com/myfreeweb/zshuery/blob/master/zshuery.sh
# -------------------------------------------------------------------
if [[ $(command -v extract) ]]; then
  alias ex=extract
else
  ex() {
    if [[ -f $1 ]]; then
      case $1 in
        *.tar.bz2) tar xvjf $1 ;;
        *.tar.gz) tar xvzf $1 ;;
        *.tar.xz) tar xvJf $1 ;;
        *.tar.lzma) tar --lzma xvf $1 ;;
        *.bz2) bunzip $1 ;;
        *.rar) unrar $1 ;;
        *.gz) gunzip $1 ;;
        *.tar) tar xvf $1 ;;
        *.tbz2) tar xvjf $1 ;;
        *.tgz) tar xvzf $1 ;;
        *.zip) unzip $1 ;;
        *.Z) uncompress $1 ;;
        *.7z) 7z x $1 ;;
        *.dmg) hdiutul mount $1 ;; # mount OS X disk images
        *) echo "'$1' cannot be extracted via >ex<" ;;
      esac
    else
      echo "'$1' is not a valid file"
    fi
  }
fi
# -------------------------------------------------------------------
# def
#   shell function to define words
#   http://vikros.tumblr.com/post/23750050330/cute-little-function-time
# -------------------------------------------------------------------
function def() {
  one-arg-req ${@} || return 1

  curl -Ss "dict://dict.org/d:${1}" | $PAGER
}
# -------------------------------------------------------------------
# find-exec
#   search aliases/functions
# -------------------------------------------------------------------
falias() {
  CMD="$(
    (
      (alias)
      (functions | grep "()" | cut -d ' ' -f1 | grep -v "^_" )
    ) | fzf | cut -d '=' -f1
  )";

  eval "${CMD}"
}
# -------------------------------------------------------------------
# find-exec
#   find files and exec commands at them.
#   $ find-exec .coffee cat | wc -l
#   # => 9762
#    - source: https://github.com/paulmillr/dotfiles
# -------------------------------------------------------------------
function find-exec() {
  find . -type f -iname "*${1:-}*" -exec "${2:-file}" '{}' \;
}
# -------------------------------------------------------------------
# glc
#   git clone & cd
# -------------------------------------------------------------------
function git_clone_cd {
  url="${1}";
  reponame=$(echo $url | awk -F/ '{print $NF}' | sed -e 's/.git$//');
  git clone "${url}" "${reponame}" && cd "${reponame}";
}
alias gcld=git_clone_cd
# -------------------------------------------------------------------
#   git-status - opinionated to also include git worktree info
# -------------------------------------------------------------------
function git-status {
  local _is_inside_git_repo="$(git rev-parse --is-inside-work-tree 2>/dev/null)"
  if [[ "${_is_inside_git_repo}" ]]; then
    printf "\n🌳\n\n" \
      && git worktree list \
      && printf "\n🛠 $(pwd | string replace ${HOME}/ '')\n\n" \
      && git status
  fi

  git status
}
# -------------------------------------------------------------------
# git-clone-for-worktrees
#   https://morgan.cugerone.com/blog/workarounds-to-git-worktree-using-bare-repository-and-cannot-fetch-remote-branches/
# -------------------------------------------------------------------
function git_clone_for_worktrees {
  # Examples of call:
  # git-clone-bare-for-worktrees git@github.com:name/repo.git
  # => Clones to a /repo directory
  #
  # git-clone-bare-for-worktrees git@github.com:name/repo.git my-repo
  # => Clones to a /my-repo directory

  url="${1}"
  basename="${url##*/}"
  name="${2:-${basename%.*}}"

  mkdir -p "${name}"
  cd "${name}"

  # Moves all the administrative git files (a.k.a $GIT_DIR) under .bare directory.
  #
  # Plan is to create worktrees as siblings of this directory.
  # Example targeted structure:
  # .bare
  # main
  # new-awesome-feature
  # hotfix-bug-12
  # ...
  git clone --bare "${url}" .bare
  echo "gitdir: ./.bare" > .git

  # Explicitly sets the remote origin fetch so we can fetch remote branches
  git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

  # Gets all branches from origin
  git fetch origin
}
# -------------------------------------------------------------------
# gcbo
#   git checkout branch from origin without typing origin/
# -------------------------------------------------------------------
function gcbo {
  git checkout -t origin/${1}
}
# -------------------------------------------------------------------
# gcbwd
#   git checkout new branch w/ initials + date appended to the name
# -------------------------------------------------------------------
function gcbwd {
  one-arg-req "${@}" || return 1
  branch_name="sa-$(date "+%Y-%m-%d")-${1}"
  gcb ${branch_name}
}
# -------------------------------------------------------------------
# gwtawd
#   an opinionated git worktree add based on current project
# -------------------------------------------------------------------
function gwta {
  one-arg-req "${@}" || return 1

  _proj="$(basename `git rev-parse --show-toplevel`)"

  git worktree add "../${_proj}-${1}" -b "${1}"
}
# -------------------------------------------------------------------
# git-prune
#   prune local branches that do not exist in remote
# -------------------------------------------------------------------
function git_prune {
  git remote prune origin
  git branch -vv | grep 'origin/.*: gone]' | awk '{print $1}' | xargs git branch -D
}
# -------------------------------------------------------------------
# git_update
#   pull & rebase with base branch (1) default: head branch
# -------------------------------------------------------------------
function git_update {
  _head_branch="$(git_head_branch)"

  if [[ $# > 0 ]]; then
    _branch="${1}"
  else
    _branch="${_head_branch}"
  fi

  git checkout "${_branch}" \
    && git pull \
    && git checkout - \
    && git rebase "${_branch}"
}
# -------------------------------------------------------------------
# git_head_branch
#   returns the head branch
# -------------------------------------------------------------------
function git_head_branch() {
  git remote show origin | grep "HEAD branch" | cut -d ":" -f 2 | xargs
}
# -------------------------------------------------------------------
# gcln
#   checkout the default branch, pull & prune
# -------------------------------------------------------------------
function gcln() {
  if [[ $# > 0 ]]; then
    _branch="${1}"
  else
    _branch="$(git_head_branch)"
  fi

  git checkout "${_branch}" && git pull && git-prune
}
# -------------------------------------------------------------------
# gpo
#   push upstream w/ origin of current branch name (used when origin branch does not exist)
# -------------------------------------------------------------------
function gpo() {
  git push --set-upstream origin $(git branch | grep \* | cut -d ' ' -f2)
}
# -------------------------------------------------------------------
# fzpr
#   view PR w/ fzf
# -------------------------------------------------------------------
function fzpr() {
  GH_FORCE_TTY=100% \
    op run -- gh pr list \
    | fzf --ansi --preview 'GH_FORCE_TTY=100% op run -- gh pr view {1}' \
    --preview-window down --header-lines 3 \
    | awk '{print $1}'
}
# -------------------------------------------------------------------
# loc
#   count code lines in some directory.
#   $ loc py js css
#   # => Lines of code for .py: 3781
#   # => Lines of code for .js: 3354
#   # => Lines of code for .css: 2970
#   # => Total lines of code: 10105
#    - source: https://github.com/paulmillr/dotfiles
# -------------------------------------------------------------------
function loc() {
  local total
  local firstletter
  local ext
  local lines
  total=0
  for ext in $@; do
    firstletter=$(echo $ext | cut -c1-1)
    if [[ firstletter != "." ]]; then
      ext=".$ext"
    fi
    lines=`find-exec "*$ext" cat | wc -l`
    lines=${lines// /}
    total=$(($total + $lines))
    echo "Lines of code for ${fg[blue]}$ext${reset_color}: ${fg[green]}$lines${reset_color}"
  done
  echo "${fg[blue]}Total${reset_color} lines of code: ${fg[green]}$total${reset_color}"
}
# -------------------------------------------------------------------
# magef
#  fzf mage execution
# -------------------------------------------------------------------
magef() {
  if [[ ! -f "mage.go" ]] && [[ ! -f "magefile.go" ]]; then
    print_err "no magefile in pwd"
    return 1
  fi

  if [ $# -eq 0 ]; then
    # sed strips color characters (if enabled)
    mage | tail -n +2 | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | fzf | while read -r cmd _; do if [ "$cmd" ]; then mage "$cmd"; fi; done
  else
    mage "${1:-.}"
  fi
}
# -------------------------------------------------------------------
#  kubectl_cheatsheet
# -------------------------------------------------------------------
function kubectl_cheatsheet() {
  [[ $(command -v glow) ]] || ( print_err "missing glow (https://github.com/charmbracelet/glow)" && return 1 )

  local kubectl_cheatsheet_url='https://raw.githubusercontent.com/kubernetes/website/main/content/en/docs/reference/kubectl/cheatsheet.md'
  glow -p "${kubectl_cheatsheet_url}"
}

# -------------------------------------------------------------------
# man
#  colorize man pages
#    - source: https://github.com/robbyrussell/oh-my-zsh/blob/master/plugins/colored-man-pages/colored-man-pages.plugin.zsh
# -------------------------------------------------------------------
if ! [[ $HAS_BAT -eq true ]]
then

  function man_colored() {
    env \
      LESS_TERMCAP_mb=$(printf "\e[1;31m") \
      LESS_TERMCAP_md=$(printf "\e[1;31m") \
      LESS_TERMCAP_me=$(printf "\e[0m") \
      LESS_TERMCAP_se=$(printf "\e[0m") \
      LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
      LESS_TERMCAP_ue=$(printf "\e[0m") \
      LESS_TERMCAP_us=$(printf "\e[1;32m") \
      PAGER="${commands[less]:-$PAGER}" \
      _NROFF_U=1 \
      PATH="$HOME/bin:$PATH" \
      "${@}"
  }
  function man() {
    man_colored man "${@}"
  }

fi
# -------------------------------------------------------------------
# nicemount
#   nice mount (http://catonmat.net/blog/another-ten-one-liners-from-commandlingfu-explained)
#   displays mounted drive information in a nicely formatted manner
# -------------------------------------------------------------------
function nicemount() {
  (echo "DEVICE PATH TYPE FLAGS" && mount | awk '$2="";1') | column -t
}

# op
function op_signin() {
  [[ ! $(command -v op) ]] && print_err "op not found" && return 1
  [[ -n "${1}"          ]] && OP_TEAM="${1}"

  eval $(op signin --account "${OP_TEAM:-my}.1password.com")
}

# -------------------------------------------------------------------
# path
#   display a neatly formatted path
# -------------------------------------------------------------------
function path() {
  echo "${PATH}" | tr ":" "\n" | \
    awk "{
      sub(\"$HOME\",  \"$fg_no_bold[green]$HOME$reset_color\"); \
      sub(\"/usr\",   \"$fg_no_bold[green]/usr$reset_color\"); \
      sub(\"/bin\",   \"$fg_no_bold[blue]/bin$reset_color\"); \
      sub(\"/opt\",   \"$fg_no_bold[cyan]/opt$reset_color\"); \
      sub(\"/sbin\",  \"$fg_no_bold[magenta]/sbin$reset_color\"); \
      sub(\"/local\", \"$fg_no_bold[yellow]/local$reset_color\"); \
      sub(\"/.rvm\",  \"$fg_no_bold[red]/.rvm$reset_color\"); \
    print }"
}
# -------------------------------------------------------------------
# fpath
#   display a neatly formatted fpath
# -------------------------------------------------------------------
fpath() {
  echo "${fpath}" | tr " " "\n" | \
    awk "{ sub(\"/usr\",   \"$fg_no_bold[green]/usr$reset_color\"); \
            sub(\"/bin\",   \"$fg_no_bold[blue]/bin$reset_color\"); \
            sub(\"/opt\",   \"$fg_no_bold[cyan]/opt$reset_color\"); \
            sub(\"/sbin\",  \"$fg_no_bold[magenta]/sbin$reset_color\"); \
            sub(\"/local\", \"$fg_no_bold[yellow]/local$reset_color\"); \
            sub(\"/.rvm\",  \"$fg_no_bold[red]/.rvm$reset_color\"); \
    print }"
}
# -------------------------------------------------------------------
# pyenv-pip-upgrade - upgrade pip versions for all pyenv versions of python
# -------------------------------------------------------------------
function pyenv-pip-upgrade() {
  for VERSION in $(pyenv versions --bare) ; do
    pyenv shell ${VERSION} ;
    pip install --upgrade pip ;
  done
}
function pip-list-outdated() {
  print_info "pip outdated packages"
  pip list --outdated
}
function pip-list-outdated-user() {
  print_info "pip outdated user packages"
  pip list --outdated --user
}
function pip-upgrade() {
  pip-list-outdated
  pip list --outdated | tail +3 | cut -d ' ' -f 1 | xargs -n1 pip install -U
}
function pip-upgrade-user() {
  pip-list-outdated-user
  pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip install -U
}
# --------------------------------------------------------------------
# psax
#   ps with a grep
# --------------------------------------------------------------------
function psax() {
  ps auxwwwh | grep "$@" | grep -v grep
}
# --------------------------------------------------------------------
# pushds
#   pushd silently
# --------------------------------------------------------------------
pushds () {
  pushd "${@}" > /dev/null
}
# --------------------------------------------------------------------
# popds
#   popd silently
# --------------------------------------------------------------------
popds () {
  popd "${@}" > /dev/null
}
# -------------------------------------------------------------------
# ram
#   show how much RAM application uses
#   $ ram safari
#   # => safari uses 154.69 MBs of RAM.
#    - source: https://github.com/paulmillr/dotfiles
# -------------------------------------------------------------------
function ram() {
  one-arg-req "${@}" || return 1

  local sum
  local items
  local app="$1"
  sum=0
  for i in `ps aux | grep -i "$app" | grep -v "grep" | awk '{print $6}'`; do
    sum=$(($i + $sum))
  done
  sum=$(echo "scale=2; $sum / 1024.0" | bc)
  if [[ $sum != "0" ]]; then
    echo "${fg[blue]}${app}${reset_color} uses ${fg[green]}${sum}${reset_color} MBs of RAM."
  else
    echo "There are no processes with pattern '${fg[blue]}${app}${reset_color}' are running."
  fi
}
# --------------------------------------------------------------------
# rvim
#  edit file using vim remotely using scp
# --------------------------------------------------------------------
rvim () {
  if [ $# -lt 2 ]  # Must have 2 command-line args to run
  then
    print_err "Please invoke with one or more command-line arguments.
    usage: rvim /path/to/file SERVER USER"
    return 1
  fi
  rvim_file="${1}"
  rvim_server="${2}"
  rvim_user="${3:-$(whoami)}"
  vim "scp://${rvim_user}@${rvim_server}/${rvim_file}"
}
# -------------------------------------------------------------------
# (s)ave
# (i)nsert a directory.
# -------------------------------------------------------------------
s() { pwd > ~/.save_dir ; }
i() { cd "$(cat ~/.save_dir)" ; }
# --------------------------------------------------------------------
# shrug
#   shrug emoji to clipboard
#   https://twitter.com/climagic/status/672862397015658496
#    try: curl http://www.climagic.org/txt/unicodeicons.txt
# --------------------------------------------------------------------
shrug () {
  printf "${SHRUG}" | (xclip -selection c || pbcopy) && print_info "${SHRUG} copied to your clipboard"
}
# --------------------------------------------------------------------
# up
#   Preserve fingers from cd ..; cd ..; cd..; cd..;
# --------------------------------------------------------------------
up(){ DEEP=$1; [ -z "${DEEP}" ] && { DEEP=1; }; for i in $(seq 1 ${DEEP}); do cd ../; done; }
# --------------------------------------------------------------------
# vgo
#  vagrant up & vagrant ssh into specified machine
# --------------------------------------------------------------------
vgo () {
  vagrant up $1 && vagrant ssh $1
}
# --------------------------------------------------------------------
# aws_s3_rm_versioned_bucket
#  purge and remove a versioned bucket
# --------------------------------------------------------------------
aws_s3_rm_versioned_bucket () {
  echo '#!/bin/bash' > /tmp/deleteBucketScript.sh
  aws --output text s3api list-object-versions \
    --bucket "${1}" \
    | grep -E "^VERSIONS" \
    | awk '{print "aws s3api delete-object --bucket "${1}" --key "$4" --version-id "$8";"}' >> /tmp/deleteBucketScript.sh && \
    chmod +x /tmp/deleteBucketScript.sh
  ./tmp/deleteBucketScript.sh
  rm -f /tmp/deleteBucketScript.sh
  echo '#!/bin/bash' > /tmp/deleteBucketScript.sh

  aws --output text s3api list-object-versions --bucket "${1}" | grep -E "^DELETEMARKERS" | grep -v "null" | awk '{print "aws s3api delete-object --bucket "${1}" --key "$3" --version-id "$5";"}' >> /tmp/deleteBucketScript.sh && \
    chmod +x /tmp/deleteBucketScript.sh
  ./tmp/deleteBucketScript.sh
  rm -f /tmp/deleteBucketScript.sh
}
# --------------------------------------------------------------------
# aws_s3_purge
#  purge all buckets in an AWS account
# --------------------------------------------------------------------
aws_s3_purge() {
  aws s3 ls

  while true; do
    read -p "Continue with purge of the above buckets? (y/n)" yn
    case $yn in
      [Yy]* ) echo "Purging buckets..."; break ;;
      [Nn]* ) echo "Aborting!"; return ;;
      * ) echo "Please answer yes or no." ;;
    esac
  done

  aws s3 ls | awk '{print "s3://"$3}' | xargs -n 1 -P 5 aws s3 rm --recursive
}

# -------------------------------------------------------------------
# tf_rm
#   purge terraform cache
# -------------------------------------------------------------------
function tf_rm {
  find . \( -iname ".terraform*"  ! -iname ".terraform-version" ! -iname ".terraform-docs*" \)  -print0 | xargs -0 rm -r; true
}
# -------------------------------------------------------------------
# CLean local Neovim files for reset
# -------------------------------------------------------------------
function nvim_clean_local() {
  rm -rf ~/.local/share/nvim
  rm -rf ~/.local/state/nvim
  rm -rf ~/.cache/nvim
  rm -rf ~/.local/share/nvim/site/pack/packer/start/packer.nvim
  rm -rf ~/.local/share/nvim/lazy/lazy.nvim
  rm -rf ~/.local/share/nvim/lazy/nvim-treesitter
  rm -rf ~/.local/share/nvim/mason
}
# -------------------------------------------------------------------
# Zellij
# -------------------------------------------------------------------
function zellij_attach() {
  ZJ_SESSIONS=$(zellij list-sessions)
  NO_SESSIONS=$(echo "${ZJ_SESSIONS}" | wc -l)

  if [ "${NO_SESSIONS}" -ge 2 ]; then
    zellij attach \
      "$(echo "${ZJ_SESSIONS}" | fzf)" # alternatively use sk
  else
    zellij attach -c
  fi
}
alias zja=zellij_attach

# /begin mac specific functions

if [[ $IS_MAC -eq true ]]; then
  # -------------------------------------------------------------------
  # pman
  #   view man pages in Preview
  # -------------------------------------------------------------------
  pman() {
    ps=`mktemp -t manpageXXXX`.ps
    man -t $@ > "$ps"
    open "$ps"
  }
  # -------------------------------------------------------------------
  # notify
  #   notify function
  #     - http://hints.macworld.com/article.php?story=20120831112030251
  # -------------------------------------------------------------------
  notify() {
    automator -D title=$1 -D subtitle=$2 -D message=$3 ~/Library/Workflows/DisplayNotification.wflow
  }
  # -------------------------------------------------------------------
  # rmount
  #   remote mount (sshfs)
  #     creates mount folder and mounts the remote filesystem
  # -------------------------------------------------------------------
  rmount() {
    local host folder mname
    host="${1%%:*}:"
    [[ ${1%:} == ${host%%:*} ]] && folder='' || folder=${1##*:}
    if [[ -n $2 ]]; then
      mname=$2
    else
      mname=${folder##*/}
      [[ "$mname" == "" ]] && mname=${host%%:*}
    fi
    if [[ $(grep -i "host ${host%%:*}" ~/.ssh/config) != '' ]]; then
      mkdir -p ~/mounts/$mname > /dev/null
      sshfs $host$folder ~/mounts/$mname -oauto_cache,reconnect,defer_permissions,negative_vncache,volname=$mname,noappledouble && echo "mounted ~/mounts/$mname"
    else
      print_warn "No entry found for ${host%%:*}"
      return 1
    fi
  }
  # -------------------------------------------------------------------
  # rumount
  #   remote umount, unmounts and deletes local folder (experimental, watch you step)
  # -------------------------------------------------------------------
  rumount() {
    if [[ $1 == "-a" ]]; then
      ls -1 ~/mounts/|while read dir
      do
        [[ -d $(mount|grep "mounts/$dir") ]] && umount ~/mounts/$dir
        [[ -d $(ls ~/mounts/$dir) ]] || rm -rf ~/mounts/$dir
      done
    else
      [[ -d $(mount|grep "mounts/$1") ]] && umount ~/mounts/$1
      [[ -d $(ls ~/mounts/$1) ]] || rm -rf ~/mounts/$1
    fi
  }

fi

# /end mac specific functions
