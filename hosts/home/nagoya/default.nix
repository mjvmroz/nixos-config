{
  identity,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../../../modules/home/gtk.nix
    ../../../modules/home/mroz-shell.nix
  ];

  home = {
    username = identity.user;
    homeDirectory = "/home/${identity.user}";
    stateVersion = "24.05";
    enableNixpkgsReleaseCheck = false;
  };

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    ripgrep
    jq
    btop
    bat
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

  programs.zsh.initContent = ''
    # CUDA paths for development
    export PATH="/usr/local/cuda/bin:$PATH"
    export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
  '';

  nixpkgs.config.allowUnfree = true;
}
