{ pkgs }:

with pkgs;
let
  shared-packages = import ../shared/packages.nix { inherit pkgs; };
in
shared-packages
++ [
  betterdisplay # Display management; used to disable GPU dithering to fix external monitor flicker
]
