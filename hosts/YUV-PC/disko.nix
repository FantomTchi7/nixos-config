let
  # Set this from `ls -l /dev/disk/by-id` before running disko.
  disk = "/dev/disk/by-id/nvme-REPLACE_ME";

  btrfsOpts = [
    "compress=zstd:1"
    "noatime"
  ];
in
{
  disko.devices.disk.main = {
    type = "disk";
    device = disk;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "@" = {
                mountpoint = "/";
                mountOptions = btrfsOpts;
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = btrfsOpts;
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = btrfsOpts;
              };
              "@log" = {
                mountpoint = "/var/log";
                mountOptions = btrfsOpts;
              };
            };
          };
        };
      };
    };
  };
}
