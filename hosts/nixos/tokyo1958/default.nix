# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{
  config,
  pkgs,
  lib,
  identity,
  home-manager,
  stylix,
  ...
}:
let
  # This one is 1Password-managed
  keys = [ identity.sshKey ];
in
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos/hardware/nvidia.nix
    ../../../modules/nixos/hardware/samsung-odyssey.nix
    home-manager.nixosModules.home-manager
    stylix.nixosModules.stylix
    ../../../modules/nixos/core.nix
    ../../../modules/nixos/security.nix
    ../../../modules/shared/security
    ../../../modules/shared/fonts.nix
    ../../../modules/nixos/gaming.nix
    ../../../modules/nixos/hyprland.nix
    ../../../modules/nixos/audio.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "tokyo1958"; # Define your hostname.

  # Set this to the NixOS release at the time of the first install.
  system.stateVersion = "25.05";

  mroz.hardware.samsung-odyssey.enable = true;
  mroz.security.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users = {
    ${identity.user} = {
      isNormalUser = true;
      description = identity.name;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      packages = with pkgs; [
        code-cursor
        discord-ptb
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
          ../../../modules/home/nixos/cursor.nix
          ../../../modules/home/nixos/wofi.nix
          ../../../modules/home/mroz-shell.nix
        ];

        home = {
          stateVersion = "25.05";

          mrozShell = {
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
