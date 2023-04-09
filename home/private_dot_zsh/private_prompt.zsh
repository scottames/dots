#!/usr/bin/env bash
# Prompt

# bright blue:  039
# bright green: 154
# bright red:   197
# dull red:     052
# orange:       202
# white:        231
## color chart: https://upload.wikimedia.org/wikipedia/commons/1/15/Xterm_256color_chart.svg

# if not using zplug, setup the prompt natively... :D
if "${HAS_ZPLUG}"; then
  setopt prompt_subst
  autoload -U promptinit
  promptinit
fi

PROMPT="starship"
# shellcheck disable=SC2312
if [[ ${PROMPT} == "starship" ]] &&
  [[ -n $(command -v starship) ]]; then

  eval "$(starship init zsh)"

elif [[ ${PROMPT} == "powerline" ]] &&
  [[ -f /usr/share/powerline/bindings/zsh/powerline.zsh ]] &&
  [[ -n $(command -v powerline-daemon) ]]; then
  # shellcheck disable=SC1091
  . /usr/share/powerline/bindings/zsh/powerline.zsh

  # use pure prompt if installed & wanted | https://github.com/sindresorhus/pure
elif [[ ${PROMPT} == "pure" ]] &&
  [[ -f /usr/share/zsh/functions/Prompts/prompt_pure_setup ]] &&
  [[ -f /usr/share/zsh/functions/Prompts/async ]]; then

  if ! ${HAS_ZPLUG}; then
    prompt pure
  else
    zplug "mafredri/zsh-async", from:github, defer:0 # Async for zsh, required by pure
    zplug "sindresorhus/pure", use:pure.zsh, from:github, as:theme
  fi

  # change up the colors
  zstyle ':prompt:pure:path' color 9
  zstyle ':prompt:pure:prompt:success' color 15
  zstyle ':prompt:pure:prompt:error' color 8

  # options: https://github.com/sindresorhus/pure#options

elif [[ ${PROMPT} == "spaceship" ]] &&
  [[ -f /usr/local/share/zsh/site-functions/prompt_spaceship_setup ]]; then

  if ! ${HAS_ZPLUG}; then
    prompt spaceship
  fi

  # options: https://github.com/denysdovhan/spaceship-prompt/blob/master/docs/Options.md
  export SPACESHIP_PROMPT_ADD_NEWLINE=false
  export SPACESHIP_CHAR_COLOR_SUCCESS=197
  export SPACESHIP_DIR_COLOR=039
  export SPACESHIP_GIT_BRANCH_COLOR=154

  export SPACESHIP_PROMPT_PREFIXES_SHOW=false
  # export SPACESHIP_PROMPT_SUFFIXES_SHOW=false
  export SPACESHIP_VI_MODE_SHOW=false

  # otherwise, use our own
else
  # inspiration: https://www.reddit.com/r/commandline/comments/1do8cb/alright_echo_your_ps1s_lets_see_your_colourful/

  # prompt circle char | http://stevelosh.com/blog/2010/02/my-extravagant-zsh-prompt/
  function prompt_char {
    git branch >/dev/null 2>/dev/null && echo '❯' && return
    echo '❯'
  }

  # Git Prompt
  function git_prompt_info() {
    ref=$(git symbolic-ref HEAD 2>/dev/null) || return
    # shellcheck disable=SC1087,SC2250
    echo "%{$FG[202]%}${ref#refs/heads/}%{$reset_color%}"
  }

  # shellcheck disable=SC1087,SC2250
  return_code="%(?..%{$FG[196]%}%? ↵%{$reset_color%})"

  # shellcheck disable=SC1087,SC2250,SC2016
  user_host='%{$FG[039]%}%n$FG[231]%}.$FG[197]%}%m%{$reset_color%}'
  # shellcheck disable=SC1087,SC2250,SC2016
  current_dir='%{$FG[154]%}%~%{$reset_color%}'

  # shellcheck disable=SC2016
  git_branch='$(git_prompt_info)%{$reset_color%}'

  # shellcheck disable=SC1087,SC2250,SC2016
  export RPROMPT="[%{$FG[154]%}%T%{$reset_color%}] ${return_code}%{$reset_color%}"
  # shellcheck disable=SC1087,SC2250,SC2016,SC2155
  export PROMPT="${user_host} ${current_dir} ${git_branch}
  %B%b%{$FG[197]%}$(prompt_char)%{$reset_color%} "

  export ZSH_THEME_GIT_PROMPT_SUFFIX=""
fi
