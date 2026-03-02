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

        test_script = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/99-VM/configuration-VM.nix
            agenix.nixosModules.default
          ];
        };
      };
    };
}
