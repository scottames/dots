#!/bin/env fish

function help_fzf_fish --description "Prints brief summary for fzf.fish"
  printf_info "https://github.com/PatrickF1/fzf.fish\n\n"

  printf_white_bold "Directories\n"
  printf            "-----------\n"
  printf            "--> ctrl + alt + f\n\n"

  printf_white_bold "Git Log\n"
  printf            "-----------\n"
  printf            "--> ctrl + alt + l\n\n"

  printf_white_bold "Git Status\n"
  printf            "-----------\n"
  printf            "--> ctrl + alt + s\n\n"

  printf_white_bold "History\n"
  printf            "-----------\n"
  printf            "--> ctrl + r\n\n"

  printf_white_bold "Processes\n"
  printf            "-----------\n"
  printf            "--> ctrl + alt + p\n\n"

  printf_white_bold "Variables (env)\n"
  printf            "-----------\n"
  printf            "--> ctrl + v\n"
end
