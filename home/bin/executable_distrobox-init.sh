#!/bin/env bash

# Override distrobox's default as to handle the situations where
# the variables may not be set correctly
if [[ -e "/etc/fish/config.fish" ]]; then
	cat <<EOF >/etc/fish/conf.d/distrobox_config.fish
test -z "${USER}" && set -gx USER (id -un 2> /dev/null)
test -z "${UID}"  && set -gx UID (id -ur 2> /dev/null)
test -z "${EUID}" && set -gx EUID (id -u  2> /dev/null)
set -gx SHELL (getent passwd "${USER}" | cut -f 7 -d :)

# Ensure we have these variables from the host, so that graphical apps
# also work in case we use a login session
if not set -q DISPLAY
    set -gx DISPLAY (host-spawn sh -c "printf '%s' \$DISPLAY")
    not set -q DISPLAY or test -z ${DISPLAY}; and set -e DISPLAY
end
if not set -q XAUTHORITY
    set -gx XAUTHORITY (host-spawn sh -c "printf '%s' \$XAUTHORITY")
    # if the variable is still empty, unset it, because empty it could be harmful
    not set -q XAUTHORITY or test -z ${XAUTHORITY}; and set -e XAUTHORITY
end
if not set -q XAUTHLOCALHOSTNAME
    set -gx XAUTHLOCALHOSTNAME (host-spawn sh -c "printf '%s' \$XAUTHLOCALHOSTNAME")
    not set -q XAUTHLOCALHOSTNAME or test -z ${XAUTHLOCALHOSTNAME}; and set -e XAUTHLOCALHOSTNAME
end

# This will ensure we have a first-shell password setup for an user if needed.
# We're going to use this later in case of rootful containers
if test -e /var/tmp/.${USER}.passwd.initialize
    echo "⚠️  First time user password setup ⚠️ "
    trap "echo; exit" INT
    passwd && rm -f /var/tmp/.${USER}.passwd.initialize
    trap - INT
end
EOF
fi
# vi: ft=bash
