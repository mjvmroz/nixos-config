{
  description = "mroz.env";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    hyprland.url = "github:hyprwm/Hyprland";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    stylix.url = "github:nix-community/stylix";
  };
  outputs =
    {
      self,
      darwin,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      home-manager,
      nixpkgs,
      agenix,
      flake-parts,
      hyprland,
      stylix,
    }@inputs:
    let
      identity = {
        name = "Michael Mroz";
        gitEmail = "4539332+mjvmroz@users.noreply.github.com";
        user = "mroz";
        sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJRQgKmvXGkbgTLFTCT0gtm6/fojgXcJhfcvNW2n6+WB";
        signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFXfLkgyrc4VC+xkXo5uCmQqx+nRxrdKwvyKOzEud6IF";
      };
      linuxSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      darwinSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs (linuxSystems ++ darwinSystems) f;
      devShell =
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          default =
            with pkgs;
            mkShell {
              nativeBuildInputs = with pkgs; [
                bashInteractive
                git
                age
                age-plugin-yubikey
              ];

              shellHook = with pkgs; ''
                export EDITOR=vim
              '';
            };
        };

      homeConfig =
        system: hostPath:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = inputs // {
            inherit identity inputs;
          };
          modules = [
            hostPath
          ];
        };
    in
    {
      devShells = forAllSystems devShell;

      homeConfigurations = {
        # Standalone Home Manager config for Fedora workstation/server.
        nagoya = homeConfig "x86_64-linux" ./hosts/home/nagoya;
      };

      darwinConfigurations =
        nixpkgs.lib.genAttrs darwinSystems (
          system:
          darwin.lib.darwinSystem {
            inherit system;
            specialArgs = inputs // {
              inherit identity inputs;
            };
            modules = [
              home-manager.darwinModules.home-manager
              nix-homebrew.darwinModules.nix-homebrew
              stylix.darwinModules.stylix
              hosts/darwin
            ];
          }
        )
        // {
          sapporo = darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            specialArgs = inputs // {
              inherit identity inputs;
            };
            modules = [
              home-manager.darwinModules.home-manager
              nix-homebrew.darwinModules.nix-homebrew
              stylix.darwinModules.stylix
              hosts/darwin
              {
                networking.hostName = "sapporo";
                # TODO: clean this up. This machine now uses Determinate Nix, which
                #       doesn't permit nix-darwin to manage the installation itself.
                nix.enable = false;
                nix.gc.automatic = nixpkgs.lib.mkForce false;
              }
            ];
          };
          chomusuke = darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            specialArgs = inputs // {
              inherit identity inputs;
            };
            modules = [
              home-manager.darwinModules.home-manager
              nix-homebrew.darwinModules.nix-homebrew
              stylix.darwinModules.stylix
              hosts/darwin
              {
                networking.hostName = "chomusuke";
                ids.gids.nixbld = 350;
                # Work makes me use Kandji, which wants to manage
                # my tailscale installation itself 🤬
                services.tailscale.enable = nixpkgs.lib.mkForce false;
              }
            ];
          };
        };

      nixosConfigurations = {
        tokyo1958 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = inputs // {
            inherit identity inputs;
          };
          modules = [
            hosts/nixos/tokyo1958
          ];
        };
      };
    };
}
