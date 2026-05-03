args@{
    config,
    lib,
    pkgs,
    inputs,
    modulesPath,
    ...
}:
# <https://github.com/nix-community/disko/blob/master/docs/disko-images.md>
{
    imports = [
        "${modulesPath}/profiles/qemu-guest.nix"
    ];

    boot.loader.grub.efiSupport = lib.mkDefault true;
    boot.loader.grub.efiInstallAsRemovable = lib.mkDefault true;

    virtualisation.vmVariantWithBootLoader.virtualisation = {
        memorySize = 1024 * 4;
        cores = 3;
    };

    # nixpkgs.config.allowUnfreePredicate =
    #     pkg:
    #     builtins.elem (lib.getName pkg) [
    #         # Add additional package names here
    #         "discord"
    #     ];

    disko.devices.disk.boot.imageSize = "64G";
    disko.memSize = 1024 * 4;
}
