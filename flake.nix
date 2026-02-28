{
  description = "Configuration NixOS Multi-Machine";

  #==== Sources ====
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  #==== Configuration ====
  outputs =
    inputs@{ self, nixpkgs, ... }:
    {
      nixosConfigurations = {

        maousse = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [ ./hosts/maousse/configuration-maousse.nix ];
        };

        travail = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [ ./hosts/travail/configuration-travail.nix ];
        };

        jarvis = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [ ./hosts/jarvis/configuration-jarvis.nix ];
        };

        valheim = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [ ./hosts/valheim/configuration-valheim.nix ];
        };
      };
    };
}
