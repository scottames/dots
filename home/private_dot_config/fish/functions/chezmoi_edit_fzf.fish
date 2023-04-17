#!/bin/env fish

function chezmoi_edit_fzf \
  --description "Edit dotfile tracked by chezmoi w/ fzf query" \
  --wraps "chezmoi edit"

  set -l fzf_command "fzf"
  if test (count $argv) -ge 1
    set fzf_command $fzf_command "--query=$argv[1]" "-1"
  end

  set file_path (chezmoi managed --include=files | $fzf_command)

  if test -z "$file_path"
    printf_warn "No file selected\n"
    return 1
  else
    echo chezmoi edit --apply "$HOME/$file_path"
  end
end

