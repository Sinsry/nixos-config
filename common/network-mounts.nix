let
  nas = "192.168.1.2";

  smbOptions = [
    "rw"
    "soft"
    "echo_interval=1"
    "x-systemd.mount-timeout=1s"
    "noauto"
    "x-systemd.automount" # Le serveur sera content (réveil au ls)
    "guest"
    "x-gvfs-show"
    "uid=1000"
    "gid=100"
    "noserverino" # Vital pour Dolphin
    "nounix" # Vital pour Dolphin
    "vers=3.1.1"
  ];

  mkSmbMount = share: {
    device = "//${nas}/${share}";
    fsType = "cifs";
    options = smbOptions;
  };

  mounts = [
    "Data"
    "Torrents"
  ];
in
{
  fileSystems = builtins.listToAttrs (
    map (m: {
      name = "/mnt/${m}";
      value = mkSmbMount m;
    }) mounts
  );
}
