{
  config,
  pkgs,
  nixpkgs,
  devenv,
  system,
  ...
}:

{
  imports = [
    ./fonts.nix
    ./security
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    };

    overlays =
      let
        path = ../../overlays;
      in
      with builtins;
      map (n: import (path + ("/" + n))) (
        filter (n: match ".*\\.nix" n != null || pathExists (path + ("/" + n + "/default.nix"))) (
          attrNames (readDir path)
        )
      )
      ++ [
        (_final: prev: {
          devenv = devenv.packages.${prev.stdenv.hostPlatform.system}.devenv;
        })
      ];
  };
}
