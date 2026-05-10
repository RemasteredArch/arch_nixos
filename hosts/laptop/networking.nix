{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:

let
    cfg = config.services.laptop.networking;
in
{
    options.services.laptop.networking = {
        enable = lib.mkEnableOption "Configures networking for `laptop`";
        configureUsbEthernet = lib.mkOption {
            type = lib.types.bool;
            description = ''
                Whether or not to configure the USB Ethernet dongle used for `laptop`,
                matched based on MAC address.
                This will cause ~100 seconds of delay during boot if the dongle ise not plugged in.
            '';
            default = false;
        };
    };

    config = lib.mkIf cfg.enable {
        systemd.network = {
            # enable = true;
            links = {
                "10-usb-ethernet" = lib.mkIf cfg.configureUsbEthernet {
                    matchConfig.PermanentMACAddress = "0c:37:96:77:8c:32";
                    linkConfig.Name = "usb-eth";
                };
                "15-on-board-wifi" = {
                    matchConfig.PermanentMACAddress = "a8:59:5f:f6:be:fe";
                    linkConfig.Name = "ob-wlan";
                };
            };
            networks."45-usb-ethernet" = lib.mkIf cfg.configureUsbEthernet {
                matchConfig.name = "usb-eth";
                linkConfig.RequiredForOnline = "no";
            };
        };

        # Provides multicast DNS and DNS service discovery. Requires UDP port 5353 to be open.
        services.avahi.enable = true;

        services.openssh = {
            enable = true;
            settings = {
                PermitRootLogin = "no";
                AllowUsers = [ "arch" ];
            };
        };

        services.fail2ban = {
            enable = true;
            ignoreIP = [ "arch-pc" ];
        };

        networking = {
            hostName = "arch-laptop";

            # IPv6 is a myth invented by big IANA to scare you into using DHCP!
            enableIPv6 = false;

            interfaces.usb-eth = lib.mkIf cfg.configureUsbEthernet {
                useDHCP = true;

                ipv4.addresses = [
                    {
                        address = "192.168.68.210";
                        prefixLength = 22;
                    }
                ];
            };

            hosts = {
                "192.168.68.209" = [ "arch-router" ];
                "192.168.68.211" = [ "arch-pc" ];
            };

            firewall = {
                enable = true;

                # Only allow inbound connections from an Ethernet connection.
                interfaces.usb-eth = lib.mkIf cfg.configureUsbEthernet {
                    allowedTCPPorts = [
                        22 # Used by OpenSSH.
                    ];
                    allowedUDPPorts = [
                        5353 # Used by Avahi for mDNS/DNS-SD.
                    ];
                };
            };
        };
    };
}
