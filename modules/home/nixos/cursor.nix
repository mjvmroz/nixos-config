{ pkgs, ... }:

{
  home.packages = [ pkgs.hyprcursor ];

  home.pointerCursor = {
    name = "catppuccin-mocha-dark-cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
    size = 16;

    hyprcursor.enable = true;
    gtk.enable = true;
    x11.enable = true;
    x11.defaultCursor = "catppuccin-mocha-dark-cursors";
  };

  home.sessionVariables = {
    XCURSOR_SIZE = "16"; # X11 scales differently to Wayland ;_;
  };
}
