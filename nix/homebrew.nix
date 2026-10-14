{ homebrew-bundle
, homebrew-core
, homebrew-cask
, lib
, manageHomebrew
, nix-homebrew
, username
, ...
}:
{
  imports = [
    nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = lib.mkIf manageHomebrew {
    autoMigrate = true;
    enable = true;
    enableRosetta = true;
    user = username;
    mutableTaps = true;
    taps = {
      "homebrew/homebrew-core" = homebrew-core;
      "homebrew/homebrew-cask" = homebrew-cask;
      "homebrew/homebrew-bundle" = homebrew-bundle;
    };
  };

  homebrew = {
    enable = true;
    greedyCasks = true;
    global.autoUpdate = true;
    onActivation = {
      cleanup = if manageHomebrew then "zap" else "none";
      autoUpdate = manageHomebrew;
      upgrade = manageHomebrew;
    };

    taps = lib.optionals manageHomebrew [
      "homebrew/cask"
      "homebrew/core"
      "homebrew/bundle"
    ];

    brews = [
      "docker-compose"
      "docker-credential-helper"
      "eza"
      "lima"
      "openssh"
      "try-rs"
    ];

    casks = [
      "1password-cli"
      "akiflow"
      "docker-desktop"
      "firefox"
      "ghostty"
      "google-cloud-sdk"
      "granola"
      "iterm2"
      "notion"
      "obsidian"
      "raycast"
      "tailscale-app"
      "vlc"
      "zen"
      "zoom"
    ] ++ lib.optionals manageHomebrew [
      # Leave these apps to the company when Homebrew is externally managed.
      "1password"
      "google-chrome"
      "slack"
      "visual-studio-code"
    ];
  };
}
