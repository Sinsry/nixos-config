{
  description = "Configuration NixOS Multi-Machine";

  #==== Sources ====
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    faugus-launcher = {
      url = "github:Faugus/faugus-launcher/1.16.4";
      flake = false;
    };
  };

  #==== Configuration ====
  outputs =
    inputs@{
      self,
      nixpkgs,
      sops-nix,
      faugus-launcher,
      ...
    }:

    let
      system = "x86_64-linux";
      commonModule = {
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [
          (final: prev: {
            faugus-launcher = prev.faugus-launcher.overrideAttrs (_: {
              src = faugus-launcher;
              version = "git-${faugus-launcher.shortRev}";
            });
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
      };
    };
}
