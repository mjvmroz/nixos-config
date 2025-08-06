{ config, pkgs, inputs, ... }:

let
  onePassPath = "~/.1password/agent.sock";
in {
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    protonup
  ];

  home.sessionVariables = {
    STEAM_EXTRA_COMPAT_DATA_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };

  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
          IdentityAgent ${onePassPath}
    '';
  };

  # GPU issues with Hyprland :(
  # wayland.windowManager.hyprland = {
  #   enable = true;
  # };
}
