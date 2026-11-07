#!/usr/bin/env bash

set -euo pipefail

# Keep shell startup files from replacing the stub PATH in child Bash processes.
unset BASH_ENV ENV

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="${repo_root}/home/dot_local/bin/executable_theme-set"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

export HOME="${tmpdir}/home"
export TEST_APP_LOG="${tmpdir}/app.log"
mkdir -p "${HOME}/.config/themes/aura" "${HOME}/.config/themes/catppuccin-mocha" "${tmpdir}/bin"
export PATH="${tmpdir}/bin:${PATH}"

# Never send signals or reload the real desktop from this test.
for cmd in pkill herdr tmux makoctl vicinae; do
	printf '#!/bin/sh\nexit 0\n' >"${tmpdir}/bin/${cmd}"
	chmod +x "${tmpdir}/bin/${cmd}"
done
cat >"${tmpdir}/bin/herdr-app" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"${TEST_APP_LOG}"
exit "${TEST_APP_EXIT:-0}"
EOF
chmod +x "${tmpdir}/bin/herdr-app"

printf '{"background":"#15141b"}\n' >"${HOME}/.config/themes/aura/herdr-app.json"
printf '{"background":"#1e1e2e"}\n' >"${HOME}/.config/themes/catppuccin-mocha/herdr-app.json"
target="${HOME}/.config/herdr-app/themes/current.json"

bash "${script}" aura >/dev/null
[[ -L ${target} ]]
[[ $(readlink "${target}") == "${HOME}/.config/themes/current/herdr-app.json" ]]
cmp "${target}" "${HOME}/.config/themes/aura/herdr-app.json"
grep -Fx 'do app.theme --name current' "${TEST_APP_LOG}" >/dev/null

bash "${script}" catppuccin-mocha >/dev/null
cmp "${target}" "${HOME}/.config/themes/catppuccin-mocha/herdr-app.json"

# A closed app must not make theme switching fail.
TEST_APP_EXIT=1 bash "${script}" aura >/dev/null
cmp "${target}" "${HOME}/.config/themes/aura/herdr-app.json"

# Preserve the existing missing-fragment behavior for older theme directories.
mkdir -p "${HOME}/.config/themes/without-app"
bash "${script}" without-app >/dev/null
[[ -L ${target} ]]

printf 'PASS: theme link, palette switching, closed app, and missing fragment\n'
