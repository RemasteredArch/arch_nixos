# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

args@{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:

let
    packages = inputs.nixpkgs.legacyPackages.x86_64-linux;
in
{
    imports = [
        ../../common/neovim-minimal.nix
        ./home-manager.nix
    ];

    wsl.enable = lib.mkDefault false; # To allow conditionals that don't fail on a missing key.
    boot.binfmt = {
        # Prefer to statically load the emulators into the Kernel to support Docker.
        preferStaticEmulators = true;
        # Install emulators (mostly QEMU) for the specified architectures.
        emulatedSystems = [
            "aarch64-linux" # AKA `arm64`.
        ];
    };

    users.users.arch = {
        isNormalUser = true;
    };

    services.arch-home-manager = {
        enable = true;
        trackedNeovimConfig = false;
    };

    nix.settings = {
        experimental-features = [
            "nix-command"
            "flakes"
        ];
        trusted-users = [ "arch" ];

        extra-substituters = [ "https://nixos-raspberrypi.cachix.org" ];
        extra-trusted-public-keys = [
            "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
        ];
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
        libraries = with packages; [
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
    # Enabled by default with gnome-keyring, but I figured it's good to be explicit.
    services.gnome.gcr-ssh-agent.enable = true;
    # Not really sure why this isn't set up by the systemd service, but setting this like so makes
    # SSH use gnome-keyring's SSH agent, so it stays.
    environment.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
    programs.gnupg.agent = {
        enable = true;
        pinentryPackage = packages.pinentry-curses;
    };

    environment.systemPackages = with packages; [
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
