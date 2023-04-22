#!/bin/env fish

function kubectl_cheatsheet --description "Opens kubectl cheatsheet using glow in pager" \
  --wraps glow

  if ! type -q glow
    printf_err "missing glow (https://github.com/charmbracelet/glow)"
    return 1
  end

  glow -p \
    'https://raw.githubusercontent.com/kubernetes/website/main/content/en/docs/reference/kubectl/cheatsheet.md' \
    $argv
end
