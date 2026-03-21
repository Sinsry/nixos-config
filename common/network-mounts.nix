let
  nas = "192.168.1.2";

  smbOptions = [
    "rw"
    "soft"
    "echo_interval=1"
    "x-systemd.mount-timeout=1s"
    "noauto"
    "x-systemd.automount" # Le déclencheur (pour le serveur)
    "user" # Le sésame pour Dolphin (pour la corbeille)
    "exec" # Autorise l'exécution (aide le CLI)
    "guest"
    "uid=1000"
    "gid=100"
    "noserverino" # INDISPENSABLE pour la corbeille
    "nounix"
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
