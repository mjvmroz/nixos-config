{
  identity,
  config,
  pkgs,
  ...
}:

let
  xdg_configHome = "${config.users.users.${identity.user}.home}/.config";
  xdg_dataHome = "${config.users.users.${identity.user}.home}/.local/share";
  xdg_stateHome = "${config.users.users.${identity.user}.home}/.local/state";
in
{
  "${xdg_configHome}" = {
    source = ./config;
    recursive = true;
  };
}
