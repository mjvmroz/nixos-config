{ config, pkgs, lib, identity, onePassAgentPath, gpgSshProgram, ... }:

let
  shared-programs = import ../../../modules/shared/home-manager.nix {
    inherit
      config
      pkgs
      lib
      onePassAgentPath
      identity
      gpgSshProgram
      ;
  };
in {
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    protonup
  ];

  home.sessionVariables = {
    STEAM_EXTRA_COMPAT_DATA_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };

  programs = shared-programs;

  # GPU issues with Hyprland :(
  # wayland.windowManager.hyprland = {
  #   enable = true;
  # };
}
