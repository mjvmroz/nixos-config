{
  config,
  pkgs,
  lib,
  ...
}:

# Original source: https://gist.github.com/antifuchs/10138c4d838a63c0a05e725ccd7bccdd

with lib;
let
  cfg = config.home.dock;
  inherit (pkgs) dockutil;
in
{
  options = {
    home.dock.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable dock management via Home Manager.";
      example = true;
    };

    home.dock.entries = mkOption {
      description = ''
        Entries on the Dock. Contributed from several places (the app registry,
        the host config), so position comes from `order` rather than from the
        order definitions happen to be merged in.
      '';
      default = [ ];
      type =
        with types;
        listOf (submodule {
          options = {
            path = mkOption {
              type = str;
              # dockutil compares against the URIs already in the Dock, which
              # always carry a trailing slash for bundles. Normalising here means
              # callers don't have to remember.
              apply = path: if hasSuffix ".app" path then path + "/" else path;
            };
            order = mkOption {
              type = int;
              default = 100;
              description = "Position within the Dock, sorted low to high.";
            };
            section = mkOption {
              type = str;
              default = "apps";
            };
            options = mkOption {
              type = str;
              default = "";
            };
          };
        });
    };
  };

  config = mkIf cfg.enable (
    let
      # Path breaks ties so the result doesn't depend on merge order.
      entries = sort (
        a: b: if a.order != b.order then a.order < b.order else a.path < b.path
      ) cfg.entries;

      entryURI =
        path:
        "file://"
        + (builtins.replaceStrings
          [
            " "
            "!"
            "\""
            "#"
            "$"
            "%"
            "&"
            "'"
            "("
            ")"
          ]
          [
            "%20"
            "%21"
            "%22"
            "%23"
            "%24"
            "%25"
            "%26"
            "%27"
            "%28"
            "%29"
          ]
          path
        );
      wantURIs = concatMapStrings (entry: "${entryURI entry.path}\n") entries;
      createEntries = concatMapStrings (
        entry:
        "${dockutil}/bin/dockutil --no-restart --add '${entry.path}' --section ${entry.section} ${entry.options}\n"
      ) entries;
    in
    {
      home.packages = with pkgs; [
        killall
        coreutils
        dockutil
      ];
      home.activation.dock = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        echo >&2 "Setting up the Dock..."
        haveURIs="$(${dockutil}/bin/dockutil --list | ${pkgs.coreutils}/bin/cut -f2)"
        if ! diff -wu <(echo -n "$haveURIs") <(echo -n '${wantURIs}') >&2 ; then
          echo >&2 "Resetting Dock."
          ${dockutil}/bin/dockutil --no-restart --remove all
          ${createEntries}
          ${pkgs.killall}/bin/killall Dock
        else
          echo >&2 "Dock setup complete."
        fi
      '';
    }
  );
}
