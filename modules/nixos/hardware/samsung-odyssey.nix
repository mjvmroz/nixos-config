_: {
  home-manager.sharedModules = [
    {
      wayland.windowManager.hyprland.extraConfig = ''
        # Odyssey G9
        monitor = DP-2, 5120x1440@120, 0x0, 1
      '';
    }
  ];
}
