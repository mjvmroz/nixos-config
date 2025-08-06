{
  inputs,
  pkgs,
  identity,
  lib,
  ...
}:

with lib;
let
  pkgs-unstable = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.system};
in
{
  options = {
    mroz.hyprland.enable = mkEnableOption {
      default = true;
      description = "Enable Mroz's hyprland configuration";
    };
  };

  config = {
    programs.hyprland = {
      enable = true;
      # set the flake package
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      # make sure to also set the portal package, so that they are in sync
      portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
    };

    services.xserver.enable = true; # Might need this for Xwayland

    environment.systemPackages = with pkgs; [
      kitty # Terminal (Hyprland's default, pays to keep it around)
      waybar # Status bar
      hyprpicker # Color picker
      swww # Wallpaper setter
    ];

    xdg.portal = {
      enable = true;
    };

    environment.sessionVariables.NIXOS_OZONE_WL = "1"; # This variable fixes electron apps in wayland
  };
}
