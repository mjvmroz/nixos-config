{ lib, pkgs, ... }:

# The single source of truth for colour across every host. Written so it can be
# imported either as a NixOS/nix-darwin module or as a standalone home-manager
# module, since Stylix declares the same option names in all three.
#
# The palette is spelled out here rather than pulled from pkgs.base16-schemes
# because neither packaged Tokyo Night Storm scheme is usable as an ANSI palette:
# `tokyo-night-storm` is built for syntax highlighting and puts a pale lavender
# in the red slot, while `tokyo-night-terminal-storm` gets the accents right but
# drops the foreground to the same grey as base04.
let
  # Tokyo Night Storm as published upstream, before softening.
  tokyoNight = {
    bg = "#24283b";
    bgDark = "#212536";
    bgHighlight = "#292e42";
    terminalBlack = "#414868";
    dark5 = "#737aa2";
    fgDark = "#787c99";
    fg = "#a9b1d6";
    fgBright = "#c0caf5";

    red = "#f7768e";
    orange = "#ff9e64";
    yellow = "#e0af68";
    green = "#9ece6a";
    cyan = "#7dcfff";
    blue = "#7aa2f7";
    magenta = "#bb9af7";
  };

  toHex = n: lib.fixedWidthString 2 "0" (lib.toLower (lib.toHexString n));

  mix =
    ratio: from: to:
    let
      channel =
        offset:
        let
          a = lib.fromHexString (builtins.substring offset 2 from);
          b = lib.fromHexString (builtins.substring offset 2 to);
        in
        toHex (builtins.floor (a + (b - a) * ratio + 0.5));
    in
    "#${channel 1}${channel 3}${channel 5}";

  # Pulling an accent toward the foreground lightens and desaturates it in one
  # step, which is what reads as pastel. Raise for softer, lower for punchier.
  softness = 0.22;
  pastel = accent: mix softness accent tokyoNight.fgBright;

  # Upstream's dark foreground only reaches 3.6:1 on this background, and it is
  # what vivid paints plain files in `ls`. Lift it toward the main foreground.
  fgMuted = mix 0.4 tokyoNight.fgDark tokyoNight.fg;
in
{
  stylix = {
    enable = true;
    polarity = "dark";

    base16Scheme = with tokyoNight; {
      scheme = "Tokyo Night Storm Pastel";
      author = "Tokyo Night by Folke Lemaitre, softened locally";
      slug = "tokyo-night-storm-pastel";
      variant = "dark";

      base00 = bg;
      base01 = bgDark;
      base02 = bgHighlight;
      # Upstream's terminal_black (#414868) only manages 1.6:1 here, and this
      # slot does a lot of work: it is ANSI bright black, so eza draws the
      # dashes in permission strings and the date column with it, and vivid
      # paints ~66 "unimportant" patterns (*.o, *.hi, *.lock, tags) with it too.
      # dark5 is the next tone up in Tokyo Night's own ramp and reaches 3.5:1,
      # still clearly the dimmest tier but actually readable.
      base03 = dark5;
      base04 = fgMuted;
      # Sitting the main foreground on fg rather than fgBright takes the top off
      # the contrast range, which is the other half of "flatter".
      base05 = fg;
      base06 = fgBright;
      base07 = fgBright;

      base08 = pastel red;
      base09 = pastel orange;
      base0A = pastel yellow;
      base0B = pastel green;
      base0C = pastel cyan;
      base0D = pastel blue;
      base0E = pastel magenta;
      # Stylix's vivid target colours directory entries from base0F, so this is
      # what `ls` looks like. Blue keeps that conventional.
      base0F = pastel blue;
    };

    fonts.monospace = {
      package = pkgs.nerd-fonts.hasklug;
      name = "Hasklug Nerd Font";
    };
  };
}
