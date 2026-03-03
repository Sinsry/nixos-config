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
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };

  #==== Networking ====
  networking = {
    networkmanager = {
      enable = true;
      settings = {
        connection = {
          "ipv4.dhcp-send-release" = "yes";
        };
      };
    };
    firewall.enable = false;
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

  users.users.${user} = {
    hashedPassword = "$6$0dVqmZkohmN71nL.$E9cdlaxTsKG9nHYjORbpSB6ExtgPXTj5th1HYwgwt1l6kkeYbE7oGRx1y6bt.JVYuKlHNr4v1W/dUBEv4T1tT1";
    isNormalUser = true;
    description = gitName;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

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
        credential.helper = "cache --timeout=604800";
        commit.template = pkgs.writeText "commit-template" "Update\n";
        safe.directory = nixosConfigPath;
      };
    };

    bash = {
      completion.enable = true;
      interactiveShellInit = "clear && fastfetch";
    };
  };

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "046d:407c" ];
      settings = {
        main = {
        };
        "meta" = {
          f8 = "macro(g 20ms i 20ms t 20ms space 20ms c 20ms l 20ms o 20ms n 20ms e 20ms space 20ms h 20ms t 20ms t 20ms p 20ms s 20ms : 20ms / 20ms / 20ms g 20ms i 20ms t 20ms h 20ms u 20ms b 20ms . 20ms c 20ms o 20ms m 20ms / 20ms s 20ms i 20ms n 20ms s 20ms r 20ms y 20ms / 20ms n 20ms i 20ms x 20ms o 20ms s 20ms - 20ms c 20ms o 20ms n 20ms f 20ms i 20ms g 20ms . 20ms g 20ms i 20ms t)";
        };
      };
    };
  };

  #==== Paquets ====
  environment = {
    systemPackages = with pkgs; [
      cifs-utils
      dnsmasq
      duf
      ethtool
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
      rar
      rsync
      usbutils
      unzip
    ];

    shellAliases =
      let
        git-nixos = "git -C ${nixosConfigPath}";
        rebuild = "sudo nixos-rebuild switch --flake ${nixosConfigPath}";
      in
      {
        nixrebuild = rebuild;
        nixupdate = "nix flake update --flake ${nixosConfigPath} && ${rebuild}";
        nixpush = "${git-nixos} add . && (${git-nixos} commit -m 'Update' || true) && ${git-nixos} pull --rebase && ${git-nixos} push";
        nixpull = "${git-nixos} pull";
        nixlistenv = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
        nixgarbage = "sudo nix-collect-garbage -d && sudo nixos-rebuild boot";
      };

    etc."inputrc".text = ''
      set completion-ignore-case on
      set show-all-if-ambiguous on
      set completion-map-case on
    '';
  };

  #==== Système ====
  system = {
    stateVersion = "25.11";

    activationScripts.binbash = ''
      mkdir -p /bin
      ln -sf ${pkgs.bash}/bin/bash /bin/bash
    '';

    autoUpgrade = {
      enable = true;
      allowReboot = true;
      rebootWindow = {
        lower = "06:00";
        upper = "07:00";
      };
      flake = nixosConfigPath;
      dates = "hourly";
      upgrade = false;
      flags = [
        "--update-input"
        "nixpkgs"
        "--commit-lock-file"
      ];
    };
  };

  #==== Swap ====
  zramSwap = {
    enable = true;
    memoryPercent = 12;
  };
}
