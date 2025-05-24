{ inputs, ... }:
{
  imports = [
    ./hardware/nvidia.nix
    ./hardware/samsung-odyssey.nix
    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.nixosModules.stylix
    ./core.nix
    ./x11.nix
    ./localization.nix
    ./security.nix
    ../shared/security
    ../shared
    ./gaming.nix
    ./hyprland.nix
    ./audio.nix
  ];
}
