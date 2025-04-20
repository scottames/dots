{
  homebrew-bundle,
  homebrew-core,
  homebrew-cask,
  nix-homebrew,
  username,
  ...
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
    global.autoUpdate = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
    caskArgs = {
      no_quarantine = true; # Disable Gatekeeper quarantine
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
      "cursor"
      "docker"
      "firefox"
      "ghostty"
      "google-chrome"
      "obsidian"
      "plexamp"
      "visual-studio-code"
      "vlc"
      "zen-browser"
    ];
    
    masApps = {
      "Home Assistant Companion" = 1099568401;
    };
  };
}
