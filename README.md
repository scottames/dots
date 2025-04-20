# dots

⚡ Scotty's dotfiles

[![forthebadge](assets/image/built-for-linux.svg)](https://forthebadge.com) [![forthebadge](assets/image/works-on-my-machine.svg)](https://forthebadge.com)

[![chezmoi init](https://github.com/scottames/dots/actions/workflows/pr_chezmoi_init.yaml/badge.svg)](https://github.com/scottames/dots/actions/workflows/pr_chezmoi_init.yaml)
[![trunk.io](https://github.com/scottames/dots/actions/workflows/pr_trunkio.yaml/badge.svg)](https://github.com/scottames/dots/actions/workflows/pr_trunkio.yaml)

- see also:
    - [containers](https://github.com/scottames/containers) 
        - my personal collection of container builds which uses Fedora Atomic to build my entire Linux experience outside the home directory

## 🚀 init

Requirements: `curl`, `git`, and `go`

> 🙈 Don't do this at home.

```shell
curl -fsLS https://raw.githubusercontent.com/scottames/dots/main/scripts/init.sh | bash

```

Optionally, pass additional params to `chezmoi init`

```shell
curl -fsSL -O "https://raw.githubusercontent.com/scottames/dots/main/scripts/init.sh" && chmod +x init.sh && ./init.sh --branch <my_branch>
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
  [flake.nix](./flake.nix)) that calls `darwin-rebuild switch --flake .#` under the hood


## 🔧 Tools of Note

|               project                               |                                             description                                              |
|:----------------------------------------------------|:-----------------------------------------------------------------------------------------------------|
| [alacritty](https://alacritty.org/)                 | modern terminal emulator that comes with sensible defaults, but allows for extensive configuration   |
| [aqua](https://aquaproj.github.io/)                 | declarative cli version manager                                                                      |
| [chezmoi](https://www.chezmoi.io/)                  | manage your dotfiles across multiple diverse machines, securely                                      |
| [fish](https://fishshell.com/)                      | smart and user-friendly command line shell                                                           |
| [lazygit](https://github.com/jesseduffield/lazygit) | simple terminal UI for git commands                                                                  |
| [mage](https://magefile.org/)                       | make/rake-like build tool using golang                                                               |
| [lix](https://lix.systems/) (nix)                   | A modern, implementation of the Nix package manager, focused on correctness, usability, and growth.  |
| [nix-darwin](https://github.com/nix-darwin/nix-darwin) | nix modules for darwin  |
| [neovim](https://neovim.io/)                        | hyperextensible Vim-based text editor                                                                |
| [paperwm](https://github.com/paperwm/PaperWM)       | experimental Gnome Shell extension providing scrollable tiling of windows and per monitor workspaces |
| [starship](https://starship.rs/)                    | minimal, blazing-fast, and infinitely customizable prompt for any shell!                             |
| [trunk.io](https://trunk.io/)                       | check, merge, and monitor your code                                                                  |
| [wezterm](https://wezfurlong.org/wezterm/)          | a powerful cross-platform terminal emulator and multiplexer                                          |
| [zellij](https://zellij.dev/)                       | terminal workspace with batteries included                                                           |

## 🧪 Testing

Runs linter checks, go tests, and chezmoi init inside a docker container

```shell
mage check && mage test
```

- Requires: docker, go, mage, trunk

## 📜 Terms

Use at your own risk!

## ♥ Credits

"Nothing is original." Especially these dotfiles. Everything included here is heavily inspired by many giants that have come before me.

Some (far from all) noteworthy sources:

* https://github.com/sheldonhull/dotfiles-starter
* https://github.com/webpro/awesome-dotfiles
* https://github.com/folke/dot
* https://github.com/twpayne/dotfiles
* https://github.com/szorfein/dots
* https://github.com/ThePrimeagen

## ⚖️ License

The code is available under the [MIT license](LICENSE).
