#!/bin/bash
# Custom file suggestion script for Claude Code
# Uses rg + fzf for fuzzy matching and symlink support
# https://x.com/callam53/status/2009898697740480868

# Parse JSON input to get query
QUERY=$(jq -r '.query // ""')

# Use project dir from env, fallback to pwd
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# cd into project dir so rg outputs relative paths
cd "$PROJECT_DIR" || exit 1

{
  # Main search - respects .gitignore, includes hidden files, follows symlinks
  rg --files --follow --hidden --no-ignore . 2>/dev/null

  # Additional paths - include even if gitignored (uncomment and customize)
  # [ -e .notes ] && rg --files --follow --hidden --no-ignore-vcs .notes 2>/dev/null
} | sort -u | fzf --filter "$QUERY" | head -15
