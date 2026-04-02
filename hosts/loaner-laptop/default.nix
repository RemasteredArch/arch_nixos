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
    ];

    wsl = {
        enable = true;
        wsl.defaultUser = "arch";
    };

    programs.tmux = import ../../common/tmux.nix args;

    environment.systemPackages = with pkgs; [
        act
        b3sum
        bat
        caddy
        xcaddy
        # cloudflared
        docker
        eza
        fzf
        gcc
        gh
        git
        javaPackages.compiler.openjdk25
        jq
        net-tools
        ripgrep
        rustup
        shellcheck
        tealdeer
        unzip
        zip

        vim

        wget
        curl

        htop
        btop
    ];

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It's perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "25.11"; # Did you read the comment?
}
