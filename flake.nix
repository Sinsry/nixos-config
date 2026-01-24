{
  description = "Configuration NixOS Full Unstable";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }: {
    nixosConfigurations.maousse = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
	./noctalia.nix
      ];
    };
  };
}
