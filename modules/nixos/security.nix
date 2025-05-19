{
  pkgs,
  identity,
  lib,
  ...
}:
{
  config = {
    home-manager.users.${identity.user} = {
      systemd.user.services._1password-gui = {
        Unit = {
          Description = "1Password GUI";
          After = [ "graphical-session-pre.target" ];
        };
        Service = {
          ExecStart = "${pkgs._1password-gui}/bin/1password --silent";
          Restart = "on-failure";
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };

    programs = {
      # 1Password is my agent of choice for SSH and GPG
      _1password.enable = true;
      _1password-gui = {
        enable = true;
        # Certain features, including CLI integration and system authentication support,
        # require enabling PolKit integration on some desktop environments (e.g. Plasma).
        polkitPolicyOwners = [ identity.user ];
      };
    };

    security.sudo.enable = true;
    security.pam.services.swaylock = { };
    security.pam.services.hyprlock = { };
  };
}
