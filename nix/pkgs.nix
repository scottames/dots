{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    coreutils-full
    curl
    fish
    git
    gnupg
    nodejs
    nushell
    nixfmt-rfc-style
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
