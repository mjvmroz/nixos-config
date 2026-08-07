{ lib, ... }:

# Personal M2 Max. Runs Determinate Nix, so modules/darwin/lix.nix is left out
# rather than pointing nix-direnv and friends at an interpreter this host
# doesn't actually run.

{
  networking.hostName = "sapporo";
  mroz.machine.profile = "personal";

  # TODO: clean this up. This machine now uses Determinate Nix, which doesn't
  #       permit nix-darwin to manage the installation itself.
  nix.enable = false;
  nix.gc.automatic = lib.mkForce false;
}
