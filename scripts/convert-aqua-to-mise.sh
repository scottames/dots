#!/usr/bin/env bash

# Convert aqua.yaml tools to mise use commands
# This script extracts package information from aqua.yaml and generates mise use commands

set -euo pipefail

# Read aqua.yaml and extract package information
echo "# Generated mise use commands from aqua.yaml"
echo "# Run these commands to install the same tools with mise:"
echo ""

# Parse the YAML file more carefully
awk '
/^packages:/ {in_packages=1; next}
in_packages && /^[^ ]/ {in_packages=0}
in_packages && /^\s*-\s*name:/ {
    # Extract the package name
    gsub(/^\s*-\s*name:\s*/, "")
    package = $0
    
    # Check if package has @version format
    if (package ~ /@/) {
        split(package, parts, "@")
        tool = parts[1]
        gsub(/.*\//, "", tool)  # Remove repo path, keep only tool name
        version = parts[2]
        print "mise use " tool "@" version
    } else {
        # No version specified, use latest
        tool = package
        gsub(/.*\//, "", tool)  # Remove repo path, keep only tool name
        print "mise use " tool "@latest"
    }
}
' aqua/aqua.yaml

echo ""
echo "# Note: Some tools may need manual verification of tool names in mise"
echo "# Run 'mise ls-remote <tool>' to see available versions"
echo "# Some GitHub repo names might map differently in mise registries"
