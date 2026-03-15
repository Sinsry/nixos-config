{
  pkgs,
  lib,
  ...
}:
let
  nixosConfigPath = "/etc/nixos";
in
{
  imports = [ ./common-base.nix ];

  #==== Boot ====
  boot = {
    initrd = {
      kernelModules = [ "amdgpu" ];
      systemd.enable = true;
      verbose = false;
    };

    consoleLogLevel = 0;

    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "amdgpu.dcverbose=0"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];

    supportedFilesystems = [
      "ntfs"
      "exfat"
      "vfat"
      "ext4"
      "btrfs"
    ];
  };

  #==== Matériel ====
  hardware = {
    amdgpu.overdrive.enable = true;

    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    graphics = {
      enable = true;
      enable32Bit = true;
      # vulkan-loader est inclus automatiquement par enable32Bit
      # vulkan-validation-layers : uniquement utile en développement GPU
      extraPackages = [ ];
    };
  };

  #==== Services ====
  services = {
    lact.enable = true;
    gvfs.enable = true;
    spice-vdagentd.enable = true;

    xserver = {
      enable = true;
      videoDrivers = [ "amdgpu" ];
      excludePackages = [ pkgs.xterm ];
    };

    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "breeze";
      extraPackages = [ pkgs.papirus-icon-theme ];
    };

    desktopManager.plasma6.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      extraConfig.pipewire."99-no-suspend" = {
        "context.properties"."suspend-timeout-seconds" = 0;
      };
    };

    samba = {
      enable = true;
      # openFirewall retiré : smbd/nmbd/winbindd sont désactivés au démarrage,
      # ouvrir les ports firewall n'a pas de sens dans ce cas
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };
  };

  #==== Systemd ====
  systemd = {
    services = {
      NetworkManager-wait-online.enable = false;

      samba-smbd.wantedBy = lib.mkForce [ ];
      samba-nmbd.wantedBy = lib.mkForce [ ];
      samba-winbindd.wantedBy = lib.mkForce [ ];
    };
  };

  #==== Programmes ====
  programs = {
    firefox = {
      enable = true;
      languagePacks = [ "fr" ];
      preferences."intl.locale.requested" = "fr";
      nativeMessagingHosts.packages = [ pkgs.kdePackages.plasma-browser-integration ];
    };

    chromium = {
      enable = true;
      extraOpts."NativeMessagingHosts"."org.kde.plasma.browser_integration" =
        "${pkgs.kdePackages.plasma-browser-integration}/etc/chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json";
    };

    ssh = {
      startAgent = true;
      enableAskPassword = true;
      askPassword = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
    };

    dconf.enable = true;
  };

  #==== Sécurité ====
  security.rtkit.enable = true;

  #==== Environnement ====
  environment = {
    systemPackages = with pkgs; [
      ddcutil
      discord
      ffmpeg
      google-chrome
      kdePackages.breeze-gtk
      kdePackages.keditbookmarks
      # kdePackages.kup
      kdePackages.filelight
      kdePackages.isoimagewriter
      kdePackages.ksshaskpass
      kdePackages.plasma-browser-integration
      kdePackages.qtwebengine
      libnotify
      meld
      mpv
      papirus-icon-theme
      protonvpn-gui
      remmina
      transmission-remote-gtk
      virt-viewer
      vlc
      vorta
      vscode-fhs
      vulkan-tools

      (writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
        [General]
        background=${nixosConfigPath}/asset/wallpaper.png
      '')
    ];

    etc = {
      "google-chrome/native-messaging-hosts/org.kde.plasma.browser_integration.json".source =
        "${pkgs.kdePackages.plasma-browser-integration}/etc/chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json";

      "xdg/kdeglobals".text = ''
        [Icons]
        Theme=Papirus-Dark
      '';
    };

    sessionVariables = {
      GTK_THEME = "Breeze-Dark";
      SSH_ASKPASS_REQUIRE = "prefer";
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.dejavu-sans-mono
  ];

  #==== Qt ====
  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };
}
