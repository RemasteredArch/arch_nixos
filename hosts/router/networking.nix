{
    config,
    lib,
    ...
}:

let
    cfg = config.services.networking;
in
{
    options.services.networking = {
        nat = lib.mkOption {
            type = lib.types.bool;
            description = ''
                Whether or not this device should actually act as a NAT router.
                Disabling this defeats the purpose of `router` being a router,
                reducing it to just being a device on the network.
            '';
            default = true;
        };
    };

    config = {
        systemd.network.links = {
            "10-on-board-ethernet" = {
                matchConfig.PermanentMACAddress = "2c:cf:67:50:3d:bb";
                linkConfig.Name = "ob-eth";
            };
            "11-add-on-ethernet" = {
                matchConfig.PermanentMACAddress = "00:e0:4c:00:11:53";
                linkConfig.Name = "add-eth";
            };
            "12-usb-ethernet" = {
                matchConfig.PermanentMACAddress = "0c:37:96:77:8c:32";
                linkConfig.Name = "usb-eth";
            };
            "15-on-board-wifi" = {
                matchConfig.PermanentMACAddress = "ea:25:82:be:7e:b3";
                linkConfig.Name = "ob-wlan";
            };
        };

        # Provides multicast DNS and DNS service discovery. Requires UDP port 5353 to be open.
        services.avahi.enable = true;

        networking = {
            hostName = "arch-router";

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

            interfaces.add-eth = {
                useDHCP = true;

                ipv4.addresses = [
                    {
                        address = "192.168.68.208";
                        prefixLength = 22;
                    }
                ];
            };

            hosts = {
                "192.168.68.210" = [ "arch-laptop" ];
                "192.168.68.211" = [ "arch-pc" ];
            };

            nat = {
                enable = cfg.nat;
                externalInterface = "ob-eth";
                internalInterfaces = [ "add-eth" ];
            };

            # No open ports by default, only open ports on internal interfaces.
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

            nftables = {
                enable = true;
                # Keep things declarative.
                flushRuleset = true;
            };
        };
    };
}
