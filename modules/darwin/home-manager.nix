{
  identity,
  config,
  pkgs,
  lib,
  home-manager,
  ...
}:

let
  additionalFiles = import ./files.nix { inherit identity config pkgs; };
in
{
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
      AppleConfigurator = 1037126344;
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
        imports = [
          ../home/darwin
          ../home/mroz-shell.nix
        ];

        home = {
          enableNixpkgsReleaseCheck = false;
          packages = pkgs.callPackage ./packages.nix { };
          file = lib.mkMerge [
            additionalFiles
          ];

          stateVersion = "24.05";

          mroz.shell = {
            enable = true;
            identity = {
              name = identity.name;
              email = identity.email;
              signingKey = identity.signingKey;
            };
          };

          dock = {
            enable = true;
            entries = [
              { path = "/Applications/Google Chrome.app/"; }
              # TODO: Maybe this is a good case for trying out modules + options?
              #       I don't want messages to be in the dock on my work machine,
              #       but I do want it on my personal ones.
              # { path = "/System/Applications/Messages.app/"; }
              { path = "/Applications/iTerm.app/"; }
              { path = "/Applications/1Password.app/"; }
              { path = "/Applications/Visual Studio Code.app/"; }
              { path = "/Applications/Spotify.app/"; }
              { path = "/Applications/ChatGPT.app/"; }
              {
                path = "${config.home.homeDirectory}/Downloads";
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
      };
  };
}
