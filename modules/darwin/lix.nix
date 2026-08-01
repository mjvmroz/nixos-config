{ pkgs, ... }:

# Lix from nixpkgs, rather than the lix flake's own NixOS/darwin module.
#
# That module tracks lix `main`, which nixpkgs necessarily trails, so it warns
# about a major version mismatch on every eval and falls back to `pkgs.lix`
# anyway. Building its lix instead is worse: it's uncached, and it periodically
# fails to evaluate against a moving nixpkgs. This is the overlay-based approach
# lix documents for released versions.
#
# Imported per-host rather than from hosts/darwin, because hosts running someone
# else's CppNix (sapporo, on Determinate) must not have their nix tooling
# repointed at an interpreter they don't run.
{
  nix.package = pkgs.lixPackageSets.latest.lix;

  # Tools that link against nix, or shell out to it expecting matching store and
  # client protocols, need the same build the daemon runs. Take them from the
  # same package set instead of leaving them on nixpkgs' CppNix. Deliberately
  # narrow: the lix module's global `nixVersions.stable` rewire is what forces it
  # to carry an exclusion list for devenv, nixd and friends.
  nixpkgs.overlays = [
    (_final: prev: {
      inherit (prev.lixPackageSets.latest) nix-eval-jobs;

      # Not taken from the package set: its nix-direnv is defined there as
      # `nix-direnv.override { nix = lix; }` against the *top-level* package, so
      # re-exporting it into the top level makes it refer to itself. Doing the
      # same override against `prev` breaks the cycle. Anything else in that set
      # built by overriding a top-level package (nil, nix-du, colmena...) would
      # need the same treatment.
      nix-direnv = prev.nix-direnv.override { nix = prev.lixPackageSets.latest.lix; };
    })
  ];
}
