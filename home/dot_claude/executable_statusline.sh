#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# ANSI color codes
magenta=$'\033[0;35m'
yellow=$'\033[0;33m'
reset=$'\033[0m'

# Extract values using jq
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')

# Get directory using starship
dir=$(cd "$cwd" && starship module directory)

# Check if we're in a git repo and get branch
git_info=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null || echo "detached")
  git_info=" on ${magenta}${branch}${reset}"
fi

# Calculate context window percentage
context_info=""
usage=$(echo "$input" | jq '.context_window.current_usage')
if [ "$usage" != "null" ]; then
  current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
  size=$(echo "$input" | jq '.context_window.context_window_size')
  if [ "$size" != "null" ] && [ "$size" != "0" ]; then
    pct=$((current * 100 / size))
    context_info=" | ${yellow}${pct}%${reset} ctx"
  fi
fi

# Output status line
printf "%s%s | %s%s\n" "$dir" "$git_info" "$model" "$context_info"
