{
  identity,
  config,
  lib,
  ...
}:

{
  config = lib.mkIf (config.mroz.machine.profile == "work") {
    mroz.machine.mdm = lib.mkDefault "kandji";

    mroz.appBundles = lib.mkDefault [
      "core"
      "dev"
      "media"
      "work"
    ];

    # Work machines are bootstrapped by bootstrap-mercury rather than by the
    # upstream installer, and it picks a different nixbld gid. Set at normal
    # priority because nix-darwin's own default is already an mkDefault, so a
    # second mkDefault here would be a conflict rather than an override.
    ids.gids.nixbld = 350;

    # bootstrap-mercury insists on a literal `extra-trusted-users` entry naming
    # the current user, and adds it by replacing nix-darwin's /etc/nix/nix.conf
    # symlink with a regular file. The next darwin-rebuild then aborts on
    # "unrecognized content" in /etc. `trusted-users = @admin` already covers
    # this user, so this is redundant, but emitting it is what stops the two
    # tools fighting over the file.
    nix.settings.extra-trusted-users = [ identity.user ];

    # Work wants to randomly push changes to ~/.ssh/config 🫠
    home-manager.backupFileExtension = "backup";
  };
}
