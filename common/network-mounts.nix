let
  nas = "192.168.1.2";

  nfsOptions = [
    "rw"
    "_netdev"
    "nfsvers=4.2"
    "x-systemd.automount"
    "x-systemd.mount-timeout=10"
    "timeo=14"
    "retrans=2"
    "soft"
    "nolock"
    "noatime"
  ];

  mkNfsMount = share: {
    device = "${nas}:/NAS/${share}";
    fsType = "nfs";
    options = nfsOptions;
  };

  mounts = [
    "Data"
    "Torrents"
  ];
in
{
  systemd.tmpfiles.rules = map (m: "d /mnt/${m} 0755 root root -") mounts;

  fileSystems = builtins.listToAttrs (
    map (m: {
      name = "/mnt/${m}";
      value = mkNfsMount m;
    }) mounts
  );
}
