{ nixos-raspberrypi, ... }:
{
    imports = with nixos-raspberrypi.nixosModules.raspberry-pi-5; [
        base
        page-size-16k # Performance fixes, allegedly.
    ];

    # Recommended for new installations.
    boot.loader.raspberry-pi.bootloader = "kernel";

    hardware.raspberry-pi.config.all.base-dt-params = {
        # Assumes that your PSU is genuinely able to deliver 5 amps, despite what the Pi detects. Be
        # careful with this!
        PSU_MAX_CURRENT = {
            enable = true;
            value = 5000;
        };
    };
}
