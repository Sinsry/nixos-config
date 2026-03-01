{
  lib,
  pkgs,
  ...
}:
let
  gitEmail = "Sinsry@users.noreply.github.com";
  gitName = "Sinsry";
  nixosConfigPath = "/etc/nixos";
in
{
  imports = [ ./network-mounts.nix ];

  #==== Boot ==== Test
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
  users.users.sinsry = {
    isNormalUser = true;
    description = gitName;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  #==== Nix ====
  nixpkgs.config.allowUnfree = true;

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
        nixcheck = "git ls-remote https://github.com/NixOS/nixpkgs nixos-unstable | cut -c1-7 && nix flake metadata --json ${nixosConfigPath} | jq -r .locks.nodes.nixpkgs.locked.rev | cut -c1-7";
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
      allowReboot = false;
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
