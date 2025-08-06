_: {
  home-manager.sharedModules = [
    {
      home.sessionVariables.STEAM_COMPAT_DATA_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    }
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = true;
}
