#!/usr/bin/env bash

# Install all tools from aqua.yaml using mise
# Generated from aqua.yaml configuration

set -euo pipefail

echo "Installing tools with mise..."

# Extract and execute mise use commands
./convert-aqua-to-mise.sh | grep "^mise use" | while read -r cmd; do
  echo "Executing: $cmd"
  if ! eval "$cmd"; then
    tool=$(echo "$cmd" | cut -d' ' -f3 | cut -d'@' -f1)
    echo "Warning: Failed to install $tool - may need manual verification"
    echo "Try running: mise ls-remote $tool"
  fi
done

echo "Done! Run 'mise list' to see installed tools"
