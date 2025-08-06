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
      description = "Entries on the Dock";
      type =
        with types;
        listOf (submodule {
          options = {
            path = mkOption { type = str; };
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
      readOnly = true;
    };
  };

  config = mkIf cfg.enable (
    let
      normalize = path: if hasSuffix ".app" path then path + "/" else path;
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
          (normalize path)
        );
      wantURIs = concatMapStrings (entry: "${entryURI entry.path}\n") cfg.entries;
      createEntries = concatMapStrings (
        entry:
        "${dockutil}/bin/dockutil --no-restart --add '${entry.path}' --section ${entry.section} ${entry.options}\n"
      ) cfg.entries;
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
