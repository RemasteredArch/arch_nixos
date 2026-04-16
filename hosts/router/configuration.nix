{
    self,
    nixpkgs,
    nixos-raspberrypi,
    disko,
    ...
}:

let
    pkgs = nixos-raspberrypi.legacyPackages.aarch64-linux;
in
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
            eza
            git
            jq
            net-tools
            ripgrep
            tealdeer
            tmux
            unzip
            zip
        ];
        openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKSSO9Pg/bRzFb33fJr4MYbeq9HeNK5nGLJBndI5V/A SSH Login Key <81265470+RemasteredArch@users.noreply.github.com>"
        ];
    };

    nix.settings = {
        extra-substituters = [
            "https://nixos-raspberrypi.cachix.org"
        ];
        extra-trusted-public-keys = [
            "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
        ];
        experimental-features = [
            "nix-command"
            "flakes"
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
    };

    system.stateVersion = "25.11";
}
