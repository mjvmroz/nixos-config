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
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    nixos-unified.url = "github:srid/nixos-unified";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    {
      self,
      darwin,
      nix-homebrew,
      homebrew-bundle,
      homebrew-core,
      homebrew-cask,
      home-manager,
      nixpkgs,
      disko,
      agenix,
      flake-parts,
      nixos-unified,
      treefmt-nix,
      hyprland,
    }@inputs:
    let
      identity = {
        name = "Michael Mroz";
        email = "michael@mroz.io";
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
          pkgs = nixpkgs.legacyPackages.${system};
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
    in
    {
      devShells = forAllSystems devShell;

      darwinConfigurations =
        nixpkgs.lib.genAttrs darwinSystems (
          system:
          darwin.lib.darwinSystem {
            inherit system;
            specialArgs = inputs // {
              inherit identity;
            };
            modules = [
              home-manager.darwinModules.home-manager
              nix-homebrew.darwinModules.nix-homebrew
              ./hosts/darwin
            ];
          }
        )
        // {
          sapporo = darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            specialArgs = inputs // {
              inherit identity;
            };
            modules = [
              home-manager.darwinModules.home-manager
              nix-homebrew.darwinModules.nix-homebrew
              hosts/darwin
              {
                # Sussy about this. Doesn't seem like it should be necessary.
                # Check this with `dscacheutil -q group | grep nixbld -B 3`
                ids.gids.nixbld = 350;
              }
            ];
          };
          chomusuke = darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            specialArgs = inputs // {
              inherit identity;
            };
            modules = [
              home-manager.darwinModules.home-manager
              nix-homebrew.darwinModules.nix-homebrew
              hosts/darwin
            ];
          };
        };

      nixosConfigurations =
        nixpkgs.lib.genAttrs linuxSystems (
          system:
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = inputs // {
              inherit identity;
            };
            modules = [
              disko.nixosModules.disko
              home-manager.nixosModules.home-manager
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  users.${identity.user} = import ./modules/nixos/home-manager.nix { inherit identity; };
                };
              }
              ./hosts/nixos
            ];
          }
        )
        // {
          tokyo1958 = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = inputs // {
              inherit identity;
            };
            modules = [
              home-manager.nixosModules.home-manager
              hosts/nixos/tokyo1958
            ];
          };
        };
    };
}
