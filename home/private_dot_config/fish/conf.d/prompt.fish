#!/bin/env fish

if status --is-interactive

  set -g fish_greeting
  set PROMPT "starship"

  if [ "$PROMPT" = "starship" ]
    if type -q starship
      starship init fish | source
    else
      printf_warn "starship not found, but PROMPT set\n"
    end
  end

# https://github.com/zzhaolei/transient.fish
  if type -q transient_execute
    function __transient_prompt_func
      set --local color 6d6f83
      if test $transient_pipestatus[-1] -ne 0
          set color red
      end
      printf (set_color $color)"❯ "(set_color normal)
    end
  end

end
