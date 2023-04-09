#!/usr/bin/env bash

# shellcheck disable=SC2312
selected="$(
  cat "${HOME}/.config/tmux/cht.sh/languages" "${HOME}/.config/tmux/cht.sh/commands" |
    fzf
)"

read -r -p "Enter Query: " query

if grep -qs "${selected}" ~/.tmux-cht-languages; then
  query="$(echo "${query}" | tr ' ' '+')"
  tmux neww bash -c "curl cht.sh/${selected}/${query} & while [ : ]; do sleep 1; done"
else
  tmux neww bash -c "curl cht.sh/${selected}~${query} & while [ : ]; do sleep 1; done"
fi
