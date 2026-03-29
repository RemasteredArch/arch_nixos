
{ config, lib, pkgs, ... }:

{
  systemd.network.links."10-ethernet" = {
    matchConfig.PermanentMACAddress = "9c:6b:00:19:a3:a7";
    linkConfig.Name = "eth";
  };

  # Provides multicast DNS and DNS service discovery. Requires UDP port 5353 to be open.
  services.avahi.enable = true;

  networking = {
    hostName = "arch-server";

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # Used by OpenSSH.
      ];
      allowedUDPPorts = [
        9    # Used for Wake on LAN.
        5353 # Used by Avahi for mDNS/DNS-SD.
      ];
    };

    # IPv6 is a myth invented by big IANA to scare you into using DHCP!
    enableIPv6 = false;
    useDHCP = false;

    interfaces.eth = {
      ipv4.addresses = [{
        address = "192.168.68.212";
        prefixLength = 22;
      }];

      wakeOnLan.enable = true;
    };

    nameservers = ["75.75.75.75" "76.76.76.76"];

    defaultGateway = {
      address = "192.168.68.1";
      interface = "eth";
    };

    hosts = {
      "192.168.68.210" = ["arch-laptop"];
      "192.168.68.211" = ["arch-pc"];
    };
  };
}
