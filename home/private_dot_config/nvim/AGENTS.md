# AGENTS.md

This file provides guidance to coding agents (opencode, claude.ai/code, etc)
when working with code in this project.

## Overview

This is a personal Neovim configuration built on
[LazyVim](https://www.lazyvim.org/) with extensive language support and custom
tooling.

## Code Formatting

```bash
# Format Lua files
stylua lua/

# Check Lua formatting
stylua --check lua/
```

Lua style: 2-space indentation, 120 character line width (see `stylua.toml`).

## Architecture

### Module Loading Flow

1. `init.lua` → requires `config.lazy`
2. `lua/config/lazy.lua` → bootstraps lazy.nvim, loads LazyVim base, imports
   `lua/plugins/`
3. Plugins lazy-load via `ft`, `event`, or `keys` conditions

### Directory Structure

- `lua/config/` - Core configuration (options, keymaps, autocmds)
- `lua/plugins/` - Plugin specifications (one concern per file)
- `lua/util/` - Helper functions (`M.map()`, `M.buf_map()`, etc.)
- `ftplugin/` - Filetype-specific settings (shell, fish, gitcommit, help)
- `lockfiles/` - Backup copies of `lazy-lock.json` (auto-maintained)

### Key Files

- `lazyvim.json` - Enables LazyVim extras (32 extras: languages, UI, coding
  tools)
- `lazy-lock.json` - Pinned plugin versions
- `lua/plugins/disabled.lua` - Explicitly disabled plugins

### Plugin Organization

Each file in `lua/plugins/` returns a table of plugin specs:

- `ai.lua` - AI assistant integrations
- `editor.lua` - Editor enhancements
- `lsp.lua` - LSP, formatters, linters
- `ui.lua` - Visual/UI plugins
- `go.lua` - Go-specific overrides
- `obsidian.lua` - Obsidian vault integration
- `snacks.lua` - Snacks plugin config

### Custom Utilities

`lua/util/init.lua` provides:

- `M.map(mode, lhs, rhs, opts)` - Keymap with noremap default
- `M.buf_map(bufnr, mode, lhs, rhs, opts)` - Buffer-local keymap
- `M.merge_table(t1, t2)` - Concatenate tables
- `M.version()` - Warns if not running Neovim nightly

## Configuration Patterns

### Adding a Plugin

Create or edit a file in `lua/plugins/`:

```lua
return {
  {
    "author/plugin-name",
    opts = { ... },
    -- Lazy loading (pick one):
    -- ft = { "lua", "python" },
    -- event = "VeryLazy",
    -- keys = { { "<leader>x", ... } },
  },
}
```

### Disabling a LazyVim Plugin

Add to `lua/plugins/disabled.lua`:

```lua
return {
  { "plugin/name", enabled = false },
}
```

### Filetype Settings

Add `ftplugin/<filetype>.lua` for filetype-specific options (runs automatically
on buffer open).

## Notable Integrations

- **Zellij**: Terminal multiplexer navigation via zellij-nav.nvim
- **Obsidian**: Vault at `.obsidian/this/` with custom diagnostic suppression
- **SSH**: OSC 52 clipboard support for remote sessions
- **Catppuccin**: Default colorscheme
