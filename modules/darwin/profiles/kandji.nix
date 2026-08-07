{ config, lib, ... }:

{
  config = lib.mkIf (config.mroz.machine.mdm == "kandji") {
    # Kandji wants to manage my tailscale installation itself 🤬
    services.tailscale.enable = lib.mkForce false;
  };
}
