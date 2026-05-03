args@{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:

let
    cfg = config.services.arch-home-manager;
in
{
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    options.services.arch-home-manager = {
        enable = lib.mkEnableOption "`arch` home-manager configuration";
        trackedNeovimConfig = lib.mkOption {
            type = lib.types.bool;
            description = ''
                Whether or not to fetch a tracked Neovim configuration from Git.
                If this is set to `false`, no Neovim configuration will be used at all,
                and you'll have to bring your own.
            '';
            default = true;
        };
        trackedWezTermConfig = lib.mkOption {
            type = lib.types.bool;
            description = ''
                Whether or not to fetch a tracked WezTerm configuration from Git.
                If this is set to `false`, no WezTerm configuration will be used at all,
                and you'll have to bring your own.
            '';
            default = cfg.desktop;
        };
        wsl = lib.mkOption {
            type = lib.types.bool;
            description = ''
                Whether or not this is targeted towards a NixOS-WSL install.
                Enabling this installs and configures WSL-related software.
            '';
            default = config ? wsl && config.wsl ? enable && config.wsl.enable;
        };
        desktop = lib.mkOption {
            type = lib.types.bool;
            description = ''
                Whether or not this is targeted towards a device with a graphical desktop.
                Enabling this installs and configures more graphical software.
                Disabling this does not disable all graphical software,
                as the intended target here is for WSL installs, which can use graphical software.
            '';
            default = false;
        };
    };

    config = lib.mkIf cfg.enable {
        # What does this do?
        home-manager.useGlobalPkgs = true;
        # What does this do?
        home-manager.useUserPackages = true;

        # Allow specific unfree packages to be installed.
        #
        # <https://nixos.wiki/wiki/Unfree_Software>
        nixpkgs.config.allowUnfreePredicate =
            pkg:
            builtins.elem (lib.getName pkg) [
                # Add additional package names here
                "discord"
                "corefonts"
            ];

        fonts = lib.mkIf cfg.desktop {
            packages = with pkgs; [
                newcomputermodern
                ibm-plex
                nerd-fonts.caskaydia-cove

                # Unfree packages.
                corefonts
            ];
            # Some safe default fonts.
            enableDefaultPackages = true;
        };

        home-manager.users.arch = import ../../common/interative/home.nix;
    };
}
