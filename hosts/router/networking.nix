{
    config,
    pkgs,
    lib,
    ...
}:

let
    cfg = config.services.networking;
    internalIf = "add-eth";
    internalIp = "192.168.68.208";
    externalIf = "ob-eth";
    externalIp = "192.168.68.209";

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
        dhcpServer = lib.mkOption {
            type = lib.types.bool;
            description = ''
                Whether this device should be the authoritative DHCP server on the internal network.
                Allocates addresses 192.168.68.2 through 192.168.68.199.

                This does nothing if {option}`services.networking.nat` is false.
            '';
            default = cfg.nat;
        };
        dnsServer = lib.mkOption {
            type = lib.types.bool;
            description = ''
                Whether this device should be a DNS server on the internal network.
            '';
            default = true;
        };
    };

    config = {
        assertions = [
            {
                assertion = cfg.dhcpServer -> cfg.nat;
                message = "DHCP server functionality may only be enabled alongside NAT routing";
            }
        ];

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

        boot.kernel.sysctl = {
            "net.ipv4.conf.all.arp_filter" = true;
        };

        networking = {
            hostName = "arch-router";

            # IPv6 is a myth invented by big IANA to scare you into using DHCP!
            enableIPv6 = false;

            useDHCP = true;

            interfaces.${externalIf} = {
                useDHCP = true;

                ipv4.addresses = [
                    {
                        address = externalIp;
                        prefixLength = 22;
                    }
                ];

                wakeOnLan.enable = true;
            };

            interfaces.${internalIf} = {
                useDHCP = true;

                ipv4.addresses = [
                    {
                        address = internalIp;
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
                externalInterface = externalIf;
                internalInterfaces = [ internalIf ];
            };

            # No open ports by default, only open ports on internal interfaces.
            firewall =
                let
                    opt = lib.lists.optional;
                in
                {
                    enable = true;

                    allowedTCPPorts = [
                        22 # Used by OpenSSH.
                    ]
                    ++ opt cfg.dnsServer 53;
                    allowedUDPPorts = [
                        9 # Used for Wake on LAN.
                        5353 # Used by Avahi for mDNS/DNS-SD.
                    ]
                    ++ opt cfg.dhcpServer 67
                    ++ opt cfg.dnsServer 53;
                };

            nftables = {
                enable = true;
                # Keep things declarative.
                flushRuleset = true;
            };
        };

        # Provides DHCP and DNS, if requested to do so.
        services.dnsmasq = {
            enable = cfg.dhcpServer || cfg.dnsServer;
            # Every long-form CLI option of dnsmasq, without the proceeding `--`.
            settings = {
                # The network interface to serve on.
                interface = internalIf;
                # Only serve on the specified network interface.
                bind-interfaces = true;

                # Act as the authoritative (i.e., only) DHCP server on the network.
                dhcp-authoritative = true;
                # Ranges of IP addresses to allocate. An empty list disables dnsmasq's DHCP server.
                dhcp-range = lib.lists.optionals cfg.dhcpServer [
                    # Allocate 192.168.68.2 through 192.168.68.199 with default lease length.
                    "192.168.68.2,192.168.68.199"
                ];
                # A full list of named options can be found with `dnsmasq --help dhcp`.
                dhcp-option = [
                    "option:router,${internalIp}"
                    "option:dns-server,${internalIp}"
                ];

                # Setting the port to 0 disables dnsmasq's DNS server.
                port = lib.mkIf (!cfg.dnsServer) 0;
                # Use the dnscrypt-proxy instance as the upstream, which will encrypt requests.
                server = [ "127.0.0.1#5354" ];
                # Only use the statically configured DNS servers, don't read from
                # `/etc/resolve.conf`.
                no-resolv = true;
                # Don't forward plain names to the upstream servers. I.e., do forward `nixos.org`,
                # but do not forward `nixos`.
                domain-needed = true;
                # Don't forward reverse lookups for IP addresses in private IP ranges
                # (192.168.0.0/16, 10.0.0.0/8, etc.)
                bogus-priv = true;

                dnssec = true;
                trust-anchor =
                    let
                        # Digests from the store, generated by `unbound-anchor`.
                        digests = builtins.readFile "${pkgs.dns-root-data}/root.ds";
                        # Split a string along newlines and filter out empty lines.
                        splitLines =
                            str: builtins.filter (f: builtins.stringLength f != 0) (lib.strings.splitString "\n" str);
                        # Split a string along spaces.
                        splitSpace = lib.strings.splitString " ";
                        # Zip together two lists into an attribute set, using elements from the
                        # first as the names for the corresponding values in the second.
                        #
                        # E.g., `nameValues [ "a", "b" ] [ 1, 2 ]` returns `{ a = 1; b = 2; }`.
                        nameValues =
                            names: values:
                            lib.attrsets.mergeAttrsList (
                                lib.lists.zipListsWith (name: val: {
                                    ${name} = val;
                                }) names values
                            );
                        # E.g., `. IN DS 20326 8 2 E06D44` becomes
                        # `{ zone = "."; resourceRecordType = "IN"; ...; digest = "E06D44" }`.
                        parseDigest =
                            line:
                            nameValues [
                                "zone"
                                "resourceRecordClass"
                                "resourceRecordType"
                                "keyTag"
                                "algorithm"
                                "digestType"
                                "digest"
                            ] (splitSpace line);
                        # Validate that the given digest is actually an Internet delegation signer
                        # resource record.
                        validateDigest =
                            digest:
                            assert lib.asserts.assertMsg (
                                digest.resourceRecordClass == "IN"
                            ) "expected only Internet resource records";
                            assert lib.asserts.assertMsg (
                                digest.resourceRecordType == "DS"
                            ) "expected only delegation signer resource records";
                            digest;
                        # Convert a digest from `parseLine` into a string appropriate for dnsmasq's
                        # `trust-anchor` option.
                        toTrustAnchorStr =
                            digest: "${digest.zone},${digest.keyTag},${digest.algorithm},${digest.digestType},${digest.digest}";
                    in
                    # For example:
                    #
                    # ```
                    # . IN DS 20326 8 2 E06D44B80B8F1D39A95C0B0D7C65D08458E880409BBC683457104237C7F8EC8D
                    # . IN DS 38696 8 2 683D2D0ACB8C9B712A1948B27F741219298D0A450D612C483AF444A4C0FB2B16
                    # ```
                    #
                    # Turns it into this:
                    #
                    # ```nix
                    # [
                    #     ".,20326,8,2,E06D44B80B8F1D39A95C0B0D7C65D08458E880409BBC683457104237C7F8EC8D"
                    #     ".,38696,8,2,683D2D0ACB8C9B712A1948B27F741219298D0A450D612C483AF444A4C0FB2B16"
                    # ]
                    # ```
                    map (line: toTrustAnchorStr (validateDigest (parseDigest line))) (splitLines digests);
            };
        };

        services.dnscrypt-proxy = {
            enable = cfg.dnsServer;
            settings = {
                # Use Cloudflare DNS.
                server_names = [ "cloudflare" ];

                # Traditional DNS providers used to fetch the list of encrypted providers.
                bootstrap_resolvers = [
                    "9.9.9.11:53"
                    "1.1.1.1:53"
                    "8.8.8.8:53"
                ];
                # Don't actually make request for IPv6 records.
                block_ipv6 = true;
                # Only use providers that support DNSSEC.
                require_dnssec = true;

                # Listen privately and on an unusual port --- it's dnsmasq's responsibility to
                # handle queries, dnscrypt-proxy just encrypts queries headed upstream.
                listen_addresses = [ "127.0.0.1:5354" ];
            };
        };
    };
}
