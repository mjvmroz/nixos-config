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
      # zhaofengli-wip is a redirect to this; needs to be recent enough to
      # materialise declarative taps into the Taps tree rather than symlinking
      # them at the store, which brew >= 6 rejects because the realpath of a
      # formula escapes its tap root.
      # https://github.com/zhaofengli/nix-homebrew/pull/150
      url = "github:zhaofengli/nix-homebrew";
      # nix-homebrew pins brew to a tag of its own choosing, which drifts behind
      # the tap contents. The cask DSL is versioned with brew, so a tap newer
      # than the interpreter fails to parse: an August 2026 cask using
      # `postflight_steps` is "invalid" to brew 5.1.11. Point it at ours instead,
      # so all three move together.
      inputs.brew-src.follows = "brew-src";
    };
    brew-src = {
      url = "github:homebrew/brew/6.0.15";
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
    hyprland.url = "github:hyprwm/Hyprland";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    stylix.url = "github:nix-community/stylix";
    devenv.url = "github:cachix/devenv";
  };
  outputs =
    {
      self,
      darwin,
      nix-homebrew,
      brew-src,
      homebrew-core,
      homebrew-cask,
      home-manager,
      nixpkgs,
      agenix,
      flake-parts,
      hyprland,
      stylix,
      devenv,
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

      darwinConfig =
        {
          system ? "aarch64-darwin",
          modules ? [ ],
        }:
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
          ]
          ++ modules;
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
            # NixOS and nix-darwin hosts get these through their system module
            # tree; a standalone home-manager config has to import them itself.
            stylix.homeModules.stylix
            ./modules/shared/theme.nix
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
        # Unnamed entries for bootstrapping a machine that doesn't have a host
        # file yet: `darwin-rebuild switch --flake .#aarch64-darwin`.
        nixpkgs.lib.genAttrs darwinSystems (
          system:
          darwinConfig {
            inherit system;
            modules = [
              modules/darwin/lix.nix
              { mroz.machine.profile = "personal"; }
            ];
          }
        )
        // {
          sapporo = darwinConfig { modules = [ hosts/darwin/sapporo.nix ]; };
          chomusuke = darwinConfig { modules = [ hosts/darwin/chomusuke.nix ]; };
          megumin = darwinConfig { modules = [ hosts/darwin/megumin.nix ]; };
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
