#!/bin/env fish

function setclip --description "Set to clipboard"
  if $IS_LINUX
    set -l login_session_type (loginctl show-session (loginctl | grep (whoami) | awk '{print $1}') -p Type)
    set -l login_session (string split = $login_session_type)[2]

    if [ $login_session = "wayland" ]
      wl-copy $argv
    else if [ $login_session = "x11" ]
      xclip -selection c $argv
    else
      echo "No clipboard handler found."
    end
  else if $IS_MAC
    pbcopy $argv
  else
      echo "Only Linux & Mac supported."
  end
end
