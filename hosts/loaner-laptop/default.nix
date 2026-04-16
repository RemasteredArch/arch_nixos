# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

args@{ config, lib, pkgs, ... }:

{
    imports = [
        # include NixOS-WSL modules
        <nixos-wsl/modules>
        ../../common/neovim-minimal.nix
        ./home-manager.nix
    ];

    wsl = {
        enable = true;
        defaultUser = "arch";
    };

    users.users.arch = {
        isNormalUser = true;
    };

    services.arch-home-manager = {
        enable = true;
        trackedNeovimConfig = false;
    };

    nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
        trusted-users = [ "arch" ];
    };

    time.timeZone = "America/Los_Angeles";

    # Enable developer documentation that some packages optionally provide.
    documentation.dev.enable = true;

    # Maintain the user's editor preferences when running commands with `sudo`.
    security.sudo.extraConfig = ''
        Defaults:%sudo env_keep += "EDITOR"
        Defaults:%sudo env_keep += "VISUAL"
        Defaults:%sudo env_keep += "SYSTEMD_EDITOR"
    '';

    programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
            zlib
            zstd
            stdenv.cc.cc
            curl
            openssl
            attr
            libssh
            bzip2
            libxml2
            acl
            libsodium
            util-linux
            xz
            systemd

            icu
        ];
    };

    programs.tmux = import ../../common/tmux.nix args;

    services.gnome.gnome-keyring.enable = true;
    programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
        pinentryPackage = pkgs.pinentry-curses;
    };

    environment.systemPackages = with pkgs; [
        man

        vim

        net-tools
        wget
        curl

        htop
        btop
    ];

    virtualisation.docker.enable = true;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It's perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "25.11"; # Did you read the comment?
}
