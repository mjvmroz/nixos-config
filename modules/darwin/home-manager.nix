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

  # What gets installed comes from modules/darwin/apps; this is just how.
  #
  # If you have previously added a Mac App Store app to your profile (but not
  # installed it on this system), you may see "Redownload Unavailable with This
  # Apple ID". That message is safe to ignore.
  # (https://github.com/dustinlyons/nixos-config/issues/83)
  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps; # This defaults empty which causes problems with the aggressive nix-based management below
    onActivation = {
      # Must stay off. nix-darwin only passes HOMEBREW_NO_AUTO_UPDATE=1 when
      # this is false, and without it brew.sh re-execs itself to pick up new
      # environment variables, losing the PATH entry nix-darwin injected for
      # mas. Every masApps entry then fails with "mas installation failed",
      # including ones already installed.
      # https://github.com/zhaofengli/nix-homebrew/issues/131
      #
      # Taps are pinned as flake inputs anyway, so there is nothing for an
      # auto-update to fetch; casks move when those inputs are updated.
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = true;
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
              gitEmail = identity.gitEmail;
              signingKey = identity.signingKey;
            };
          };

          # App entries come from modules/darwin/apps; this is for the rest.
          dock = {
            enable = true;
            entries = [
              {
                path = "${config.home.homeDirectory}/Downloads";
                section = "others";
                options = "--view fan --display stack";
                order = 900;
              }
            ];
          };
        };
      };
  };
}
