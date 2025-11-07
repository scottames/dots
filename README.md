# dots

⚡ Scotty's dotfiles

[![forthebadge](assets/image/built-for-linux.svg)](https://forthebadge.com) [![forthebadge](assets/image/works-on-my-machine.svg)](https://forthebadge.com)

[![chezmoi init](https://github.com/scottames/dots/actions/workflows/pr_chezmoi_init.yaml/badge.svg)](https://github.com/scottames/dots/actions/workflows/pr_chezmoi_init.yaml)
[![trunk.io](https://github.com/scottames/dots/actions/workflows/pr_trunkio.yaml/badge.svg)](https://github.com/scottames/dots/actions/workflows/pr_trunkio.yaml)

- see also:
  - [containers](https://github.com/scottames/containers)
    - my personal collection of container builds which uses Fedora Atomic to
      build my entire Linux experience outside the home directory

## 🚀 init

Requirements: `curl`, `git`, and `go`

> 🙈 Don't do this at home.

```bash
curl -fsLS \
  https://raw.githubusercontent.com/scottames/dots/main/scripts/init.sh \
```

Optionally, pass additional params to `chezmoi init`

```bash
curl -fsSL \
  -O "https://raw.githubusercontent.com/scottames/dots/main/scripts/init.sh" \
  && chmod +x init.sh && ./init.sh --branch <my_branch>
```

### MacOS (Darwin)

nix flake is used to configure MacOS (Darwin) machines.

> nix is not used for Linux machines

Install nix ([lix](https://lix.systems/install/))

- Note: flakes should be enabled (by default in lix)

```bash
curl -sSf -L https://install.lix.systems/lix | sh -s -- install
```

```bash
cd /path/to/dots
nix run .#install
```

- Note: `.#install` is unique to this flake (see bottom of
  [flake.nix](./flake.nix)) that calls `darwin-rebuild switch --flake .#` under
  the hood

## 🔧 Tools of Note

|  project   |                                         description                                                                         |
|:----------------------------------------------------|:-----------------------------------------------------------------------------------|
| [aqua](https://aquaproj.github.io/)        | declarative cli version manager                                                                                            |
| [atuin](https://atuin.sh/)          | sync, search and backup shell history                                                                                            |
| [chezmoi](https://www.chezmoi.io/)     | manage your dotfiles across multiple diverse machines, securely                                                            |
| [fish](https://fishshell.com/)        | smart and user-friendly command line shell                                                                                 |
| [lazygit](https://github.com/jesseduffield/lazygit)     | simple terminal UI for git commands                                                                                        |
| [ghostty](https://ghostty.org/)     | Ghostty is a fast, feature-rich, and cross-platform terminal emulator that uses platform-native UI and GPU acceleration.   |
| [just](https://just.systems/)        | 🤖 Just a command runner                                                                                                   |
| [intelli-shell](https://github.com/lasantosr/intelli-shell)        |  like IntelliSense, but for shells                                                                                                     |
| [lix](https://lix.systems/)         | a modern, implementation of the Nix package manager, focused on correctness, usability, and growth. (MacOS only)           |
| [nix-darwin](https://github.com/nix-darwin/nix-darwin)  | nix modules for darwin                                                                                                     |
| [neovim](https://neovim.io/)      | hyperextensible Vim-based text editor                                                                                      |
| [Niri](https://github.com/YaLTeR/niri)        | a scrollable-tiling Wayland compositor.                                                                                   |
| [starship](https://starship.rs/)    | minimal, blazing-fast, and infinitely customizable prompt for any shell!                                                   |
| [trunk.io](https://trunk.io/)    | check, merge, and monitor your code                                                                                        |
| [vicinae](https://docs.vicinae.com/)    |  a focused launcher for your desktop — native, fast, extensible                                                                                         |
| [zellij](https://zellij.dev/)      | terminal workspace with batteries included                                                                                 |
| [zen browser](https://zen-browser.app/) | welcome to a calmer internet                                                                                               |

## 🧪 Testing

Runs linter checks, go tests, and chezmoi init inside a docker container

```shell
mage check && mage test
```

- Requires: docker, go, mage, trunk

## 📜 Terms

Use at your own risk!

## ♥ Credits

"Nothing is original." Especially these dotfiles. Everything included here is
heavily inspired by many giants that have come before me.

Some (far from all) noteworthy sources:

- [sheldonhull/dotfiles-starter](https://github.com/sheldonhull/dotfiles-starter)
- [webpro/awesome-dotfiles](https://github.com/webpro/awesome-dotfiles)
- [folke/dot](https://github.com/folke/dot)
- [twpayne/dotfiles](https://github.com/twpayne/dotfiles)
- [szorfein/dots](https://github.com/szorfein/dots)
- [ThePrimeagen](https://github.com/ThePrimeagen)

## ⚖️ License

The code is available under the [MIT license](LICENSE).
