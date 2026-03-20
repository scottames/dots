#!/bin/env fish

if test -f "$HOME/.gnupg/gpg-agent.conf"
    and status --is-interactive
    and type -q gpgconf

    set -e SSH_AGENT_PID
    set -l gpg_ssh_sock (gpgconf --list-dirs agent-ssh-socket)
    set -l is_remote false

    if set -q SSH_CONNECTION; or set -q SSH_CLIENT; or set -q SSH_TTY
        set is_remote true
    end

    printf_debug "SSH_AUTH_SOCK before: $SSH_AUTH_SOCK\n" >&2
    printf_debug "Is socket test: $(test -S "$SSH_AUTH_SOCK"; and echo "exists"; or echo "missing")\n" >&2
    printf_debug "GPG socket: $gpg_ssh_sock\n" >&2

    if test "$is_remote" = true; and set -q SSH_AUTH_SOCK; and test -S "$SSH_AUTH_SOCK"
        printf_debug "Keeping forwarded SSH_AUTH_SOCK\n" >&2
    else if test "$SSH_AUTH_SOCK" != "$gpg_ssh_sock"
        printf_debug "Using GPG agent socket\n" >&2
        set -x SSH_AUTH_SOCK "$gpg_ssh_sock"
    else
        printf_debug "SSH_AUTH_SOCK already using GPG socket\n" >&2
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
