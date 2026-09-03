function theme --description "Switch the active theme (wraps theme-set)"
    theme-set $argv
end

complete -c theme -f
complete -c theme -a "(theme-set --list 2>/dev/null)" -d Theme
complete -c theme-set -f
complete -c theme-set -a "(theme-set --list 2>/dev/null)" -d Theme
