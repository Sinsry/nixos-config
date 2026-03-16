{
  pkgs,
  lib,
  ...
}:
let
  # nbhost = "01";
  host = "maousse";
  user = "sinsry";
  g903Devices = [
    {
      id = "1133][16519";
      name = "Logitech G903 LS";
    }
    {
      id = "1133][49297";
      name = "Logitech G903 LIGHTSPEED Wireless Gaming Mouse w/ HERO";
    }
  ];
  kcminputrc =
    lib.concatMapStrings (d: ''
      [Libinput][${d.id}][${d.name}]
      PointerAccelerationProfile=1
    '') g903Devices
    + ''
      [Mouse]
      X11LibInputXAccelProfileFlat=true
    '';
in
{
  imports = [
    ./hardware-configuration.nix
    ./disks-mounts.nix
    ../../common/common-desktop.nix
  ];

  # ==== Overlay (temporaire) ====
  # nixpkgs.overlays = [ ... ];

  #==== Identité ====
  networking.hostName = host;

  #==== Boot spécifique ====
  boot = {
    kernelParams = [
      "video=2160x1440@165"
      "intel_iommu=on"
    ];

    kernel.sysctl = {
      "kernel.split_lock_mitigate" = 0;
    };

    kernelModules = [
      "ntsync"
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
    ];
  };

  #==== Clavier ====
  console.keyMap = "us";
  services.xserver.xkb.layout = "us";

  #==== Matériel spécifique ====
  hardware = {
    xpadneo.enable = true;
    graphics.extraPackages = with pkgs; [
      rocmPackages.clr.icd
    ];
  };

  #==== Utilisateur ====
  users.users.${user}.extraGroups = lib.mkAfter [ "gamemode" ];

  #==== Programmes spécifiques ====
  programs = {
    gamemode = {
      enable = true;
      enableRenice = true;
      settings.general.renice = 10;
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      package = pkgs.steam.override {
        extraEnv.STEAM_FORCE_DESKTOPUI_SCALING = "1";
        extraArgs = "-language french";
      };
    };
    partition-manager.enable = true;
  };

  #==== Système ====
  system.activationScripts = {
    sddmKcminputrc = ''
      mkdir -p /var/lib/sddm/.config
      cat > /var/lib/sddm/.config/kcminputrc << 'EOF'
      ${kcminputrc}
      EOF
    '';

    fastfetch = ''
      mkdir -p /home/${user}/.config/fastfetch
      chown ${user}:users /home/${user}/.config/fastfetch
      ln -sfn /etc/nixos/asset/fastfetch.jsonc /home/${user}/.config/fastfetch/config.jsonc
    '';
  };

  # swapDevices = [
  #   {
  #     device = "/var/lib/swapfile";
  #     size = 32 * 1024;
  #   }
  # ];

  #==== Paquets spécifiques ====
  environment = {
    systemPackages = with pkgs; [
      btop-rocm
      dualsensectl
      faugus-launcher
      goverlay
      mangohud
      wowup-cf
    ];
    etc = {
      "libinput/local-overrides.quirks".source = ../../asset/local-overrides-g903.quirks;
    };
  };
}
