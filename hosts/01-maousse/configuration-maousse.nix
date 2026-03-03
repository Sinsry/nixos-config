{
  pkgs,
  lib,
  ...
}:
let
  nbhost = "01";
  host = "maousse";
  user = "sinsry";
in
{
  imports = [
    ./hardware-configuration.nix
    ./disks-mounts.nix
    ../../common/common-desktop.nix
  ];

  #==== Configuration Souris (Quirks & Accélération) ====
  # Remplace l'ancien 'environment.etc' et le script SDDM pour la souris
  services.libinput = {
    enable = true;
    mouse = {
      accelProfile = "flat";
      extraConfig = ''
        [Logitech G903 LS]
        MatchName=Logitech G903 LS
        MatchUdevType=mouse
        AttrEventCodeDisable=REL_WHEEL_HI_RES;REL_HWHEEL_HI_RES
      '';
    };
  };

  #==== Identité ====
  networking.hostName = "${host}";

  #==== Boot spécifique ====
  boot = {
    kernelParams = [
      "video=2160x1440@165"
      "intel_iommu=on" # GPU passthrough
    ];
    kernel.sysctl = {
      "kernel.split_lock_mitigate" = 0; # Perfs gaming/Wine
    };
    kernelModules = [
      "ntsync"
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
    ];
  };

  #==== Nettoyage des Scripts d'activation ====
  system.activationScripts = {
    # On garde fastfetch pour l'instant
    fastfetch = ''
      mkdir -p /home/${user}/.config/fastfetch
      chown -R ${user}:users /home/${user}/.config
      ln -sfn /etc/nixos/hosts/${nbhost}-${host}/asset/fastfetch/config.jsonc /home/${user}/.config/fastfetch/config.jsonc
      ln -sfn /etc/nixos/hosts/${nbhost}-${host}/asset/fastfetch/date.sh /home/${user}/.config/fastfetch/date.sh
    '';
  };

  #==== Matériel & Programmes ====
  hardware.xpadneo.enable = true;

  programs.gamemode.enable = true;
  programs.steam = {
    enable = true;
    package = pkgs.steam.override {
      extraArgs = "-language french";
    };
  };

  #==== Paquets spécifiques ====
  environment.systemPackages = with pkgs; [
    btop-rocm
    dualsensectl
    faugus-launcher
    goverlay
    mangohud
    virt-viewer
    wowup-cf
  ];
}
