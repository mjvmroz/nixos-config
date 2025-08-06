{
  identity,
  config,
  pkgs,
  lib,
  home-manager,
  ...
}:

let
  sharedFiles = import ../shared/files.nix { inherit config pkgs; };
  additionalFiles = import ./files.nix { inherit identity config pkgs; };
  onePassAgentPath = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  gpgSshProgram = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
in
{
  imports = [
    ./dock
  ];

  # It me
  users.users.${identity.user} = {
    name = "${identity.user}";
    home = "/Users/${identity.user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix { };
    taps = builtins.attrNames config.nix-homebrew.taps; # This defaults empty which causes problems with the aggressive nix-based management below
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    # If you have previously added these apps to your Mac App Store profile (but not installed them on this system),
    # you may receive an error message "Redownload Unavailable with This Apple ID".
    # This message is safe to ignore. (https://github.com/dustinlyons/nixos-config/issues/83)

    masApps = {
      Tailscale = 1475387142;
    };
  };

  # Enable home-manager
  home-manager = {
    useGlobalPkgs = true;
    users.${identity.user} =
      {
        pkgs,
        config,
        lib,
        ...
      }:
      {
        home = {
          enableNixpkgsReleaseCheck = false;
          packages = pkgs.callPackage ./packages.nix { };
          file = lib.mkMerge [
            sharedFiles
            additionalFiles
          ];

          stateVersion = "23.11";
        };
        programs =
          { }
          // import ../shared/home-manager.nix {
            inherit
              identity
              config
              pkgs
              lib
              onePassAgentPath
              gpgSshProgram
              ;
          };

        # Marked broken Oct 20, 2022 check later to remove this
        # https://github.com/nix-community/home-manager/issues/3344
        manual.manpages.enable = false;
      };
  };

  # Fully declarative dock using the latest from Nix Store
  local = {
    dock = {
      enable = true;
      entries = [
        { path = "/Applications/Google Chrome.app/"; }
        { path = "/System/Applications/Messages.app/"; }
        { path = "/Applications/iTerm.app/"; }
        { path = "${pkgs.alacritty}/Applications/Alacritty.app/"; }
        { path = "/Applications/1Password.app/"; }
        { path = "/Applications/Visual Studio Code.app/"; }
        { path = "/Applications/Spotify.app/"; }
        {
          path = "${config.users.users.${identity.user}.home}/Downloads";
          section = "others";
          options = "--view fan --display stack";
        }
        # {
        #   path = "${config.users.users.${user}.home}/.local/share/";
        #   section = "others";
        #   options = "--sort name --view grid --display folder";
        # }
      ];
    };
  };
}
