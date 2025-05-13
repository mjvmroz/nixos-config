# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{
  config,
  pkgs,
  lib,
  identity,
  hyprland,
  ...
}:
let
  pkgs-unstable = hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  sharedFiles = import ../../../modules/shared/files.nix { inherit config pkgs; };
  shared-programs = import ../../../modules/shared/home-manager.nix {
    inherit
      config
      pkgs
      lib
      onePassAgentPath
      gpgSshProgram
      identity
      ;
  };
  onePassAgentPath = "~/.1password/agent.sock";
  gpgSshProgram = lib.getExe' pkgs._1password-gui "op-ssh-sign";
  # This one is 1Password-managed
  keys = [ identity.sshKey ];
in
{
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
        home = {
          stateVersion = "25.05";

          sessionVariables = {
            STEAM_EXTRA_COMPAT_DATA_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
          };

          # GPU issues with Hyprland - now with NVIDIA fixes
          wayland.windowManager.hyprland = {
            enable = true;
            systemd.enable = true;
            xwayland.enable = true;
            
            # NVIDIA-specific configuration
            extraConfig = ''
              # Monitor configuration
              monitor=,preferred,auto,1
              
              # Set environment variables for NVIDIA
              env = XCURSOR_SIZE,24
              env = WLR_NO_HARDWARE_CURSORS,1
              
              # For all categories, see https://wiki.hyprland.org/Configuring/Variables/
              input {
                  kb_layout = us
                  follow_mouse = 1
                  touchpad {
                      natural_scroll = false
                  }
                  sensitivity = 0
              }
              
              general {
                  gaps_in = 5
                  gaps_out = 10
                  border_size = 2
                  col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
                  col.inactive_border = rgba(595959aa)
                  layout = dwindle
              }
              
              # NVIDIA-specific performance tweaks
              env = LIBVA_DRIVER_NAME,nvidia
              env = __GLX_VENDOR_LIBRARY_NAME,nvidia
              
              # Animation configuration (lower for better performance on NVIDIA)
              animations {
                  enabled = true
                  bezier = myBezier, 0.05, 0.9, 0.1, 1.05
                  animation = windows, 1, 3, myBezier
                  animation = windowsOut, 1, 3, default, popin 80%
                  animation = fade, 1, 3, default
                  animation = workspaces, 1, 2, default
              }
              
              dwindle {
                  pseudotile = true
                  preserve_split = true
              }
              
              # Window rules for specific applications
              windowrulev2 = opacity 0.95 0.95,class:^(firefox)$
              windowrulev2 = opacity 0.98 0.98,class:^(Code)$
            '';
          };

          enableNixpkgsReleaseCheck = false;
          packages = pkgs.callPackage ../../../modules/nixos/packages.nix { };
          file = lib.mkMerge [
            sharedFiles
            # additionalFiles
          ];
        };

        programs = shared-programs // {
          vscode = {
            enable = true;
          };
          ghostty = {
            enable = true;
            package = pkgs.ghostty;
          };
        };

        # Marked broken Oct 20, 2022 check later to remove this
        # https://github.com/nix-community/home-manager/issues/3344
        manual.manpages.enable = true;
      };
  };

  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "tokyo1958"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

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

  # Enable sound with pipewire.
  # services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users = {
    mroz = {
      isNormalUser = true;
      description = "Michael Mroz";
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

  programs = {
    # Needed for anything GTK related
    dconf.enable = true;

    # My shell
    zsh.enable = true;

    # 1Password is my agent of choice for SSH and GPG
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      # Certain features, including CLI integration and system authentication support,
      # require enabling PolKit integration on some desktop environments (e.g. Plasma).
      polkitPolicyOwners = [ "mroz" ];
    };

    steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
      gamescopeSession.enable = true;
    };

    gamemode.enable = true;

    hyprland = {
      enable = true;
      # set the flake package
      package = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      # make sure to also set the portal package, so that they are in sync
      portalPackage = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
      # NVIDIA-specific configuration options
      enableNvidiaPatches = true;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    # Gaming
    mangohud
    protonup
    lutris
    heroic
    bottles
  ];

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  environment.sessionVariables = {
    # Wayland/Hyprland NVIDIA variables
    LIBVA_DRIVER_NAME = "nvidia";
    XDG_SESSION_TYPE = "wayland";
    GBM_BACKEND = "nvidia-drm"; # Use NVIDIA's GBM
    __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # Ensure OpenGL uses NVIDIA
    WLR_NO_HARDWARE_CURSORS = "1";  # Fix cursor rendering issues
    XCURSOR_SIZE = "24";
    # Additional Hyprland/NVIDIA fixes
    # Sometimes needed for correct GPU detection
    WLR_DRM_DEVICES = "/dev/dri/card0";
    # Hardware acceleration for video decode
    VDPAU_DRIVER = "nvidia";
    # Prevent flickering in some applications
    NIXOS_OZONE_WL = "1";
  };
}
