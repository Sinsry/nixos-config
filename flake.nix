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
      system = "x86_64-linux";
      faugusOverlay = (
        final: prev: {
          faugus-launcher = prev.faugus-launcher.overrideAttrs (oldAttrs: rec {
            version = "main";
            src = prev.fetchFromGitHub {
              owner = "Faugus";
              repo = "faugus-launcher";
              rev = "${version}";
              hash = "sha256-eSNSxwI+FImSkjN4icmb1NO6iwsfLdYI1bmdD3vU+rk=";
            };
          });
        }
      );
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ faugusOverlay ];
      };
    in
    {
      nixosConfigurations = {
        maousse = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.pkgs = pkgs; }
            ./hosts/01-maousse/configuration-maousse.nix
          ];
        };

        travail = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.pkgs = pkgs; }
            ./hosts/02-travail/configuration-travail.nix
            agenix.nixosModules.default
          ];
        };

        jarvis = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.pkgs = pkgs; }
            {
              nixpkgs.overlays = [
                (final: prev: {
                  config.cudaSupport = true;
                })
              ];
            }

            ./hosts/03-jarvis/configuration-jarvis.nix
            agenix.nixosModules.default
          ];
        };

        valheim = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.pkgs = pkgs; }
            ./hosts/04-valheim/configuration-valheim.nix
            agenix.nixosModules.default
          ];
        };

        VM = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.pkgs = pkgs; }
            ./hosts/99-VM/configuration-VM.nix
            agenix.nixosModules.default
          ];
        };
      };
    };
}
