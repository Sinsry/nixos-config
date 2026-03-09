{
  lib,
  pkgs,
  ...
}:
let
  user = "sinsry";
  gitEmail = "Sinsry@users.noreply.github.com";
  gitName = "Sinsry";
  nixosConfigPath = "/etc/nixos";
in
{
  imports = [ ./network-mounts.nix ];

  #==== Boot ====
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10; # Évite l'accumulation d'entrées de boot
        editor = false; # Désactive l'édition des paramètres kernel au boot (sécurité)
      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };

  #==== Networking ====
  networking = {
    search = [ "lan" ];
    networkmanager = {
      enable = true;
      settings = {
        connection = {
          "ipv4.dhcp-send-release" = "yes";
        };
      };
    };
    firewall.enable = false; # À activer si la machine est exposée
  };

  #==== Localisation ====
  time.timeZone = "Europe/Paris";

  i18n =
    let
      locale = "fr_FR.UTF-8";
    in
    {
      defaultLocale = locale;
      extraLocaleSettings = {
        LC_ADDRESS = locale;
        LC_IDENTIFICATION = locale;
        LC_MEASUREMENT = locale;
        LC_MONETARY = locale;
        LC_NAME = locale;
        LC_NUMERIC = locale;
        LC_PAPER = locale;
        LC_TELEPHONE = locale;
        LC_TIME = locale;
      };
    };

  #==== Users ====
  users.users.root = {
    hashedPassword = "$6$jG8elZ.qpjJ4/SIV$zBkmT9VLJK5DG8zcWfiQB7CvN68LZz2wIiSYOyzgAdhhObPhSaT/UK84a7yJeyiDH9UUKLeKdL3eyfCplOSAt/";
  };

  hardware = {
    i2c.enable = true;
  };

  users.users.${user} = {
    hashedPassword = "$6$0dVqmZkohmN71nL.$E9cdlaxTsKG9nHYjORbpSB6ExtgPXTj5th1HYwgwt1l6kkeYbE7oGRx1y6bt.JVYuKlHNr4v1W/dUBEv4T1tT1";
    isNormalUser = true;
    description = gitName;
    extraGroups = [
      "networkmanager"
      "wheel"
      "i2c"
    ];
  };

  #==== Nix ====
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      download-buffer-size = 1073741824; # 1 GiB
      max-jobs = "auto";
      cores = 0;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 15d";
    };
  };

  #==== Programmes ====
  programs = {
    git = {
      enable = true;
      config = {
        init.defaultBranch = "main";
        user = {
          name = gitName;
          email = gitEmail;
        };
        credential.helper = "cache --timeout=86400";
        commit.template = pkgs.writeText "commit-template" "Update\n";
        safe.directory = nixosConfigPath;
      };
    };

    bash = {
      completion.enable = true;
      interactiveShellInit = "clear && fastfetch";
    };
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        libGL
        libX11
        libXext
        libXrandr
        libXi
        libXcursor
        libXinerama
        libxkbcommon
        wayland
        SDL2
        SDL2_mixer
        SDL2_image
        SDL2_ttf
        libpulseaudio
        pipewire
      ];
    };
  };

  #==== Paquets ====
  environment = {
    systemPackages = with pkgs; [
      age
      binutils
      cifs-utils
      dnslookup
      dnsmasq
      duf
      ethtool
      eza
      fastfetch
      jq
      nfs-utils
      nil
      nixd
      nixfmt
      nvd
      openssl
      parted
      pciutils
      psmisc
      sops
      rar
      rsync
      ssh-to-age
      usbutils
      unzip
      wireguard-tools
    ];

    shellAliases =
      let
        git-nixos = "git -C ${nixosConfigPath}";
        rebuild = "sudo nixos-rebuild switch --flake ${nixosConfigPath}";
      in
      {
        ls = "eza --color=always --group-directories-first --icons=always";
        nixclone = "git clone https://github.com/sinsry/nixos-config.git";
        nixdiff = "nvd diff $(find /nix/var/nix/profiles -maxdepth 1 -name 'system-*-link' | sort -V | tail -2)"; # Diff des 2 dernières générations
        nixgarbage = "sudo nix-collect-garbage -d && sudo nixos-rebuild boot";
        nixlistenv = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
        nixpull = "${git-nixos} pull";
        nixpush = "${git-nixos} add . && (${git-nixos} commit -m 'Update' || true) && ${git-nixos} pull --rebase && ${git-nixos} push";
        nixrebuild = rebuild;
        nixupdate = "nix flake update --flake ${nixosConfigPath} && ${rebuild}";
      };

    etc."inputrc".text = ''
      set completion-ignore-case on
      set show-all-if-ambiguous on
      set completion-map-case on
    '';
  };

  #==== Sops Age Key ====
  systemd.user.services.sops-age-key = {
    description = "Generate sops age key from SSH key";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "sops-age-key" ''
        mkdir -p $HOME/.config/sops/age
        ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key < $HOME/.ssh/id_ed25519 \
          > $HOME/.config/sops/age/keys.txt
        chmod 600 $HOME/.config/sops/age/keys.txt
      '';
    };
  };

  #==== Système ====
  system = {
    stateVersion = "25.11";

    activationScripts.binbash = ''
      mkdir -p /bin
      ln -sf ${pkgs.bash}/bin/bash /bin/bash
    '';

    # autoUpgrade désactivé : --update-input avec upgrade = false est contradictoire.
    # Utilise plutôt l'alias nixupdate pour contrôler les mises à jour manuellement.
  };

  #==== Swap ====
  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };
}
