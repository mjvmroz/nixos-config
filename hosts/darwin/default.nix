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
    ../../modules/darwin/apps
    ../../modules/darwin/profiles
    ../../modules/darwin/home-manager.nix
    ../../modules/darwin/postgres.nix
    ../../modules/shared
    inputs.agenix.darwinModules.default
  ];

  # Setup user, packages, programs
  # nix.package is set by modules/darwin/lix.nix, which not every host imports.
  nix = {
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

  services.tailscale.enable = true;

  # Turn off NIX_PATH warnings now that we're using flakes
  system.checks.verifyNixPath = false;

  # nix-darwin puts the installer's bootstrap profile on PATH alongside its own
  # Nix, so `nix doctor` sees two nix binaries and fails. Where nix-darwin owns
  # the installation its copy is authoritative, so drop the bootstrap one; the
  # binary stays on disk as a recovery fallback, just not on PATH. Hosts with
  # nix.enable = false must keep it, since there it is the only Nix they have.
  environment.profiles = lib.mkIf config.nix.enable (
    lib.mkForce [
      "$HOME/.nix-profile"
      "/etc/profiles/per-user/$USER"
      "/run/current-system/sw"
    ]
  );

  # Keeping the installer's profile off PATH isn't enough on its own, because
  # anything that sources its profile.d snippets before shelling out puts it
  # back, and `nix doctor` then fails on the two nix binaries. Since nix-darwin
  # owns nix here, the copy in that profile is dead weight: the daemon plist
  # execs an absolute store path and NIX_SSL_CERT_FILE comes from /etc/static,
  # so nothing depends on it. Drop it and leave the rest of the profile alone.
  system.activationScripts.postActivation.text = lib.mkIf config.nix.enable ''
    if [[ -e /nix/var/nix/profiles/default/bin/nix ]]; then
      echo "removing the redundant nix from the installer's bootstrap profile" >&2
      nix-env --profile /nix/var/nix/profiles/default --uninstall lix nix || true
    fi
  '';

  # Load configuration that is shared across systems
  environment.systemPackages =
    with pkgs;
    [
      inputs.agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
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
