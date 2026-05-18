args@{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:

{
    imports = [
        ./disko.nix
        ./networking.nix
        ../loaner-laptop/default.nix
        ./hibernation.nix
        ./gnome.nix
        ./hardware-configuration.nix
    ];

    services.laptop.networking = {
        enable = true;
        configureUsbEthernet = false;
    };

    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };

    boot.plymouth = {
        enable = true;
        theme = "blahaj";
        themePackages = with pkgs; [ plymouth-blahaj-theme ];
    };

    time.timeZone = "America/Los_Angeles";
    i18n.defaultLocale = "en_US.UTF-8";
    services.xserver.xkb.layout = "us";

    # Use zswap, an alternative to zram that caches and compresses swap from disk, rather than
    # compressing memory to an in-memory block device.
    #
    # Explanatory:
    #
    # - <https://search.nixos.org/options?channel=unstable&query=zswap>
    # - <https://wiki.nixos.org/wiki/Swap#Zswap_swap_cache>
    # - <https://docs.kernel.org/admin-guide/mm/zswap.html>
    # - <https://wiki.archlinux.org/title/Zswap>
    #
    # Opinionated:
    #
    # - <https://linuxblog.io/zswap-better-than-zram/>
    # - <https://www.theregister.com/2026/03/13/zram_vs_zswap/>
    boot.zswap.enable = true;

    # Configure GNOME.
    services.laptop.gnome.enable = true;
    # Configure more graphical things.
    services.arch-home-manager.desktop = true;
}
