# vCore : 4/8 / Ram : 4/8 Gio / Disk : 256 G
{
  pkgs,
  config,
  ...
}:
let
  # nbhost = "03";
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

  #==== Boot spécifique ====
  boot.blacklistedKernelModules = [ "nouveau" ];

  #==== Clavier ====
  console.keyMap = "us";

  #==== Matériel ====
  hardware = {
    nvidia = {
      open = true;
      modesetting.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    # nvidia-container-toolkit.enable = true; # nvidia dans docker
    graphics.enable = true;
  };

  #==== Utilisateurs ====
  users.users.${user} = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEHIB9gJxYTUgrC25g6iRw5L1CBzBnpkigigJzHbKb8B"
    ];
    extraGroups = [ "docker" ];
  };

  #==== Sécurité ====
  security.acme = {
    acceptTerms = true;
    defaults.email = "yiramas@gmail.com";
  };

  security.acme.certs."aperosbros.net" = {
    extraDomainNames = [ "ollama.aperosbros.net" ];
    dnsProvider = "cloudflare";
    credentialsFile = config.sops.secrets.cloudflare-api-token.path;
    group = "nginx";
  };

  #==== Sops ====
  sops.age.sshKeyPaths = [ "/home/${user}/.ssh/id_ed25519" ];
  sops.defaultSopsFile = ./asset/secrets.yaml;

  sops.secrets.transmission-rpc-username = { };
  sops.secrets.transmission-rpc-password = { };
  sops.secrets.cloudflare-api-token = { };
  sops.secrets.ollama-token = { };

  sops.templates."transmission-credentials.json" = {
    content = ''
      {
        "rpc-username": "${config.sops.placeholder.transmission-rpc-username}",
        "rpc-password": "${config.sops.placeholder.transmission-rpc-password}"
      }
    '';
    owner = "transmission";
  };

  sops.templates."nginx-ollama-token.conf" = {
    content = ''
      map $http_authorization $auth_ok {
        "Bearer ${config.sops.placeholder.ollama-token}" 1;
        default 0;
      }
    '';
    owner = "nginx";
  };

  #==== Services ====
  services = {
    openssh.enable = true;
    xserver.videoDrivers = [ "nvidia" ];
    qemuGuest.enable = true;
    ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      host = "127.0.0.1";
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

    nginx = {
      enable = true;
      mapHashBucketSize = 128;
      commonHttpConfig = ''
        include ${config.sops.templates."nginx-ollama-token.conf".path};
      '';
      virtualHosts."aperosbros.net" = {
        forceSSL = true;
        useACMEHost = "aperosbros.net";
        root = "/var/www/aperosbros";
        locations."/" = {
          tryFiles = "$uri $uri/ /index.html";
        };
      };
      virtualHosts."opnsense.aperosbros.net" = {
        forceSSL = true;
        useACMEHost = "aperosbros.net";
        locations."/" = {
          proxyPass = "https://192.168.1.254:8443";
          extraConfig = ''
            proxy_ssl_verify off;
            proxy_ssl_server_name on;
            proxy_read_timeout 60s;
            proxy_connect_timeout 60s;
            proxy_set_header Host 192.168.1.254:8443;
            proxy_set_header X-Real-IP $remote_addr;
          '';
        };
      };
      virtualHosts."ollama.aperosbros.net" = {
        forceSSL = true;
        useACMEHost = "aperosbros.net";
        listen = [
          {
            addr = "0.0.0.0";
            port = 11435;
            ssl = true;
          }
        ];
        locations."/" = {
          proxyPass = "http://127.0.0.1:11434";
          extraConfig = ''
            if ($auth_ok != 1) {
              return 401;
            }
            proxy_read_timeout 300s;
            proxy_connect_timeout 300s;
          '';
        };
      };
    };

    transmission = {
      enable = true;
      credentialsFile = config.sops.templates."transmission-credentials.json".path;
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

  #==== Virtualisation ====
  virtualisation = {
    docker.enable = true;
  };

  #==== Systemd ====
  systemd.tmpfiles.rules = [
    "d /var/www/aperosbros 0755 nginx nginx -"
  ];

  systemd.services = {
    ollama-preload = {
      description = "Preload Ollama model into VRAM";
      after = [ "ollama.service" ];
      requires = [ "ollama.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStartPre = pkgs.writeShellScript "ollama-wait" ''
          until ${pkgs.curl}/bin/curl -s http://localhost:11434 > /dev/null 2>&1; do
            sleep 1
          done
        '';
        ExecStart = pkgs.writeShellScript "ollama-preload" ''
          ${pkgs.curl}/bin/curl -s http://localhost:11434/api/generate \
            -d '{"model": "qwen2.5-coder-3b", "prompt": ""}'
          ${pkgs.curl}/bin/curl -s http://localhost:11434/api/generate \
            -d '{"model": "qwen2.5-coder-7b", "prompt": ""}'
        '';
      };
    };
  };

  #==== Système ====
  system = {
    activationScripts.fastfetch = ''
      mkdir -p /home/${user}/.config/fastfetch
      chown ${user}:users /home/${user}/.config/fastfetch
      ln -sfn /etc/nixos/asset/fastfetch.jsonc /home/${user}/.config/fastfetch/config.jsonc
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
