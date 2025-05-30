{
  identity,
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ../../modules/darwin/home-manager.nix
    ../../modules/darwin/postgres.nix
    ../../modules/shared
    inputs.agenix.darwinModules.default
  ];

  # Setup user, packages, programs
  nix = {
    package = pkgs.nix;
    settings = {
      trusted-users = [
        "@admin"
      ];
    };

    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nix-homebrew = {
    user = identity.user;
    enable = true;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
    mutableTaps = false;
    autoMigrate = true;
  };

  # Turn off NIX_PATH warnings now that we're using flakes
  system.checks.verifyNixPath = false;

  # Load configuration that is shared across systems
  environment.systemPackages =
    with pkgs;
    [
      inputs.agenix.packages."${pkgs.system}".default
    ]
    ++ (import ../../modules/shared/packages.nix { inherit pkgs; });

  system = {
    # This value determines the NixOS release with which your system is to be
    # compatible, in order to avoid breaking some software such as database
    # servers. You should change this only after NixOS release notes say you
    # should.
    stateVersion = 4;

    # Previously, some nix-darwin options applied to the user running
    # `darwin-rebuild`. As part of a long‐term migration to make
    # nix-darwin focus on system‐wide activation and support first‐class
    # multi‐user setups, all system activation now runs as `root`, and
    # these options instead apply to the `system.primaryUser` user.
    primaryUser = identity.user;

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;

        # 120, 90, 60, 30, 12, 6, 2
        KeyRepeat = 2;

        # 120, 94, 68, 35, 25, 15
        InitialKeyRepeat = 15;

        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };
      # Disabled for now as I'm using linearmouse via Brew Casks
      # ".GlobalPreferences" = {
      #   "com.apple.mouse.scaling" = -1.0;
      # };

      dock = {
        autohide = false;
        show-recents = false;
        launchanim = true;
        orientation = "bottom";
        tilesize = 36;
      };

      finder = {
        _FXShowPosixPathInTitle = true;
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
    };
  };
}
