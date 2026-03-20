let
  nas = "192.168.1.2";

  nfsOptions = [
    "rw"
    "_netdev"
    "nfsvers=3"
    "x-systemd.automount"
    "x-systemd.mount-timeout=2s"
    "timeo=14"
    "lookupcache=none"
    "retrans=2"
    "soft"
    "nolock"
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
