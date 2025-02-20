{ ... }:
{
  substituters = [
    "https://nix-community.cachix.org"
    "https://cache.nixos.org"
    "https://mroz.cachix.org"
    "https://cache.mercury.com"
  ];
  trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "mroz.cachix.org-1:yHi4Z+V6BviriR92yRIKFSfo6QR2LBSH7/YALi/f6vQ="
    "cache.mercury.com:yhfFlgvqtv0cAxzflJ0aZW3mbulx4+5EOZm6k3oML+I="
  ];
}
