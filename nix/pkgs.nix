{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    coreutils-full
    curl
    fish
    git
    ghostty-bin
    gnupg
    gnugrep
    (callPackage ./mise.nix { })
    nodejs
    nushell
    nixfmt-rfc-style
    pipx
    vim
    wget
    yubikey-manager
    zsh
  ];
  fonts.packages = [
    pkgs.nerd-fonts.fira-code
    pkgs.nerd-fonts.fira-mono
    pkgs.nerd-fonts.hack
  ];
}
