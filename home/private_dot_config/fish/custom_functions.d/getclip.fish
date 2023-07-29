#!/bin/env fish

function getclip --wraps xclip
  if $IS_LINUX
    set -l login_session_type (loginctl show-session (loginctl | grep (whoami) | awk '{print $1}') -p Type)
    set -l login_session (string split = $login_session_type)[2]

    if [ $login_session = "wayland" ]
      wl-paste $argv
    else if [ $login_session = "x11" ]
      xclip -selection c -o $argv
    else
      echo "No clipboard handler found."
    end
  else if $IS_MAC
    pbpaste
  else
      echo "Only Linux & Mac supported."
  end
end
