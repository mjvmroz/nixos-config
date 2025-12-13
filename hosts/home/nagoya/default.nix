{
  identity,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../../../modules/home/mroz-shell.nix
    ../../../modules/home/linux
  ];

  home = {
    username = identity.user;
    homeDirectory = "/home/${identity.user}";
    stateVersion = "24.05";
    enableNixpkgsReleaseCheck = false;
  };

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Install 1Password via Nix (no dnf/rpm needed).
    _1password-gui
    _1password-cli
  ];

  home.mroz.shell = {
    enable = true;
    identity = {
      name = identity.name;
      gitEmail = identity.gitEmail;
      signingKey = identity.signingKey;
    };
  };

  # Host identity (useful for prompt / scripts).
  home.sessionVariables = {
    HOSTNAME = "nagoya";
  };
}
