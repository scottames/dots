#!/bin/env fish

if test -f "$HOME/.gnupg/gpg-agent.conf"
    and [ $IS_LINUX ]
    and status --is-interactive

    set -e SSH_AGENT_PID
    set -e SSH_AUTH_SOCK
    # Ensure that GPG Agent is used as the SSH agent
    set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
    set -x GPG_TTY (tty)
    if type -q gpg-connect-agent
        # Refresh gpg-agent tty
        if is_distrobox >/dev/null
            distrobox-host-exec gpg-connect-agent updatestartuptty /bye >/dev/null
        else
            gpg-connect-agent updatestartuptty /bye >/dev/null
        end
    end
end
