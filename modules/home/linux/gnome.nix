{ config, lib, pkgs, ... }:

{
  # Sensible Linux defaults for a Fedora + GNOME workstation where Nix is used
  # for shell/project env and dotfiles, not full system management.
  xdg.enable = true;

  # Manage GNOME settings via dconf (gsettings).
  dconf.enable = true;

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
      show-battery-percentage = true;
    };

    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "flat";
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
  };

  # Common CLI helpers (keep this minimal; projects should use devShells).
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
  ];

  # Optional: on Fedora you may prefer the RPM, but this keeps your git signer
  # working out-of-the-box if you don't install 1Password system-wide.
  nixpkgs.config.allowUnfree = true;
}


