let
  nas = "pve";

  smbOptions = [
    "rw"
    "guest"
    "uid=1000"
    "gid=100"
    "noserverino"
    "noauto"
    "x-systemd.automount"
    "x-systemd.device-timeout=5s"
    "x-systemd.mount-timeout=5s"
    "_netdev"
    "noatime"
    "actimeo=0"
    "cache=none"
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
