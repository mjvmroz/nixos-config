# Nix-darwin has an open bug where the generated configuration isn't enough to
# permit the service to start.
# https://github.com/LnL7/nix-darwin/issues/339#issuecomment-1140352696

{
  config,
  pkgs,
  identity,
  ...
}:

{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_14;
    extraPlugins = with pkgs.postgresql_14.pkgs; [
      postgis
      pg_repack
    ];
    authentication = ''
      local all all trust
    '';
  };

  # Create the PostgreSQL data directory, if it does not exist.
  system.activationScripts.preActivation = {
    enable = true;
    text = ''
      if [ ! -d "/var/lib/postgresql/" ]; then
        echo "creating PostgreSQL data directory..."
        sudo mkdir -m 775 -p /var/lib/postgresql/
        chown -R ${identity.user}:staff /var/lib/postgresql/
      fi
    '';
  };

  # Direct log output to $XDG_DATA_HOME/postgresql for debugging.
  launchd.user.agents.postgresql.serviceConfig = {
    # Un-comment these values instead to avoid a home-manager dependency.
    StandardErrorPath = "/Users/${identity.user}/.local/share/postgresql/postgres.error.log";
    StandardOutPath = "/Users/${identity.user}/.local/share/postgresql/postgres.out.log";
  };

  home-manager.users = {
    "${identity.user}" = {
      # Create the directory ~/.local/share/postgresql/
      xdg.dataFile."postgresql/.keep".text = "";
    };
  };
}
