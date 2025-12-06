#!/bin/env fish

if test -f "$HOME/.gnupg/gpg-agent.conf"
    and [ $IS_LINUX ]
    and status --is-interactive

    set -e SSH_AGENT_PID
    printf_debug "SSH_AUTH_SOCK before: $SSH_AUTH_SOCK\n" >&2
    printf_debug "Is socket test: $(test -S "$SSH_AUTH_SOCK"; and echo "exists"; or echo "missing")\n" >&2
    printf_debug "GPG socket: $(gpgconf --list-dirs agent-ssh-socket)\n" >&2

    # Only use GPG agent as SSH agent if no forwarded socket exists
    if not set -q SSH_AUTH_SOCK; or not test -S "$SSH_AUTH_SOCK"
        printf_debug "Using GPG agent socket\n" >&2
        set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
    else
        printf_debug "Keeping existing SSH_AUTH_SOCK\n" >&2
    end

    printf_debug "SSH_AUTH_SOCK after: $SSH_AUTH_SOCK\n" >&2
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
