#!/bin/env fish

function setclip --description "Set to clipboard"
  set -l loginctl
  set -l copy

  if $IS_LINUX
    set -l dbe
    set -l ls (login_session)

    if is_container > /dev/null
      set dbe "distrobox-host-exec"
    end

    if [ $ls = "wayland" ]
      set copy "wl-copy"
    else if [ $ls = "x11" ]
      set copy "xclip -selection c"
    else
      echo "No clipboard handler found."
    end

  else if $IS_MAC
    set copy "pbcopy"
  else
      echo "Only Linux & Mac supported."
  end

  eval $dbe $copy $argv
end
