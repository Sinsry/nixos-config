let
  nas = "192.168.1.2";

  smbOptions = [
    "rw"
    "soft"
    "echo_interval=1"
    "x-systemd.mount-timeout=1s"
    "noauto"
    "x-systemd.automount"
    "x-systemd.idle-timeout=0"
    # --- LE LIANT UNIVERSEL ---
    "user" # Autorise Dolphin à "posséder" le point de montage
    "exec" # Permet aux scripts de s'exécuter (essentiel pour le CLI)
    "dev" # Permet l'interprétation des périphériques
    "suid" # Garde les droits nécessaires pour l'automount
    # --------------------------
    "guest"
    "uid=1000"
    "gid=100"
    "noserverino" # UNIQUE SOLUTION pour la corbeille (Inodes stables)
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
