#!/bin/env fish

if test -f "$HOME/.gnupg/gpg-agent.conf"
  and [ $IS_LINUX ]
    set -e SSH_AGENT_PID
    set -e SSH_AUTH_SOCK
    # Ensure that GPG Agent is used as the SSH agent
    set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
    if [ $DISTRO = "arch" ]
      set -x GPG_TTY (tty)
      # Refresh gpg-agent tty in case user switches into an X session
      gpg-connect-agent updatestartuptty /bye >/dev/null
    end
end
