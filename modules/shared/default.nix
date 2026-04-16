{
  config,
  pkgs,
  nixpkgs,
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
      );
  };
}
