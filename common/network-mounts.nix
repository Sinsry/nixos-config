let
  nas = "192.168.1.2";

  smbOptions = [
    "rw"
    "guest"
    "uid=1000"
    "gid=100"
    "x-systemd.automount"
    "noauto"
    "x-systemd.device-timeout=5s"
    "x-systemd.mount-timeout=5s"
    "_netdev"
    "noatime"
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
