{ pkgs, inputs, ... }:

  {

   # import the nixos module
    imports = [
      inputs.noctalia.nixosModules.default
      ];
   # enable the systemd service
    services.noctalia-shell.enable = true;

    environment.systemPackages = with pkgs; [
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
  }
