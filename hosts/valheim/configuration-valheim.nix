# Configuration spécifique à travail
# Hardware : VM dédié à valheim
# vCore : 4/8 / Ram : 4/8 Gio / Disk : 50 G

{
  pkgs,
  # lib,
  config,
  ...
}:
let
  host = "valheim";
  user = "sinsry";
in
{
  imports = [
    ./hardware-configuration.nix
    ../../common/common-base.nix
  ];

  #==== Identité ====
  networking.hostName = "${host}";

  #==== Paquets spécifiques ====
  environment = {
    systemPackages = with pkgs; [
      btop
    ];
  };

  #==== Clavier ====
  console.keyMap = "us";

  services = {
    openssh.enable = true;
  };

  age.secrets.valheim-env = {
    file = ./asset/valheim-env.age;
  };

  virtualisation = {
    docker.enable = true;
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
          SERVER_NAME = "AperoBros";
          WORLD_NAME = "AperosBros";
        };
        environmentFiles = [
          config.age.secrets.valheim-env.path
        ];

        extraOptions = [
          "--cap-add=sys_nice"
          "--stop-timeout=120"
        ];
        autoStart = true;
      };
    };
  };

  system.activationScripts.fastfetch = ''
    mkdir -p /home/${user}/.config/fastfetch
    chown -R ${user}:users /home/${user}/.config
    ln -sfn /etc/nixos/hosts/${host}/asset/fastfetch/config.jsonc /home/${user}/.config/fastfetch/config.jsonc
    ln -sfn /etc/nixos/hosts/${host}/asset/fastfetch/date.sh /home/${user}/.config/fastfetch/date.sh
  '';
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024;
    }
  ];
}
