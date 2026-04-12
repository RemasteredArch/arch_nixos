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

    services.fail2ban.enable = true;

    system.stateVersion = "25.11";
}
