{ homebrew-bundle
, homebrew-core
, homebrew-cask
, nix-homebrew
, username
, ...
}:
{
  imports = [
    nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
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
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    taps = [
      "homebrew/cask"
      "homebrew/core"
      "homebrew/bundle"
    ];

    brews = [
      "docker-compose"
      "docker-credential-helper"
      "lima"
    ];

    casks = [
      "1password"
      "1password-cli"
      "akiflow"
      "chatgpt"
      "claude"
      "cmux"
      "discord"
      "docker-desktop"
      "firefox"
      "ghostty"
      "google-chrome"
      "iterm2"
      "notion"
      "obsidian"
      "raycast"
      "slack"
      "tailscale-app"
      "twingate"
      "visual-studio-code"
      "vlc"
      "zen"
      "zoom"
    ];
  };
}
