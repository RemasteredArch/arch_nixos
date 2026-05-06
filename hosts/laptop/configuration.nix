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
        ../loaner-laptop/default.nix
        ./hibernation.nix
        ./hardware-configuration.nix
    ];

    networking.hostName = "laptop";

    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };

    boot.plymouth = {
        enable = true;
        theme = "blahaj";
        themePackages = with pkgs; [ plymouth-blahaj-theme ];
    };

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

    # Use GNOME.
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;
    programs.dconf.profiles.user.databases = [
        {
            settings = {
                "org/gnome/mutter" = {
                    experimental-features = [
                        "scale-monitor-framebuffer" # Fractional scaling
                        "variable-refresh-rate" # VRR (for compatible displays)
                        "xwayland-native-scaling" # Crisp scaling for Xwayland applications
                        "autoclose-xwayland" # Automatically close Xwayland if there are no clients
                    ];
                };
            };
        }
    ];

    # Configure more graphical things.
    services.arch-home-manager.desktop = true;
}
