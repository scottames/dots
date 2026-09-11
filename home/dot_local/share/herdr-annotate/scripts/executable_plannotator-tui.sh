#!/usr/bin/env bash

set -eufo pipefail

# The review pane runs in the directory under review, not the plugin root.
root="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -x ${root}/bin/plannotator-tui.exe ]]; then
	exec "${root}/bin/plannotator-tui.exe" "$@"
fi

msg='plannotator-tui is not installed. Run chezmoi apply to provision Herdr Annotate.'
printf '%s\n' "${msg}" >&2
if [[ -n ${HERDR_BIN_PATH:-} ]]; then
	"${HERDR_BIN_PATH}" notification show 'Annotate: review pane unavailable' --body "${msg}" >/dev/null 2>&1 || true
fi
exit 1
