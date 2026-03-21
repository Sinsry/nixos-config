let
  nas = "192.168.1.2";

  smbOptions = [
    "rw"
    "soft"
    "retrans=2"
    "echo_interval=1"
    "nolock"
    "_netdev"
    "x-systemd.automount"
    "x-systemd.mount-timeout=1s"
    # Options obligatoires pour que SMB fonctionne comme NFS (UID/GID/Inodes)
    "guest"
    "uid=1000"
    "gid=100"
    "noserverino"
    "dir_mode=0777"
    "file_mode=0777"
    "nounix"
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
