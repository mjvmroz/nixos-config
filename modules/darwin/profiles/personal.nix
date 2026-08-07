{ config, lib, ... }:

{
  config = lib.mkIf (config.mroz.machine.profile == "personal") {
    mroz.appBundles = lib.mkDefault [
      "core"
      "dev"
      "media"
      "personal"
    ];
  };
}
