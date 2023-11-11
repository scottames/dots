# Changelog

## [0.6.0](https://github.com/scottames/dots/compare/v0.5.0...v0.6.0) (2023-11-11)


### Features

* **act:** add act + hacky support for podman ([a28764a](https://github.com/scottames/dots/commit/a28764a8cf38bfc2c73e60b48962dd6e7c0003f7))
* add gpg pub key + import ([a80bfdd](https://github.com/scottames/dots/commit/a80bfddbb66284ad8ccc69ebbc5536d5364bb733))
* **aqua:** add dive ([af32f02](https://github.com/scottames/dots/commit/af32f02f5f78907a61a7f371c184663184189575))
* **aqua:** add gron - make json grepable ([c8505a0](https://github.com/scottames/dots/commit/c8505a02e34caedd607091e2792c629cc16db245))
* **aqua:** add smallstep/certificates ([88030ed](https://github.com/scottames/dots/commit/88030ed80b7afd6f888160bddea0950d8a293558))
* **distrobox:** add fedora image ([34d8c93](https://github.com/scottames/dots/commit/34d8c932e9cbd09d735b151ee2a50ba873f5e91b))
* **distrobox:** add ublue/fedora image + enable nvidia when appropriate ([b2b218b](https://github.com/scottames/dots/commit/b2b218b52959c0210eeaad9e7fd0d0218356427b))
* **distrobox:** script to export apps & bins ([616822c](https://github.com/scottames/dots/commit/616822cbe8598229a722963dd2d9bd5d249dd9de))
* **fish:** add function to quickly update git submodules in repo ([d90c2f8](https://github.com/scottames/dots/commit/d90c2f8d75d62f19616e2740c936d0c9c6981ae2))
* **fish:** add gobrew ([5fe5415](https://github.com/scottames/dots/commit/5fe5415c2c114c991fe6cc8899e4fdb1c6e24435))
* **fish:** keybinding to drop into distrobox ([b91b666](https://github.com/scottames/dots/commit/b91b666e201c25993b5a69875095fde1dbbb929f))
* **fish:** more fun with light/dark ([ce92b74](https://github.com/scottames/dots/commit/ce92b74ca5b7148fad12ed4492394e1c206ebb1d))
* **gsettings:** backup favs + support distrobox backup ([67cf73f](https://github.com/scottames/dots/commit/67cf73fa07d7b4d2012246254d21ab5aad778924))
* **immich-go:** add to aqua + token export ([86f78f2](https://github.com/scottames/dots/commit/86f78f20fa7be46366c154d1d9f7fb433c6f9106))
* **just:** add ~/.justfile (only ublue support today) ([a61c8e3](https://github.com/scottames/dots/commit/a61c8e38b8391d636a62ab9d42966e589f69cb93))
* **nav:** add dkaslovsky/nav to aqua + helper funcs ([37f554a](https://github.com/scottames/dots/commit/37f554a04974fc9dd805de937c74755f30414a06))
* **nvim/wezterm:** auto-change dark/light based on time ([8fd5d09](https://github.com/scottames/dots/commit/8fd5d0979589c0d01f7e53ac622ead78f9e53205))
* **nvim/zellij:** dark/light based on hour ([dae9272](https://github.com/scottames/dots/commit/dae92723938368d7f8aad086d9f94d2867f5523a))
* **nvim:** add justfile treesitter parser ([4076584](https://github.com/scottames/dots/commit/4076584c5dcffb7f138d783a65f2f9ca3204192f))
* playing w/ custom wallpaper config ([f7bbbb9](https://github.com/scottames/dots/commit/f7bbbb9abd07d29bce85fab2f034760df83d7207))
* **pre-commit:** add commit-msg local runner ([db45d30](https://github.com/scottames/dots/commit/db45d30553badaaead31e21f5cd218c9314fd16d))
* small tweaks to distrobox assemble + add just to aqua ([4039ee2](https://github.com/scottames/dots/commit/4039ee226cb6f273106255784d40ff2c58cc7f01))
* **zellij:** shortcut for new tab w/ editor in specified dir ([68dd3a3](https://github.com/scottames/dots/commit/68dd3a39fdcf951ebf4634fa674b9fc12cc98209))


### Bug Fixes

* **aqua:** revert installer version until they update their website ([86219a4](https://github.com/scottames/dots/commit/86219a43fad64f56b462ab7fd07f66fa15235837))
* **chezmoi:** overly trimmed blackbox + starship escape ([4fae81d](https://github.com/scottames/dots/commit/4fae81d4cd9dda966db45c1ef98cd6511c61a98e))
* **chezmoi:** properly handle ublue/not ([3f4f5bd](https://github.com/scottames/dots/commit/3f4f5bd7185c75423adc2eaf8e256d6e6dda97c5))
* **fix:** s/test/type/ ([fa887df](https://github.com/scottames/dots/commit/fa887df1209cf9de196ef32da884cf234e37d0a8))
* **nvim:** fix up catppuccin + other issues ([f7a10c6](https://github.com/scottames/dots/commit/f7a10c6e3b576ec4a66bfbe8ec2cde7c85e5dbf6))
* **paperwm:** update user.js based on recent changes ([0fa2771](https://github.com/scottames/dots/commit/0fa27715b6fcaced25a8d4670bf0fb38974e4856))
* path, cleanup db-assemble, chezmoi loginctl outside db ([df8295b](https://github.com/scottames/dots/commit/df8295be8d3b3cf80caeb4eccb8efadca66bae65))
* **starship:** timeout + check custom ([972a7cf](https://github.com/scottames/dots/commit/972a7cf2e9d4068c6b1b0a7d6baee8654bf14065))
* **zellij:** add copy_command based on desktop env ([1e063c8](https://github.com/scottames/dots/commit/1e063c821908c9ee3752f987f5c973e147e631e9))

## [0.5.0](https://github.com/scottames/dots/compare/v0.4.0...v0.5.0) (2023-07-29)


### Features

* **aqua:** add gum ([a3f2898](https://github.com/scottames/dots/commit/a3f2898975f7704a47d9459ddc953422ffcf9b4a))
* **aqua:** add some more bins ([fd03d67](https://github.com/scottames/dots/commit/fd03d677aa7e526bfbd601306769cfc4e0e504c9))
* **aqua:** more packages! ([10a1b80](https://github.com/scottames/dots/commit/10a1b80925aba8d81bfbab88f847d54b1b43743f))
* **chezmoi:** add GTK Colloid cursors ([89c8cb9](https://github.com/scottames/dots/commit/89c8cb9cc329749bc074eb5099d8ab9cc918d35d))
* **chezmoi:** additional nerd fonts ([b64a68e](https://github.com/scottames/dots/commit/b64a68eabb1dacd2f560b5f0ce8b3a1a17758f67))
* **chezmoi:** flyway ([e9b522c](https://github.com/scottames/dots/commit/e9b522ca6a5e17d40de1aa118cb2be7034d085ea))
* **chezmoi:** gnome - install catppuccin themes (+ small refactor) ([cb27acc](https://github.com/scottames/dots/commit/cb27acc505eb3fa87005775bfbe76249f113b938))
* **chezmoi:** gnome extensions via gext ([4a9ffc9](https://github.com/scottames/dots/commit/4a9ffc94c7212af6530cdba8627c61a1bf8e8205))
* **chezmoi:** handle FiraCode nerd font ([d739378](https://github.com/scottames/dots/commit/d73937887948c675c81e820d024da3e2eb7dc76a))
* **chezmoi:** pyenv install a default python version ([fe84d00](https://github.com/scottames/dots/commit/fe84d00386fdcc3d23f4c196a8a962be2952c09a))
* **chezmoi:** ubuntu fonts ([d29998e](https://github.com/scottames/dots/commit/d29998e95bfab3b4990479221b3c2b374bd6328e))
* **distrobox:** always pull ([6c77111](https://github.com/scottames/dots/commit/6c77111a1f78e4527aad111b3e20c2255e1a8ca1))
* **fish:** set/getclip support wayland ([a9049d2](https://github.com/scottames/dots/commit/a9049d2c40ae722ea4bd3959ab5a37b0b1951f96))
* **git:** always setup remote ([5bc9720](https://github.com/scottames/dots/commit/5bc9720a76053dc4425c3e11994dfe1dad1a30c3))
* **gnome ext:** add pano ([a6111b7](https://github.com/scottames/dots/commit/a6111b7b26791ab66a123a3c585e36d1ba93c41a))
* **nvim:** copilot + lazy updates ([8270605](https://github.com/scottames/dots/commit/8270605ec6d5ee9cbf943478d4cb72a317d270e9))
* **paperwm:** calc always to scratch ([9e5e942](https://github.com/scottames/dots/commit/9e5e942aad39a462e693641f758db7a4be93c29a))
* **starship:** add distrobox info to prompt ([6c080eb](https://github.com/scottames/dots/commit/6c080eb7ff3c7b3d6828de44bd096b3053e8a2b4))
* wezterm config ([816a018](https://github.com/scottames/dots/commit/816a018fa5e0811ef1043e92672ccb4f89260508))


### Bug Fixes

* chezmoi gext + gpg init ([d995568](https://github.com/scottames/dots/commit/d99556839a81da961a08154ccf921c9b78ea6201))
* **chezmoi:** aqua update script - better handle op interaction ([ac3d5d9](https://github.com/scottames/dots/commit/ac3d5d919e8662076e46c897d059053817d0ff8a))
* **chezmoi:** catppuccin install ([ed93f41](https://github.com/scottames/dots/commit/ed93f41a0ec44d37734a9b5f91e663687fa11c05))
* **chezmoi:** init private repos - github auth check ([6e0b58a](https://github.com/scottames/dots/commit/6e0b58a97df48018fa7a5a34da934b3e3fa3d857))
* **chezmoi:** paperwm symlink ([8af5247](https://github.com/scottames/dots/commit/8af5247254ac6b5a87bd3770f0db2279fded1b6c))
* cleanup from distrobox additions + handy fish func ([ff47cb0](https://github.com/scottames/dots/commit/ff47cb07a2de4f01c9fcc586274fe231652f0e8a))
* **fish:** actually edit using chezmoi 🤦 ([c4005d2](https://github.com/scottames/dots/commit/c4005d2f36ff26cda1c4c8ce0882d86c9f33de31))
* **fish:** aqua func ([0965dba](https://github.com/scottames/dots/commit/0965dba3961765f835418b71b141f30d04079508))
* misc small fixes & tweaks ([ac2b09f](https://github.com/scottames/dots/commit/ac2b09f232abbe68843451e912bb790a9260eb87))
* **paperwm:** handle extension rename ([16d8bff](https://github.com/scottames/dots/commit/16d8bffdb6db33d543fdd6c1411d2be271a6cb4d))
* **renovate:** remove breaking quotes for aqua/catppuccin ([7b27666](https://github.com/scottames/dots/commit/7b2766669095ebcb4e256fe007ae39b521879a4d))
* **setenv:** has checks ([e9c454a](https://github.com/scottames/dots/commit/e9c454a8b1f61d6238d5b9b3f5f3340b488067ce))
* **starship:** removed nerdfont chars ([fb4f072](https://github.com/scottames/dots/commit/fb4f07239503d1fa524dfd696d519588a4a0fbef))

## [0.4.0](https://github.com/scottames/dots/compare/v0.3.0...v0.4.0) (2023-04-22)


### Features

* **aquas:** add mage-select, nvim, direnv ([ae61821](https://github.com/scottames/dots/commit/ae61821376e3ca8573a7229942a5501e7b4fe546))
* k8s + fish fun [+aquas] ([bf8fe99](https://github.com/scottames/dots/commit/bf8fe99ed03f74157ce50a23f86841a917ada8a7))
* **paru:** add paru conf ([b944552](https://github.com/scottames/dots/commit/b9445529e10fb70fef6b1ecc03ea51cb0cfb42c5))


### Bug Fixes

* init -&gt; req go & fix dockerfile ([eca7091](https://github.com/scottames/dots/commit/eca7091a563bb939308e43188913f9659d102891))

## [0.3.0](https://github.com/scottames/dots/compare/v0.2.0...v0.3.0) (2023-04-17)


### Features

* **aqua:** add fd ([7370a9b](https://github.com/scottames/dots/commit/7370a9b13277ade6e5e609d00174b13048a63d80))
* **mage:** testing with docker & go ([602dbe8](https://github.com/scottames/dots/commit/602dbe82e5abfea4cff6cba64feb7022c46282fe))

## [0.2.0](https://github.com/scottames/dots/compare/v0.1.0...v0.2.0) (2023-04-15)


### Features

* **mage:** option to install paru (AUR helper) ([f5cb6cb](https://github.com/scottames/dots/commit/f5cb6cb8b1f7eedf31865bd470f01ad6bb3ffe06))

## 0.1.0 (2023-04-15)


### Miscellaneous Chores

* release 0.1.0 ([5c9303b](https://github.com/scottames/dots/commit/5c9303b6ad747d5df5db66057b3d964f913cd89d))
