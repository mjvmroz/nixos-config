{ lib, config, ... }:
with lib;
let
  cfg = config.mroz-hardware.samsung-odyssey;
in
{
  options = {
    mroz-hardware.samsung-odyssey.enable = mkEnableOption {
      default = false;
      description = "Enable support for the Samsung Odyssey G9 monitor.";
    };
  };
  config = mkIf cfg.enable {
    home-manager.sharedModules = [
      {
        wayland.windowManager.hyprland.extraConfig = ''
          # Odyssey G9
          monitor = DP-2, 5120x1440@120, 0x0, 1
        '';
      }
    ];
  };
}
