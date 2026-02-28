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
      extraPackages = with pkgs; [
        vulkan-loader
        vulkan-validation-layers
      ];
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

    pipewire.extraConfig.pipewire."99-no-suspend" = {
      "context.properties"."suspend-timeout-seconds" = 0;
    };

    samba = {
      enable = true;
      openFirewall = true;
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

  #==== Services Systemd ====
  systemd = {
    services = {
      NetworkManager-wait-online.enable = false;

      samba-smbd.wantedBy = lib.mkForce [ ];
      samba-nmbd.wantedBy = lib.mkForce [ ];
      samba-winbindd.wantedBy = lib.mkForce [ ];

      nixos-upgrade.serviceConfig = {
        ExecStartPre = "${pkgs.bash}/bin/bash -c 'readlink -f /run/current-system > /run/nixos-pre-upgrade-gen'";
      };

      nixos-upgrade-notification = {
        description = "Notification de mise à jour NixOS";
        after = [ "nixos-upgrade.service" ];
        wantedBy = [ "nixos-upgrade.service" ];

        path = with pkgs; [
          coreutils
          libnotify
          systemd
          sudo
          gawk
        ];

        script = ''
          PRE_GEN=$(cat /run/nixos-pre-upgrade-gen 2>/dev/null || echo "")
          CURRENT_GEN=$(readlink -f /run/current-system)
          if [ "$PRE_GEN" != "$CURRENT_GEN" ]; then
            for user_id in $(loginctl list-users --no-legend | awk '{print $1}'); do
              user_name=$(loginctl show-user "$user_id" -p Name --value)
              runtime_dir="/run/user/$user_id"
              if [ -d "$runtime_dir" ]; then
                sudo -u "$user_name" \
                  DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime_dir/bus" \
                  notify-send "NixOS : Mise à jour prête" \
                    "Redémarrage recommandé pour appliquer les changements." \
                    --icon=distributor-logo-nixos \
                    --urgency=normal \
                    --hint=string:desktop-entry:systemsettings
              fi
            done
          fi
        '';

        serviceConfig.Type = "oneshot";
      };
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

  security.rtkit.enable = true;

  #==== Environnement ====
  environment = {
    systemPackages = with pkgs; [
      discord
      ffmpeg
      google-chrome
      kdePackages.breeze-gtk
      kdePackages.keditbookmarks
      kdePackages.filelight
      kdePackages.ksshaskpass
      kdePackages.plasma-browser-integration
      kdePackages.qtwebengine
      libnotify
      meld
      mpv
      papirus-icon-theme
      protonvpn-gui
      vlc
      vorta
      vscode-fhs
      vulkan-tools

      # Thème SDDM
      (writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
        [General]
        background=${nixosConfigPath}/asset/wallpaper.png
      '')

      # Icônes KDE globales
      (writeTextDir "etc/xdg/kdeglobals" ''
        [Icons]
        Theme=Papirus-Dark
      '')
    ];

    sessionVariables = {
      GDK_BACKEND = "x11";
      GTK_THEME = "Breeze-Dark";
      SSH_ASKPASS_REQUIRE = "prefer";
    };
  };

  #==== Qt ====
  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };
}
