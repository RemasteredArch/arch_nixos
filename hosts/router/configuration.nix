{
    self,
    nixpkgs,
    nixos-raspberrypi,
    disko,
    pkgs,
    ...
}:

{
    imports = [
        ./networking.nix
        # ../../common/neovim-minimal.nix
    ];

    # Don't forget to set a password!
    users.users.arch = {
        initialPassword = "callslikecalls";
        isNormalUser = true;
        extraGroups = [
            "wheel"
        ];
        packages = with pkgs; [
            bat
            ethtool
            eza
            git
            iperf
            jq
            net-tools
            pciutils
            ripgrep
            tealdeer
            tmux
            unzip
            zip
        ];
        openssh.authorizedKeys.keys = [
            # `arch@remasteredarch.net`
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKP5f8jfyl79+ta53BkUTZoMHxI8H0Dh+jsMW4lqp0BH"
        ];
    };

    nix.settings = {
        experimental-features = [
            "nix-command"
            "flakes"
        ];
        trusted-users = [ "arch" ]; # TO-DO: remove, this grants passwordless `sudo`.

        extra-substituters = [ "https://nixos-raspberrypi.cachix.org" ];
        extra-trusted-public-keys = [
            "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
        ];
    };

    time.timeZone = "America/Los_Angeles";

    i18n.defaultLocale = "en_US.UTF-8";
    services.xserver.xkb.layout = "us";

    environment.systemPackages = with pkgs; [
        vim

        wget
        curl

        htop
        btop
    ];

    services.openssh = {
        enable = true;
        settings = {
            PermitRootLogin = "no";
            AllowUsers = [ "arch" ];
        };
        # Only trust SSH keys explicitly added by this configuration, not those found in
        # `~/.ssh/authorized_keys`.
        authorizedKeysInHomedir = false;
    };

    services.fail2ban = {
        enable = true;
        ignoreIP = [ "arch-pc" ];
    };

    system.stateVersion = "25.11";
}
