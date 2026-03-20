if [[ -f ~/.gnupg/gpg-agent.conf ]]; then
  if command -v gpgconf >/dev/null 2>&1; then
    unset SSH_AGENT_PID
    gpg_ssh_sock="$(gpgconf --list-dirs agent-ssh-socket)"

    if [[ -n ${SSH_CONNECTION:-} || -n ${SSH_CLIENT:-} || -n ${SSH_TTY:-} ]]; then
      if [[ -z ${SSH_AUTH_SOCK:-} || ! -S ${SSH_AUTH_SOCK} ]]; then
        export SSH_AUTH_SOCK="${gpg_ssh_sock}"
      fi
    else
      export SSH_AUTH_SOCK="${gpg_ssh_sock}"
    fi

    export GPG_TTY=$(tty)
    if command -v gpg-connect-agent >/dev/null 2>&1; then
      gpg-connect-agent updatestartuptty /bye >/dev/null
    fi
  fi
fi
