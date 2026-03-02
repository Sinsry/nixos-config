# Configuration spécifique à maousse
# Hardware : AMD GPU, Intel CPU (IOMMU), gaming, virtualisation KVM

{
  pkgs,
  lib,
  ...
}:
let
  nbhost = "01";
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

  # ==== Overlay Mesa (temporaire) ====
  # nixpkgs.overlays = [ ... ];

  #==== SDDM input ====
  system = {
    activationScripts = {
      sddmKcminputrc = ''
        mkdir -p /var/lib/sddm/.config
        cat > /var/lib/sddm/.config/kcminputrc << 'EOF'
        ${kcminputrc}
        EOF
      '';

      fastfetch = ''
        mkdir -p /home/${user}/.config/fastfetch
        chown -R ${user}:users /home/${user}/.config
        ln -sfn /etc/nixos/hosts/${nbhost}-${host}/asset/fastfetch/config.jsonc /home/${user}/.config/fastfetch/config.jsonc
        ln -sfn /etc/nixos/hosts/${nbhost}-${host}/asset/fastfetch/date.sh /home/${user}/.config/fastfetch/date.sh
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
      "ntsync" # Améliore les perfs Wine/Proton
      "vfio_pci" # GPU passthrough
      "vfio"
      "vfio_iommu_type1"
    ];
  };

  #==== Clavier ====
  console.keyMap = "us";
  services.xserver.xkb.layout = "us";

  #==== Matériel spécifique ====
  hardware = {
    xpadneo.enable = true; # Manettes Xbox

    graphics.extraPackages = with pkgs; [
      rocmPackages.clr.icd # OpenCL AMD (calcul GPU)
      vulkan-loader
      vulkan-validation-layers
    ];
  };

  #==== Programmes spécifiques ====
  programs = {
    gamemode = {
      enable = true;
      enableRenice = true;
      settings.general.renice = 10;
    };

    partition-manager.enable = true;

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
  };

  #==== Sécurité ====
  security.pam.loginLimits = [
    {
      domain = "@gamemode";
      type = "-";
      item = "nice";
      value = "-20";
    }
  ];

  #==== Utilisateur ====
  users.users.${user}.extraGroups = lib.mkAfter [
    "gamemode"
  ];

  #==== Paquets spécifiques ====
  environment = {
    systemPackages = with pkgs; [
      btop-rocm
      dualsensectl # Manettes PS5
      faugus-launcher # Lanceur jeux Windows
      goverlay # Interface MangoHud
      mangohud # Overlay gaming
      virt-viewer # Visualiseur VMs
      wowup-cf # Addons World of Warcraft
    ];

    etc = {
      "libinput/local-overrides-g903.quirks".source = ../../asset/local-overrides-g903.quirks;
    };
  };

  # swapDevices = [
  #   {
  #     device = "/var/lib/swapfile";
  #     size = 32 * 1024;
  #   }
  # ];

}
