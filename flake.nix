{
    description = "My NixOS configurations";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
        nixvim = {
            url = "github:nix-community/nixvim";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
        nixpkgs-rpi.follows = "nixos-raspberrypi/nixpkgs";
        disko-rpi = {
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
            nixos-wsl,
            nixvim,
            home-manager,

            nixos-raspberrypi,
            nixpkgs-rpi,
            disko-rpi,
        }:
        {
            nixosConfigurations.wsl = inputs.nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                specialArgs = { inherit inputs; };
                modules = [
                    ./hosts/loaner-laptop/default.nix

                    nixvim.nixosModules.nixvim
                    nixos-wsl.nixosModules.default
                    home-manager.nixosModules.home-manager
                    {
                        wsl = {
                            enable = true;
                            defaultUser = "arch";
                            # Explicitly register Windows executable binfmt support to avoid
                            # systemd's support breaking it.
                            interop.register = true;
                        };
                    }
                ];
            };

            nixosConfigurations.router = nixos-raspberrypi.lib.nixosSystem {
                specialArgs = {
                    inherit nixos-raspberrypi;
                    nixpkgs = nixpkgs-rpi;
                    disko = disko-rpi;
                };
                modules = [
                    ./hosts/router/raspberry-pi.nix
                    ./hosts/router/disko.nix
                    ./hosts/router/configuration.nix
                ];
            };
        };
}
