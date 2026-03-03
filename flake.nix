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
      ollamaOverlay = (
        final: prev: {
          ollama-cuda = prev.ollama-cuda.overrideAttrs (oldAttrs: rec {
            version = "0.17.5";
            src = prev.fetchFromGitHub {
              owner = "ollama";
              repo = "ollama";
              rev = "v${version}";
              hash = "sha256-MPcLs9O7GZoPLnpGq3LQU13j6Nhhb4InoeXLts6yncU=";
            };
          });
        }
      );
      open-webuiOverlay = (
        final: prev: {
          ollama-cuda = prev.ollama-cuda.overrideAttrs (oldAttrs: rec {
            version = "0.8.8";
            src = prev.fetchFromGitHub {
              owner = "open-webui";
              repo = "open-webui";
              rev = "v${version}";
              hash = "sha256-3n/Zp+uEmaFuBTgRtXYM6BGpmum9/SLJ0j90DH9inbo=";
            };
          });
        }
      );
      commonModule = {
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [
          faugusOverlay
          ollamaOverlay
          open-webuiOverlay
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
          ];
        };

        travail = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            commonModule
            ./hosts/02-travail/configuration-travail.nix
            agenix.nixosModules.default
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
            agenix.nixosModules.default
          ];
        };

        valheim = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            commonModule
            ./hosts/04-valheim/configuration-valheim.nix
            agenix.nixosModules.default
          ];
        };

        VM = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            commonModule
            ./hosts/99-VM/configuration-VM.nix
            agenix.nixosModules.default
          ];
        };
      };
    };
}
