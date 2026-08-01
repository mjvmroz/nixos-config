{ config, lib, ... }:

# Stylix has no iTerm2 target, so drive iTerm2 from the same palette by hand.
#
# This is written as an iTerm2 Dynamic Profile: a JSON file dropped into
# DynamicProfiles/ that iTerm2 picks up live, without touching its own
# preferences plist. The profile owns colours only and inherits everything else
# (font, keybindings, window settings) from the profile named below.
let
  colors = config.lib.stylix.colors;

  # iTerm2 stores each channel as a 0..1 float rather than a byte.
  channel = offset: hex: lib.fromHexString (builtins.substring offset 2 hex) / 255.0;

  color = hex: {
    "Color Space" = "sRGB";
    "Red Component" = channel 0 hex;
    "Green Component" = channel 2 hex;
    "Blue Component" = channel 4 hex;
    "Alpha Component" = 1;
  };

  # Slots 0-15, in the base16 ordering also used by Stylix's own terminal targets.
  ansi = with colors; [
    base00
    red
    green
    yellow
    blue
    magenta
    cyan
    base05
    base03
    bright-red
    bright-green
    bright-yellow
    bright-blue
    bright-magenta
    bright-cyan
    base07
  ];

  ansiColors = lib.listToAttrs (
    lib.imap0 (i: hex: lib.nameValuePair "Ansi ${toString i} Color" (color hex)) ansi
  );

  profile = ansiColors // {
    Name = "Stylix";
    Guid = "stylix-base16";
    "Dynamic Profile Parent Name" = "Default";

    "Background Color" = color colors.base00;
    "Foreground Color" = color colors.base05;
    "Bold Color" = color colors.base06;
    "Link Color" = color colors.base0D;
    "Badge Color" = color colors.base08;
    "Cursor Color" = color colors.base05;
    "Cursor Text Color" = color colors.base00;
    "Cursor Guide Color" = color colors.base02;
    "Selection Color" = color colors.base02;
    "Selected Text Color" = color colors.base05;
    "Tab Color" = color colors.base00;
    "Use Tab Color" = true;

    # Both of these let iTerm2 second-guess the palette at runtime, which reads
    # as muddy against colours this desaturated.
    "Smart Cursor Color" = false;
    "Minimum Contrast" = 0;
  };
in
{
  home.file."Library/Application Support/iTerm2/DynamicProfiles/stylix.json" =
    lib.mkIf config.stylix.enable
      {
        text = builtins.toJSON { Profiles = [ profile ]; };
      };
}
