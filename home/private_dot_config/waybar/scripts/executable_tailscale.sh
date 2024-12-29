#!/usr/bin/env bash

if tailscale status &>/dev/null; then
  if tailscale exit-node list | grep -q selected; then
    tooltip=$(tailscale exit-node list | grep selected | awk '{print $2" "$3}')
    echo "{\"text\": \" \", \"class\": \"enabled\", \"tooltip\": \"${tooltip}\"}"
  else
    tooltip="No exit-node assigned"
    echo "{\"text\": \" \", \"class\": \"disabled\", \"tooltip\": \"${tooltip}\"}"
  fi
else
  tooltip="Tailscale is not connected"
  echo "{\"text\": \" \", \"class\": \"disabled\", \"tooltip\": \"${tooltip}\"}"
fi
