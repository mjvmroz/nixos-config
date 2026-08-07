# Shared

Configuration that applies whether the machine is running macOS or NixOS. Both
`hosts/darwin` and `modules/nixos` import this.

## Layout

```
.
├── default.nix        # nixpkgs config, and how we import overlays
├── fonts.nix          # Fonts installed everywhere
├── packages.nix       # List of packages to share
├── security           # Trusted substituters and their public keys
└── theme.nix          # Stylix theming, shared so standalone home-manager can import it too
```
