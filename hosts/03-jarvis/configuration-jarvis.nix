# vCore : 4/8 / Ram : 4/8 Gio / Disk : 256 G
{
  pkgs,
  config,
  ...
}:
let
  nbhost = "03";
  host = "jarvis";
  user = "sinsry";
in
{
  imports = [
    ./hardware-configuration.nix
    ../../common/common-base.nix
  ];

  #==== Identité ====
  networking = {
    hostName = host;
    interfaces.eth0.ipv4.addresses = [
      {
        address = "192.168.1.3";
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.1.254";
    nameservers = [ "192.168.1.254" ];
  };

  users.users.${user} = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEHIB9gJxYTUgrC25g6iRw5L1CBzBnpkigigJzHbKb8B"
    ];
    extraGroups = [ "docker" ];
  };

  #==== Boot spécifique ====
  boot.blacklistedKernelModules = [ "nouveau" ];

  #==== Clavier ====
  console.keyMap = "us";

  #==== Age ====
  age.identityPaths = [ "/home/${user}/.ssh/id_ed25519" ];
  age.secrets.transmission-env = {
    file = ./asset/transmission-env.age;
    owner = "transmission";
  };

  #==== Services ====
  services = {
    openssh.enable = true;
    xserver.videoDrivers = [ "nvidia" ];
    qemuGuest.enable = true;
    ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      host = "0.0.0.0";
      loadModels = [
        "nomic-embed-text"
        "qwen2.5-coder:3b-instruct-q5_K_M"
        "qwen2.5-coder:7b-instruct-q5_K_M"
        "qwen2.5-coder:14b-instruct-q5_K_M"
        "booktrail/gemma3_tools:12b-it-qat"
      ];
      environmentVariables = {
        OLLAMA_KEEP_ALIVE = "-1";
      };
    };

    transmission = {
      enable = true;
      credentialsFile = config.age.secrets.transmission-env.path;
      settings = {
        download-dir = "/mnt/Torrents";
        incomplete-dir = "/mnt/Torrents";
        incomplete-dir-enabled = true;
        rpc-bind-address = "0.0.0.0";
        rpc-whitelist-enabled = false;
        rpc-authentication-required = true;
        peer-limit-global = 200;
        peer-limit-per-torrent = 50;
        ratio-limit = 2.0;
        ratio-limit-enabled = true;
        speed-limit-up = 6144;
        speed-limit-up-enabled = true;
        dht-enabled = false;
        pex-enabled = false;
        lpd-enabled = false;
        utp-enabled = false;
      };
    };
  };

  #==== Matériel ====
  hardware = {
    nvidia = {
      open = true;
      modesetting.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    # nvidia-container-toolkit.enable = true;
    graphics.enable = true;
  };

  #==== Virtualisation ====
  virtualisation = {
    docker.enable = true;
  };

  #==== Systemd ====
  systemd.services = {
    ollama-preload = {
      description = "Preload Ollama model into VRAM";
      after = [ "ollama.service" ];
      requires = [ "ollama.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "ollama-preload" ''
          ${pkgs.curl}/bin/curl -s http://localhost:11434/api/generate \
            -d '{"model": "qwen2.5-coder:3b-instruct-q5_K_M", "prompt": ""}'
        '';
      };
    };
  };

  #==== Système ====
  system = {
    activationScripts.fastfetch = ''
      mkdir -p /home/${user}/.config/fastfetch
      chown ${user}:users /home/${user}/.config/fastfetch
      ln -sfn /etc/nixos/hosts/${nbhost}-${host}/asset/fastfetch/config.jsonc /home/${user}/.config/fastfetch/config.jsonc
      ln -sfn /etc/nixos/hosts/${nbhost}-${host}/asset/fastfetch/date.sh /home/${user}/.config/fastfetch/date.sh
    '';

    autoUpgrade = {
      enable = true;
      allowReboot = true;
      rebootWindow = {
        lower = "06:00";
        upper = "06:30";
      };
    };
  };

  #==== Swap ====
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024;
    }
  ];

  #==== Paquets spécifiques ====
  environment.systemPackages = with pkgs; [
    btop-cuda
  ];
}
