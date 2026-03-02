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
      # 1. On définit l'overlay séparément pour la clarté
      faugusOverlay = (
        final: prev: {
          faugus-launcher = prev.faugus-launcher.overrideAttrs (oldAttrs: rec {
            version = "1.15.10";
            src = prev.fetchFromGitHub {
              owner = "Faugus";
              repo = "faugus-launcher";
              rev = "v${version}";
              # Utilise une chaîne vide ou un faux hash pour forcer Nix à te donner le bon
              hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
            };
          });
        }
      );

      # 2. On crée une instance de pkgs qui inclut l'overlay
      pkgs = import nixpkgs {
        inherit system;
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
