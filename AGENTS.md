# AGENTS.md

Agent instructions for the `scottames/dots` repository.

## Project Overview

This is a **dotfiles repository** managed by [chezmoi](https://www.chezmoi.io/).
The `home/` directory (defined in `.chezmoiroot`) contains templates and files
that chezmoi uses to manage dotfiles in the user's home directory.

**Key directories:**

- `home/` - Chezmoi source directory (maps to `~`)
- `home/.chezmoiscripts/` - Scripts run by chezmoi during apply
- `home/private_dot_config/` - Config files (maps to `~/.config/`)
- `aqua/` - CLI tool version management via aqua
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
