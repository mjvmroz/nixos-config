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
    devenv.url = "github:cachix/devenv";
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
              modules/darwin/lix.nix
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
              # Determinate ships CppNix, so modules/darwin/lix.nix is left out
              # here rather than pointing nix-direnv and friends at an interpreter
              # this host doesn't actually run.
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
              modules/darwin/lix.nix
              hosts/darwin
              {
                networking.hostName = "chomusuke";
                ids.gids.nixbld = 350;

                # bootstrap-mercury insists on a literal `extra-trusted-users`
                # entry naming the current user, and adds it by replacing
                # nix-darwin's /etc/nix/nix.conf symlink with a regular file.
                # The next darwin-rebuild then aborts on "unrecognized content"
                # in /etc. `trusted-users = @admin` already covers this user, so
                # this is redundant, but emitting it is what stops the two tools
                # fighting over the file.
                nix.settings.extra-trusted-users = [ identity.user ];

                # Work makes me use Kandji, which wants to manage
                # my tailscale installation itself 🤬
                services.tailscale.enable = nixpkgs.lib.mkForce false;

                # Work wants to randomly push changes to ~/.ssh/config 🫠
                home-manager.backupFileExtension = "backup";
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
