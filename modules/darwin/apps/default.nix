{
  identity,
  config,
  lib,
  ...
}:

# A single registry for everything Homebrew installs and everything that ends up
# in the Dock, so an app is described once and each host decides whether it wants
# it. Bundles only supply the default, which is what makes "everything except
# this one app, on this one machine" a one-line change in a host file.

let
  inherit (lib)
    filterAttrs
    mapAttrsToList
    mkOption
    types
    ;

  cfg = config.mroz;

  inAnyEnabledBundle = app: lib.any (bundle: lib.elem bundle cfg.appBundles) app.bundles;

  enabled = filterAttrs (_: app: app.enable) cfg.apps;

  # Attribute sets iterate in key order, so these come out alphabetically rather
  # than in catalog order. Homebrew doesn't care, and it keeps the generated
  # Brewfile from churning as the catalog is edited.
  sourcesOf =
    field: lib.filter (source: source != null) (mapAttrsToList (_: app: app.${field}) enabled);

  masEnabled = filterAttrs (_: app: app.masId != null) enabled;
in
{
  imports = [ ./catalog.nix ];

  options.mroz = {
    appBundles = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "core"
        "dev"
      ];
      description = ''
        Bundles whose apps this host wants. Membership only sets each app's
        `enable` default, so a host can still opt in or out of any single app.
      '';
    };

    apps = mkOption {
      default = { };
      description = "Registry of Homebrew-managed apps and tools.";
      type = types.attrsOf (
        types.submodule (
          { name, config, ... }:
          {
            options = {
              enable = mkOption {
                type = types.bool;
                default = inAnyEnabledBundle config;
                defaultText = "whether any of this app's bundles is in `mroz.appBundles`";
                description = "Whether this host wants ${name}.";
              };

              displayName = mkOption {
                type = types.str;
                default = name;
                description = ''
                  How the app names itself, as opposed to how Homebrew names it.
                  Used for the Dock path and the Mac App Store entry.
                '';
                example = "Visual Studio Code";
              };

              bundles = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = ''
                  Bundles this app belongs to. An app in no bundle is never
                  enabled by default and has to be asked for by name.
                '';
              };

              cask = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Homebrew cask providing this app.";
              };

              brew = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Homebrew formula providing this app.";
              };

              masId = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = ''
                  Mac App Store item ID, from `nix run nixpkgs#mas -- search <name>`.
                '';
              };

              dock = {
                enable = mkOption {
                  type = types.bool;
                  default = false;
                  description = "Whether to pin this app to the Dock.";
                };

                order = mkOption {
                  type = types.int;
                  default = 100;
                  description = "Position in the Dock, sorted low to high.";
                };

                path = mkOption {
                  type = types.str;
                  default = "/Applications/${config.displayName}.app";
                  defaultText = "/Applications/\${displayName}.app";
                  description = "Bundle to pin. Override for apps outside /Applications.";
                };
              };
            };
          }
        )
      );
    };
  };

  config = {
    homebrew = {
      casks = sourcesOf "cask";

      # brew bundle installs mas implicitly for masApps; listing it stops
      # cleanup uninstalling it again on every activation.
      brews = sourcesOf "brew" ++ lib.optional (masEnabled != { }) "mas";

      masApps = lib.mapAttrs' (_: app: lib.nameValuePair app.displayName app.masId) masEnabled;
    };

    home-manager.users.${identity.user}.home.dock.entries = mapAttrsToList (_: app: {
      inherit (app.dock) order path;
    }) (filterAttrs (_: app: app.dock.enable) enabled);
  };
}
