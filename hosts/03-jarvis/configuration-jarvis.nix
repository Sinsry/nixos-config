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

  ollamaWait = pkgs.writeShellScript "ollama-wait" ''
    until ${pkgs.curl}/bin/curl -s http://localhost:11434 > /dev/null 2>&1; do
      sleep 1
    done
  '';
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
    nvidia-container-toolkit.enable = true;
    graphics.enable = true;
  };

  #==== Virtualisation ====
  virtualisation = {
    docker.enable = true;
    oci-containers = {
      backend = "docker";
      containers = {
        ollama = {
          image = "ollama/ollama:latest";
          ports = [ "11434:11434" ];
          volumes = [ "ollama:/root/.ollama" ];
          autoStart = true;
          extraOptions = [
            "--device=nvidia.com/gpu=all"
            "--network=ollama-net"
          ];
          environment.OLLAMA_KEEP_ALIVE = "-1";
        };
        open-webui = {
          image = "ghcr.io/open-webui/open-webui:latest";
          ports = [ "3000:8080" ];
          volumes = [ "open-webui:/app/backend/data" ];
          environment = {
            OLLAMA_BASE_URL = "http://ollama:11434";
            ENABLE_API_KEYS = "true";
            USER_PERMISSIONS_FEATURES_API_KEYS = "true";
          };
          extraOptions = [ "--network=ollama-net" ];
          autoStart = true;
          dependsOn = [ "ollama" ];
        };
      };
    };
  };

  #==== Systemd ====
  systemd.services = {
    nvidia-cdi-generate = {
      description = "Generate NVIDIA CDI config";
      before = [ "docker-ollama.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStartPre = pkgs.writeShellScript "wait-nvidia" ''
          until [ -e /dev/nvidia0 ]; do
            sleep 1
          done
        '';
        ExecStart = pkgs.writeShellScript "nvidia-cdi-generate" ''
          mkdir -p /etc/cdi
          ${pkgs.nvidia-container-toolkit}/bin/nvidia-ctk cdi generate \
            --output=/etc/cdi/nvidia.yaml \
            --mode=csv \
            --nvidia-ctk-path=${pkgs.nvidia-container-toolkit}/bin/nvidia-ctk \
            --ldconfig-path=${pkgs.glibc.bin}/bin/ldconfig
        '';
      };
    };

    docker-ollama-net = {
      description = "Create ollama docker network";
      after = [ "docker.service" ];
      wants = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "create-ollama-net" ''
          ${pkgs.docker}/bin/docker network create ollama-net 2>/dev/null || true
        '';
      };
    };

    docker-ollama = {
      after = [
        "docker-ollama-net.service"
        "nvidia-cdi-generate.service"
      ];
      requires = [
        "docker-ollama-net.service"
        "nvidia-cdi-generate.service"
      ];
    };

    ollama-pull = {
      description = "Pull Ollama models";
      after = [
        "docker-ollama.service"
        "docker-ollama-net.service"
      ];
      requires = [
        "docker-ollama.service"
        "docker-ollama-net.service"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStartPre = ollamaWait;
        ExecStart = pkgs.writeShellScript "ollama-pull" ''
          ${pkgs.docker}/bin/docker exec ollama ollama pull qwen2.5-coder:14b-instruct-q5_K_M
          ${pkgs.docker}/bin/docker exec ollama ollama pull qwen2.5-coder:7b-instruct-q5_K_M
          ${pkgs.docker}/bin/docker exec ollama ollama pull qwen2.5-coder:3b-instruct-q5_K_M
          ${pkgs.docker}/bin/docker exec ollama ollama pull nomic-embed-text
          ${pkgs.docker}/bin/docker exec ollama ollama pull booktrail/gemma3_tools:12b-it-qat
        '';
      };
    };

    ollama-preload = {
      description = "Preload Ollama model into VRAM";
      after = [ "ollama-pull.service" ];
      requires = [ "ollama-pull.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStartPre = ollamaWait;
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
    nvidia-container-toolkit
  ];
}
