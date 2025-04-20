{
  config,
  hostname,
  pkgs,
  lib,
  ...
}:
{
  nix.enable = true;

  networking = {
    computerName = hostname;
    hostName = hostname;
  };

  power.sleep = {
    allowSleepByPowerButton = true;
    computer = 20;
    display = 10;
    harddisk = 10;
  };

  programs = {
    nix-index.enable = true;
    fish.enable = true;
    zsh.enable = true;
  };

  security.pam.services.sudo_local.touchIdAuth = true; # TouchID for sudo authentication

  system.defaults = {

    controlcenter.BatteryShowPercentage = true;
    finder.FXPreferredViewStyle = "Nlsv"; # List view
    LaunchServices.LSQuarantine = false; # disables "Are you sure?" for new apps
    loginwindow.GuestEnabled = false;
    screensaver.askForPassword = true;
    trackpad.TrackpadRightClick = true;

    CustomUserPreferences = {
      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false;
      };
      "com.apple.ActivityMonitor" = {
        OpenMainWindow = true;
        IconType = 5;
        SortColumn = "CPUUsage";
        SortDirection = 0;
      };
      "com.apple.desktopservices" = {
        # Avoid creating .DS_Store files on network or USB volumes
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.finder" = {
        ShowExternalHardDrivesOnDesktop = true;
        ShowHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = false;
        ShowRemovableMediaOnDesktop = true;
        _FXSortFoldersFirst = true;
        # When performing a search, search the current folder by default
        FXDefaultSearchScope = "SCcf";
        DisableAllAnimations = true;
        NewWindowTarget = "PfDe";
        NewWindowTargetPath = "file://$\{HOME\}/Desktop/";
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        ShowStatusBar = true;
        ShowPathbar = true;
        WarnOnEmptyTrash = false;
      };
      "com.apple.SoftwareUpdate" = {
        AutomaticCheckEnabled = true;
        # Check for software updates daily, not just once per week
        ScheduleFrequency = 1;
        # Download newly available updates in background
        AutomaticDownload = 1;
        # Install System data files & security updates
        CriticalUpdateInstall = 1;
      };
      "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
      # Prevent Photos from opening automatically when devices are plugged in
      "com.apple.ImageCapture".disableHotPlug = true;
      # Turn on app auto-update
      "com.apple.commerce".AutoUpdate = true;
      "com.googlecode.iterm2".PromptOnQuit = false;
      "com.google.Chrome" = {
        AppleEnableSwipeNavigateWithScrolls = true;
        DisablePrintPreview = true;
        PMPrintingExpandedStateForPrint2 = true;
      };
    };

    dock = {
      appswitcher-all-displays = true;
      autohide = true;
      show-recents = false;
      tilesize = 26;
      persistent-apps = [
        "/Applications/Cursor.app"
        "/Applications/Ghostty.app"
        "/Applications/Zen.app"
      ];
    };

    menuExtraClock = {
      Show24Hour = true;
      ShowDate = 1;
      ShowSeconds = true;
    };

    NSGlobalDomain = {
      "com.apple.mouse.tapBehavior" = 1;
      AppleICUForce24HourTime = true;
      AppleInterfaceStyle = "Dark";
      ApplePressAndHoldEnabled = false;
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "Always";
      InitialKeyRepeat = 25;
      KeyRepeat = 2;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSDocumentSaveNewDocumentsToCloud = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      NSWindowShouldDragOnGesture = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
    };
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  users.users.scta = {
    name = "scta";
    home = "/Users/scta";
    shell = pkgs.fish;
  };
}
