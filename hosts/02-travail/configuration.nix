{
  pkgs,
  ...
}:
let
  # nbhost = "02";
  host = "travail";
  user = "sinsry";
in
{
  imports = [
    ./hardware-configuration.nix
    ./disks-mounts.nix
    ../../common/common-desktop.nix
  ];

  #==== Identité ====
  networking.hostName = host;

  #==== Boot spécifique ====
  boot.kernelParams = [ "video=1920x1080@60" ];

  #==== Clavier ====
  console.keyMap = "fr";
  services.xserver.xkb.layout = "fr";

  #==== Activation ====
  system.activationScripts.fastfetch = ''
    mkdir -p /home/${user}/.config/fastfetch
    chown ${user}:users /home/${user}/.config/fastfetch
    ln -sfn /etc/nixos/asset/fastfetch.jsonc /home/${user}/.config/fastfetch/config.jsonc
  '';

  #==== Paquets spécifiques ====
  environment.systemPackages = with pkgs; [
    btop-rocm
  ];
}
