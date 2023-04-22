#!/bin/env fish

function lock_screen --wraps dbus-send --description "Lock Screen (Gnome)"
  if type -q dbus-send
    dbus-send \
      --type=method_call \
      --dest=org.gnome.ScreenSaver \
      /org/gnome/ScreenSaver org.gnome.ScreenSaver.Lock
  else
    printf_err "No suitable system call found\n"
    return 1
  end
end
