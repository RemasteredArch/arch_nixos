{ nixos-raspberrypi, ... }:
{
    imports = with nixos-raspberrypi.nixosModules; [
        raspberry-pi-5.base
        raspberry-pi-5.page-size-16k # Performance fixes, allegedly.
    ];
}
