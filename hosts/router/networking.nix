{
    config,
    lib,
    nixpkgs,
    ...
}:

{
    systemd.network.links = {
        "10-on-board-ethernet" = {
            matchConfig.PermanentMACAddress = "2c:cf:67:50:3d:bb";
            linkConfig.Name = "ob-eth";
        };
        "15-on-board-wifi" = {
            matchConfig.PermanentMACAddress = "ea:25:82:be:7e:b3";
            linkConfig.Name = "ob-wlan";
        };
    };

    # Provides multicast DNS and DNS service discovery. Requires UDP port 5353 to be open.
    services.avahi.enable = true;

    networking = {
        hostName = "router";

        firewall = {
            enable = true;
            allowedTCPPorts = [
                22 # Used by OpenSSH.
            ];
            allowedUDPPorts = [
                9 # Used for Wake on LAN.
                5353 # Used by Avahi for mDNS/DNS-SD.
            ];
        };

        # IPv6 is a myth invented by big IANA to scare you into using DHCP!
        enableIPv6 = false;

        useDHCP = true;

        interfaces.ob-eth = {
            useDHCP = true;

            ipv4.addresses = [
                {
                    address = "192.168.68.209";
                    prefixLength = 22;
                }
            ];

            wakeOnLan.enable = true;
        };

        hosts = {
            "192.168.68.210" = [ "arch-laptop" ];
            "192.168.68.211" = [ "arch-pc" ];
        };

        nftables = {
            # Keep things declarative.
            flushRuleset = true;
        };
    };
}
