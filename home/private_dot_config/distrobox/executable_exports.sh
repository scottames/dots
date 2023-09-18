#!/bin/bash

CONTAINERS=(at)

# shellcheck disable=SC2034
APPS_AT=()
# shellcheck disable=SC2034
BIN_AT=(aws zenity)

for container in "${CONTAINERS[@]}"; do
  declare -n APPS_ARR=APPS_${container^^}
  if [[ -n ${!APPS_ARR} ]]; then
    echo "=> Exporting apps for '${container}'"
    echo "==> Cleaning old exports '${container}'"
    for application in "${APPS_ARR[@]}"; do distrobox-enter -n "${container}" -- distrobox-export --app "${application}" -d; done
    echo "==> Adding new exports '${container}'"
    for application in "${APPS_ARR[@]}"; do distrobox-enter -n "${container}" -- distrobox-export --app "${application}"; done
  fi

  declare -n BIN_ARR=BIN_${container^^}
  if [[ -n ${!BIN_ARR} ]]; then
    echo "=> Exporting bins for '${container}'"
    echo "==> Cleaning old exports '${container}'"
    for binary in "${BIN_ARR[@]}"; do distrobox-enter -n "${container}" -- distrobox-export --bin /usr/bin/"${binary}" --export-path ~/.local/bin -d; done
    echo "==> Adding new exports '${container}'"
    for binary in "${BIN_ARR[@]}"; do distrobox-enter -n "${container}" -- distrobox-export --bin /usr/bin/"${binary}" --export-path ~/.local/bin; done
  fi
done

# source: https://github.com/john-ghatas/silverblue-setup/blob/master/podman-images/export-applications.sh
