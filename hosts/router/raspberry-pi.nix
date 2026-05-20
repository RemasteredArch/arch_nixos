{ nixos-raspberrypi, ... }:
{
    imports = with nixos-raspberrypi.nixosModules.raspberry-pi-5; [
        base
        page-size-16k # Performance fixes, allegedly.
    ];

    # Recommended for new installations.
    boot.loader.raspberry-pi.bootloader = "kernel";

    hardware.raspberry-pi.dt-param = {
        # Assumes that your PSU is genuinely able to deliver 5 amps, despite what the Pi detects. Be
        # careful with this!
        PSU_MAX_CURRENT = 5000;
    };
}
