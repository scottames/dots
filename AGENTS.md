# AGENTS.md

Agent instructions for the `scottames/dots` repository.

## Project Overview

This is a **dotfiles repository** managed by [chezmoi](https://www.chezmoi.io/).
The `home/` directory (defined in `.chezmoiroot`) contains templates and files
that chezmoi uses to manage dotfiles in the user's home directory.

This is personal dotfiles: prefer boring, minimal solutions; do not build
product-grade abstractions or defenses unless explicitly requested or justified
by concrete risk.

**Key directories:**

- `home/` - Chezmoi source directory (maps to `~`)
- `home/.chezmoiscripts/` - Scripts run by chezmoi during apply
- `home/private_dot_config/` - Config files (maps to `~/.config/`)
- `aqua/` - CLI tool version management via aqua
  - checksum file is auto-generated - do not edit manually
- `nix/` - Nix/Darwin configuration (macOS only)
- `.dagger/` - Dagger module for container-based testing
- `.trunk/` - Trunk.io linter configurations

## Runtime Environment

Primary development happens inside a [distrobox](https://distrobox.it/)
container on Fedora Silverblue. This affects tool availability:

- **1Password (`op`)**: Only works via `distrobox-host-exec op` (get/load
  commands only), requires re-auth each time
- **Yubikey**: Accessible but touch-gated operations add friction
- **Host tools**: Some tools must be called via `distrobox-host-exec`

## Fish Shell Environment

Primary shell is fish. Environment setup uses a shell-agnostic approach.

### Loading Order

Fish `conf.d/` files load alphabetically. The `__` prefix ensures ordering:

```plaintext
__is_has.fish          # 1. Sets $IS_*, $HAS_* detection vars
__setenv.fish          # 2. Sources ~/.setenv (main env file)
__custom_functions.fish # 3. Adds custom_functions.d/ to fish_function_path
__path.fish            # 4. Builds $PATH using vars from setenv
*.fish                 # 5. Remaining configs (alphabetical)
```

### Key Files

| Source File                                        | Target                               | Purpose                        |
| -------------------------------------------------- | ------------------------------------ | ------------------------------ |
| `home/dot_setenv`                                  | `~/.setenv`                          | Main env vars (shell-agnostic) |
| `home/private_dot_config/fish/conf.d/`             | `~/.config/fish/conf.d/`             | Fish config snippets           |
| `home/private_dot_config/fish/custom_functions.d/` | `~/.config/fish/custom_functions.d/` | Fish functions                 |

### Shell-Agnostic Environment (`dot_setenv`)

`dot_setenv` works across bash/zsh/fish using fish's built-in `setenv` function
(csh compatibility). It sets environment variables like `EDITOR`, `GOPATH`,
`AQUA_*`, etc.

**Detection variables** (set by `__is_has.fish` before `dot_setenv` loads):

- `$IS_LINUX`, `$IS_MAC` - OS detection
- `$IS_DARK`, `$IS_LIGHT` - Theme mode
- `$HAS_*` - Binary availability (e.g., `$HAS_NVIM`, `$HAS_BAT`, `$HAS_GHTKN`)

### Custom Functions

`custom_functions.d/` contains fish functions, including wrappers that extend
CLI tools (e.g., `gh.fish` wraps `gh` with token handling).

## GitHub Tokens

`ghtkn` runs as a host-managed agent: a systemd user service on Linux and a
launchd user agent on macOS. Never run a refresh-enabled agent in a
passwordless-root container.

- Do not display or log `ghtkn get` output.
- Inspect non-secret state with `ghtkn info`; use `ghtkn docs list` and
  `ghtkn docs show <name>` for troubleshooting.
- The agent starts locked after every start or restart. From a trusted host
  terminal, unlock it with `ghtkn agent unlock --enable-refresh`.
- Linux distrobox clients use the host agent socket. On macOS, container VMs
  cannot mount a host Unix socket; forward it over SSH and set
  `GHTKN_AGENT_SOCKET` only inside the container.
- Login shells use Fish. OpenCode task commands use non-interactive Bash; other
  agents may use Zsh. Bash and Zsh both source `~/.shell_env`.

## Build/Lint/Test Commands

### Linting (Primary)

Trunk.io is the primary linter orchestrator. All linting should go through
trunk:

```bash
# Check all files
trunk check

# Check specific file(s)
trunk check path/to/file

# Auto-format all files
trunk fmt

# Auto-format specific file(s)
trunk fmt path/to/file
```

### Testing

Test chezmoi init in a container (requires dagger):

```bash
dagger call -m . init
```

### Chezmoi

**IMPORTANT:** Never run `chezmoi apply` unless explicitly directed by the user.
This modifies the user's home directory and should only be done intentionally.

```bash
# Preview what would change (safe)
chezmoi diff

# Verify templates render correctly (safe)
chezmoi execute-template < file.tmpl
```

## Code Style Guidelines

### General (EditorConfig)

- **Charset:** UTF-8
- **Line endings:** LF (Unix)
- **Final newline:** Always
- **Indent:** 2 spaces (default)
- **Max file length:** 200-300 lines, refactor beyond this

Exceptions defined in `.editorconfig`:

- Go, Makefile: tabs, 4-space width
- Python, Dockerfile: 4 spaces

### Shell Scripts (Bash)

Linters: `shellcheck`, `shfmt`

```bash
#!/usr/bin/env bash

set -eufo pipefail  # Strict mode for .tmpl scripts

# Color definitions (common pattern)
magenta='\033[0;35m'
red='\033[0;31m'
yellow='\033[0;33m'
clear='\033[0m'

# Helper functions
info() { printf "${magenta}%s${clear}\n" "${@}"; }
err() { printf "${red}%s${clear}\n" "${@}"; exit 1; }
warn() { printf "${yellow}%s${clear}\n" "${@}"; }
```

- Use `#!/usr/bin/env bash` shebang
- Quote variables: `"${var}"` not `$var`
- Use `[[ ]]` for conditionals, not `[ ]`
- Use `$(command)` not backticks
- Shellcheck directives in `.trunk/configs/.shellcheckrc`

### YAML

Linters: `yamllint`, `prettier`

- Quotes: only when needed
- No empty values in block/flow mappings
- 1 space minimum after comments

### Go

Linters: `gofmt`, `golangci-lint`

- Standard Go formatting (tabs)
- Import order: stdlib, external, internal

### Lua (Neovim configs)

Linter: `stylua`

- 2-space indentation
- Add file mode line: `-- vi: ft=lua`

### Python

Linters: `black`, `isort`, `ruff`, `bandit`

- 4-space indentation
- Black formatting
- Select rules: B, D3, E, F (see `.trunk/configs/ruff.toml`)

### Nix

Linter: `nixpkgs-fmt`

- Standard nix formatting

### Markdown

Linter: `markdownlint`

- Formatter-friendly config (formatting rules disabled)
- Let prettier handle formatting

## Chezmoi Conventions

### File Naming Prefixes

Chezmoi uses special prefixes in `home/`:

- `dot_` - Creates dotfile (e.g., `dot_bashrc` -> `~/.bashrc`)
- `private_` - Sets restrictive permissions (0600/0700)
- `executable_` - Sets executable bit
- `symlink_` - Creates symlink
- `*.tmpl` - Go template, rendered during apply

### Chezmoi Scripts (`.chezmoiscripts/`)

[docs](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/)

> chezmoi supports scripts that are executed when you run chezmoi apply. These
> scripts can be configured to run every time, only when their contents have
> changed, or only if they haven't been run before.

- `run_once_` - Run once per content hash
- `run_onchange_` - Run when watched files change
- `run_once_after_XX_name.sh.tmpl` - Numbered for ordering

### Templates

Templates use Go text/template syntax with chezmoi extensions:

```text
{{ .chezmoi.os }}           # Operating system
{{ .chezmoi.hostname }}     # Machine hostname
{{ if eq .host.os "linux" }}
  # Linux-specific content
{{ end }}
```

Use `chezmoi data` to view available data (pulls from `home/.chezmoi.toml`
written to `~/.config/chezmoi/chezmoi.toml` by chezmoi)

## Theming

Themes are switched at runtime, not at `chezmoi apply` time, so a theme change
never dirties this repo.

```plaintext
~/.config/themes/aura/             generated by chezmoi; all themes always present
~/.config/themes/catppuccin-mocha/
~/.config/themes/current  ───────► symlink; the only mutable state
```

`theme-set [<name>]` re-points the symlink and reloads what can reload live.
With no argument it opens a vicinae picker. It is a bash script in
`dot_local/bin/`, **not** a fish function, because vicinae cannot invoke those.

### Adding a color to the contract

`home/.chezmoidata/themes.toml` holds one table per theme with an identical key
set. Every theme must define every key. The contract is shaped to Aura, the most
constrained palette, so richer palettes map *down* into it.

### Adding an app

1. Write a partial in `home/.chezmoitemplates/theme/<app>.<ext>`. It receives
   the theme table, so `{{ .accent }}` and friends resolve directly.
2. Register it in the `$files` dict in
   `.chezmoiscripts/run_onchange_after_60_themes.sh.tmpl`.
3. Wire the app up by whichever of these it supports, in order of preference:
   - **include** the fragment from the app config (best; the config never
     changes again)
   - point the app at a theme *named* `current` and add a symlink to the table
     in `theme-set`
   - split the config into a `*.base.*` half plus a generated tail, and
     concatenate in `theme-set` (last resort; only starship and gh-dash need it)

**App config owns structure, theme fragment owns color.** Without that rule
every theme ends up duplicating every stylesheet.

Where a genuine upstream port exists, the fragment names it rather than
restating colors — see the `bat`, `ghostty` and `nvim` keys in the contract.

### Gotchas

- Env vars from a theme (`BAT_THEME`, fish colors) are read at **shell
  startup**. Shells opened before a switch keep the old values.
- `set -eufo pipefail` includes `-f`, which disables globbing. Use `find`, not a
  glob, in these scripts.
- `theme-set` also runs on darwin, so avoid GNU-only flags (`find -printf`,
  `readlink -f`).
- Externals with `exact = true` delete anything else in their directory,
  including symlinks `theme-set` writes there.
