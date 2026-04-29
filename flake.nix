{
    description = "A very basic flake";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
        nixvim.url = "github:nix-community/nixvim";
        home-manager.url = "github:nix-community/home-manager";
    };

    outputs =
        inputs@{
            self,
            nixpkgs,
            nixos-wsl,
            nixvim,
            home-manager,
        }:
        {
            nixosConfigurations.wsl = inputs.nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                specialArgs = { inherit inputs; };
                modules = [
                    ./default.nix

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
        };
}
