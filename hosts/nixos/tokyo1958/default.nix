# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{
  config,
  pkgs,
  lib,
  identity,
  inputs,
  ...
}:
let
  # This one is 1Password-managed
  keys = [ identity.sshKey ];
in
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "tokyo1958"; # Define your hostname.

  # Set this to the NixOS release at the time of the first install.
  system.stateVersion = "25.05";

  mroz.hardware.samsung-odyssey.enable = true;
  mroz.security.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users = {
    ${identity.user} = {
      isNormalUser = true;
      description = identity.name;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = keys;
    };

    root = {
      openssh.authorizedKeys.keys = keys;
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit identity;
    };
    users.${identity.user} =
      {
        pkgs,
        config,
        lib,
        ...
      }:
      {
        imports = [
          ../../../modules/home/nixos
          ../../../modules/home/mroz-shell.nix
        ];

        home = {
          stateVersion = "25.05";

          mroz.shell = {
            enable = true;
            identity = {
              name = identity.name;
              email = identity.email;
              signingKey = identity.signingKey;
            };
          };

          enableNixpkgsReleaseCheck = true;
          packages = pkgs.callPackage ../../../modules/nixos/packages.nix { };
        };

        programs = {
          vscode = {
            enable = true;
          };
          ghostty = {
            enable = true;
            package = pkgs.ghostty;
          };
          kitty = {
            enable = true;
          };
        };

        manual.manpages.enable = true;
      };
  };
}
