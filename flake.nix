{
  description = "Configuration NixOS Multi-Machine";

  #==== Sources ====
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.darwin.follows = "";
    agenix.inputs.home-manager.follows = "";
  };

  #==== Configuration ====
  outputs =
    inputs@{
      self,
      nixpkgs,
      agenix,
      ...
    }:
    let
      system = "x86_64-linux"; # ou ton architecture
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          (final: prev: {
            faugus-launcher = prev.faugus-launcher.overrideAttrs (oldAttrs: rec {
              version = "1.15.10";
              src = prev.fetchFromGitHub {
                owner = "Faugus";
                repo = "faugus-launcher";
                rev = "v${version}";
                # Le hash spécifique pour la version 1.15.10
                # hash = "sha256-K8HnLpGfQyI0J0MvW9A9C2D3E4F5G6H7I8J9K0L1M2N=";
                hash = "000000000000000000000000000000000000000000000000000";
              };
            });
          })
        ];
      };
    in
    {
      nixosConfigurations = {

        maousse = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/01-maousse/configuration-maousse.nix
          ];
        };

        travail = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/02-travail/configuration-travail.nix
            agenix.nixosModules.default
          ];
        };

        jarvis = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/03-jarvis/configuration-jarvis.nix
            agenix.nixosModules.default
          ];
        };

        valheim = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/04-valheim/configuration-valheim.nix
            agenix.nixosModules.default
          ];
        };

        VM = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/99-VM/configuration-VM.nix
            agenix.nixosModules.default
          ];
        };
      };
    };
}
