# Montages disques — travail
# Partition Windows uniquement

{
  fileSystems = {
    "/mnt/Windows" = {
      device = "/dev/disk/by-uuid/90D0538CD0537804";
      fsType = "ntfs";
      options = [
        "nofail"
        "noperm"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /mnt/Windows 0755 root root -"
  ];
}
