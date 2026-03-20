let
  nas = "192.168.1.2";

  smbOptions = [
    "rw"
    "uid=1000" # Ton UID sur NixOS pour être maître des fichiers
    "gid=100" # Groupe users
    "credentials=/etc/nixos/smb-secrets"
    "x-systemd.automount"
    "noatime"
    "dir_mode=0777" # Pour être sûr que Dolphin puisse créer .trash
    "file_mode=0777"
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
