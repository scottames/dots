if [[ -f ~/.gnupg/gpg-agent.conf ]]; then
  if [[ $IS_LINUX ]]; then
    unset SSH_AGENT_PID
    if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
      export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    fi
    if [[ $DISTRO == "arch" ]]; then
      # Set GPG TTY
      export GPG_TTY=$(tty)
      # Refresh gpg-agent tty in case user switches into an X session
      gpg-connect-agent updatestartuptty /bye >/dev/null
    fi
  fi
fi
