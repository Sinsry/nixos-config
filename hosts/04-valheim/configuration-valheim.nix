# vCore : 4/8 / Ram : 4/8 Gio / Disk : 256 G

{
  pkgs,
  # lib,
  config,
  ...
}:
let
  nbhost = "04";
  host = "valheim";
  user = "sinsry";
in
{
  imports = [
    ./hardware-configuration.nix
    ../../common/common-base.nix
  ];

  #==== Identité ====
  networking = {
    hostName = "${host}";
    interfaces.eth0 = {
      ipv4.addresses = [
        {
          address = "192.168.1.5";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = "192.168.1.254";
    nameservers = [ "192.168.1.254" ];
  };

  #==== Clavier ====
  console.keyMap = "us";

  #==== Utilisateurs ====
  users.users.${user} = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEHIB9gJxYTUgrC25g6iRw5L1CBzBnpkigigJzHbKb8B"
    ];
    extraGroups = [
      "docker"
    ];
  };

  #==== Sops ====
  sops.age.sshKeyPaths = [ "/home/${user}/.ssh/id_ed25519" ];
  sops.defaultSopsFile = ./asset/secrets.yaml;

  sops.secrets.SERVER_PASS = { };
  sops.secrets.ADMINLIST_IDS = { };

  sops.templates."valheim-env" = {
    content = ''
      SERVER_PASS=${config.sops.placeholder.SERVER_PASS}
      ADMINLIST_IDS=${config.sops.placeholder.ADMINLIST_IDS}
    '';
  };

  #==== Services ====
  services = {
    openssh.enable = true;
    qemuGuest.enable = true;
  };

  #==== Virtualisation ====
  virtualisation = {
    docker = {
      enable = true;
    };
    oci-containers = {
      backend = "docker";
      containers.valheim-server = {
        image = "ghcr.io/lloesche/valheim-server:latest";
        ports = [
          "2456-2458:2456-2458/udp"
        ];
        volumes = [
          "/home/sinsry/valheim-server/config:/config"
          "/home/sinsry/valheim-server/data:/opt/valheim"
        ];
        environment = {
          SERVER_NAME = "AperosBros";
          WORLD_NAME = "AperosBros";
        };
        environmentFiles = [
          config.sops.templates."valheim-env".path
        ];
        extraOptions = [
          "--cap-add=sys_nice"
          "--stop-timeout=120"
        ];
        autoStart = true;
      };
    };
  };

  #==== Système ====
  system.activationScripts.fastfetch = ''
    mkdir -p /home/${user}/.config/fastfetch
    chown -R ${user}:users /home/${user}/.config
    ln -sfn /etc/nixos/hosts/${nbhost}-${host}/asset/fastfetch/config.jsonc /home/${user}/.config/fastfetch/config.jsonc
    ln -sfn /etc/nixos/hosts/${nbhost}-${host}/asset/fastfetch/date.sh /home/${user}/.config/fastfetch/date.sh
  '';

  #==== Swap ====
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024;
    }
  ];

  #==== Paquets spécifiques ====
  environment = {
    systemPackages = with pkgs; [
      btop
    ];
  };
}
