# Configuration spécifique à travail
# Hardware : VM dédié à valheim
# vCore : 4/8 / Ram : 4/8 Gio / Disk : 50 G

{
  pkgs,
  # lib,
  # config,
  ...
}:
let
  host = "test_script";
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
    # interfaces.eth0 = {
    #   ipv4.addresses = [
    #     {
    #       address = "192.168.1.5";
    #       prefixLength = 24;
    #     }
    #   ];
    # };
    # defaultGateway = "192.168.1.254";
    # nameservers = [ "192.168.1.254" ];
  };

  users.users.${user} = {
    extraGroups = [
      "docker"
    ];
  };

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
    qemuGuest.enable = true;
  };

  # age.secrets.test_script-env = {
  #   file = ./asset/test_script-env.age;
  # };

  age.identityPaths = [ "/home/${user}/.ssh/id_ed25519" ];

  virtualisation = {
    docker = {
      enable = true;
    };
    oci-containers = {
      backend = "docker";
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
