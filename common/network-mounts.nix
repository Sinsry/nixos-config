let
  nas = "192.168.1.2";

  nfsOptions = [
    "_netdev"
    "v4"
    "x-systemd.automount"
    "x-systemd.mount-timeout=1s"
    "timeo=14"
    "retrans=2"
    "nolock"
    "soft"
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
