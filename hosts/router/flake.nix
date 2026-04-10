{
    description = "A NixOS-based router configuration for a Raspberry Pi 5.";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
        nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
        disko = {
            url = "github:nix-community/disko";
            inputs.nixpkgs.follows = "nixos-raspberrypi/nixpkgs";
        };
    };

    nixConfig = {
        extra-substituters = [
            "https://nixos-raspberrypi.cachix.org"
        ];
        extra-trusted-public-keys = [
            "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
        ];
    };

    outputs =
        inputs@{
            self,
            nixpkgs,
            nixos-raspberrypi,
            disko,
            ...
        }:
        {
            nixosConfigurations.router = nixos-raspberrypi.lib.nixosSystem {
                specialArgs = inputs;
                modules = [
                    ./raspberry-pi.nix
                    ./disko.nix
                    ./configuration.nix
                ];
            };
        };
}
