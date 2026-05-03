{
    inputs,
    ...
}:
let
    # Must be large enough to fit system memory for hibernation.
    #
    # This laptop has 16 GiB of RAM, so 18 GiB seems like a safe buffer.
    swapSize = "18G";
in
{
    imports = [ inputs.disko.nixosModules.disko ];

    disko.devices.disk.boot = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
            type = "gpt";
            partitions = {
                ESP = {
                    label = "ESP";

                    type = "EF00";
                    size = "500M";
                    content = {
                        type = "filesystem";
                        format = "vfat";
                        mountpoint = "/boot";
                        mountOptions = [ "umask=0077" ];
                    };
                };
                NIXOS = {
                    label = "NIXOS";

                    end = "-${swapSize}";
                    content = {
                        type = "filesystem";
                        format = "ext4";
                        mountpoint = "/";
                    };
                };
                SWAP = {
                    label = "SWAP";

                    size = "100%";
                    content = {
                        type = "swap";
                        # Seems to be the default behavior for general Linux, but it's enabled in
                        # the example and does at least have an effect on encryption (which I'm not
                        # using), so I'll enable it.
                        discardPolicy = "both";
                        # Resume from hibernation with this swap.
                        resumeDevice = true;
                    };
                };
            };
        };
    };
}
