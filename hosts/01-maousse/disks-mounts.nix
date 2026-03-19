{
  fileSystems = {
    "/mnt/Ventoy" = {
      device = "/dev/disk/by-uuid/4E21-0000";
      fsType = "exfat";
      options = [
        "nofail"
        "rw"
        "umask=0000"
        "uid=1000"
        "gid=100"
      ];
    };

    "/mnt/Windows" = {
      device = "/dev/disk/by-uuid/DA060B51060B2DD7";
      fsType = "ntfs";
      options = [
        "nofail"
        "noperm"
      ];
    };

    "/home/sinsry/Jeux" = {
      device = "/dev/disk/by-uuid/c5f40b61-d064-468c-932a-c3460bc762ed";
      fsType = "ext4";
      options = [
        "nofail"
      ];
    };
  };

  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  systemd.tmpfiles.rules = [
    "d /mnt/Ventoy          0755 root   root  -"
    "d /mnt/Windows         0755 root   root  -"
    "d /home/sinsry/Jeux    0755 sinsry users -"
  ];
}
