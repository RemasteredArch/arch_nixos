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
            linkConfig.Name = "eth";
        };
        "15-on-board-wifi" = {
            matchConfig.PermanentMACAddress = "ea:25:82:be:7e:b3";
            linkConfig.Name = "wwan";
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
        useDHCP = false;

        interfaces = {
            eth = {
                ipv4.addresses = [
                    {
                        address = "192.168.68.209";
                        prefixLength = 22;
                    }
                ];

                wakeOnLan.enable = true;
            };
            wwan = {
                useDHCP = true;
            };
        };

        # nameservers = [
        #     "75.75.75.75"
        #     "76.76.76.76"
        # ];
        #
        # defaultGateway = {
        #     address = "192.168.68.1";
        #     interface = "eth";
        # };

        hosts = {
            "192.168.68.210" = [ "arch-laptop" ];
            "192.168.68.211" = [ "arch-pc" ];
        };
    };
}
