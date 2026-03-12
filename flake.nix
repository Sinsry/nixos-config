{
  description = "Configuration NixOS Multi-Machine";

  #==== Sources ====
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    faugus.url = "github:Faugus/faugus-launcher/1.16.3";
  };

  #==== Configuration ====
  outputs =
    inputs@{
      self,
      nixpkgs,
      sops-nix,
      faugus,
      ...
    }:

    let
      system = "x86_64-linux";
      commonModule = {
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [
          (final: prev: {
            faugus-launcher = faugus.packages.${system}.default;
          })
        ];
      };
    in

    {
      nixosConfigurations = {
        maousse = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            commonModule
            ./hosts/01-maousse/configuration-maousse.nix
            sops-nix.nixosModules.sops
          ];
        };

        travail = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            commonModule
            ./hosts/02-travail/configuration-travail.nix
            sops-nix.nixosModules.sops
          ];
        };

        jarvis = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            commonModule
            {
              nixpkgs.config = {
                cudaSupport = true;
              };
            }
            ./hosts/03-jarvis/configuration-jarvis.nix
            sops-nix.nixosModules.sops
          ];
        };

        valheim = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            commonModule
            ./hosts/04-valheim/configuration-valheim.nix
            sops-nix.nixosModules.sops
          ];
        };

        VM = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            commonModule
            ./hosts/99-VM/configuration-VM.nix
            sops-nix.nixosModules.sops
          ];
        };
      };
    };
}
