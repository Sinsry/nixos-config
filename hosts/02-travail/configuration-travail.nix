# Configuration spécifique à travail
# Hardware : AMD GPU, usage bureautique

{
  pkgs,
  # lib,
  ...
}:
let
  nbhost = "02";
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
  networking.hostName = "${host}";

  #==== Boot spécifique ====
  boot = {
    kernelParams = [
      "video=1920x1080@60"
    ];
  };

  #==== Paquets spécifiques ====
  environment = {
    systemPackages = with pkgs; [
      btop-rocm
    ];
  };

  #==== Clavier ====
  console.keyMap = "fr";
  services.xserver.xkb.layout = "fr";

  system.activationScripts.fastfetch = ''
    mkdir -p /home/${user}/.config/fastfetch
    chown -R ${user}:users /home/${user}/.config
    ln -sfn /etc/nixos/hosts/${nbhost}-${host}/asset/fastfetch/config.jsonc /home/${user}/.config/fastfetch/config.jsonc
    ln -sfn /etc/nixos/hosts/${nbhost}-${host}/asset/fastfetch/date.sh /home/${user}/.config/fastfetch/date.sh
  '';
}
