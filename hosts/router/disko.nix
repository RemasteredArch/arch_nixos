{ ... }:
{
    disko.devices.disk.sdCard = {
        type = "disk";
        device = "/dev/mmcblk0";
        content = {
            type = "gpt";
            partitions = {
                FIRMWARE = {
                    label = "FIRMWARE";
                    priority = 1;

                    type = "0700"; # Microsoft basic data.
                    attributes = [
                        0 # Required partition.
                    ];

                    size = "1GiB";
                    content = {
                        type = "filesystem";
                        mountpoint = "/boot/firmware";
                        format = "vfat";
                        mountOptions = [
                            "noatime"
                            "noauto"
                            "x-systemd.automount"
                            "x-systemd.idle-timeout=1min"
                        ];
                    };
                };
                ESP = {
                    label = "ESP";

                    type = "EF00"; # EFI System Partition (ESP).
                    attributes = [
                        2 # Legacy BIOS Bootable, for U-Boot to find extlinux config.
                    ];

                    size = "1GiB";
                    content = {
                        type = "filesystem";
                        format = "vfat";
                        mountpoint = "/boot";
                        mountOptions = [
                            "noatime"
                            "noauto"
                            "x-systemd.automount"
                            "x-systemd.idle-timeout=1min"
                            "umask=0077"
                        ];
                    };
                };
                NIXOS = {
                    label = "NIXOS";

                    size = "100%";
                    content = {
                        type = "filesystem";
                        format = "ext4";
                        mountpoint = "/";
                    };
                };
            };
        };
    };
}
