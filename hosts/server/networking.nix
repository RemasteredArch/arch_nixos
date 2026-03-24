
{ config, lib, pkgs, ... }:

{
  systemd.network.links."10-ethernet" = {
    matchConfig.PermanentMACAddress = "9c:6b:00:19:a3:a7";
    linkConfig.Name = "eth";
  };

  networking = {
    hostName = "arch-server"; # Define your hostname.

    # Open ports in the firewall.
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [];
    };

    # IPv6 is a myth invented by big IANA to scare you into using DHCP!
    enableIPv6 = false;
    useDHCP = false;

    interfaces.eth = {
      ipv4.addresses = [{
        address = "192.168.68.212";
        prefixLength = 22;
      }];
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
