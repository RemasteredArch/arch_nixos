{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:

let
    cfg = config.services.laptop.gnome;
in
{
    options.services.laptop.gnome = {
        enable = lib.mkEnableOption "Configures GNOME for `laptop`";
        useGdm = lib.mkOption {
            type = lib.types.bool;
            description = ''
                Whether or not to enable the GNOME Display Manager.
            '';
            default = true;
        };
    };

    config = lib.mkIf cfg.enable {
        services.displayManager.gdm = lib.mkIf cfg.useGdm {
            enable = true;
        };

        services.desktopManager.gnome.enable = true;
        environment.systemPackages = with pkgs.gnomeExtensions; [
            appindicator
        ];
        programs.dconf.profiles.user.databases = with lib.gvariant; [
            {
                settings = {
                    "org/gnome/mutter" = {
                        experimental-features = [
                            "scale-monitor-framebuffer" # Fractional scaling
                            "variable-refresh-rate" # VRR (for compatible displays)
                            "xwayland-native-scaling" # Crisp scaling for Xwayland applications
                            "autoclose-xwayland" # Automatically close Xwayland if there are no clients
                        ];
                    };
                    "org/gnome/desktop/wm/keybindings" = {
                        switch-applications = mkEmptyArray type.string;
                        switch-applications-backward = mkEmptyArray type.string;

                        switch-windows = [ "<Alt>Tab" ];
                        switch-windows-backward = [ "<Shift><Alt>Tab" ];
                    };
                    "org/gnome/shell" = {
                        disable-user-extensions = false;
                        # Might not be necessary.
                        disabled-extensions = mkEmptyArray type.string;
                        # Might not be necessary.
                        enabled-extensions = [ "appindicatorsupport@rgcjonas.gmail.com" ];
                    };
                };
            }
        ];
        environment.gnome.excludePackages = with pkgs; [
            epiphany
            gnome-console
            gnome-contacts
        ];
    };
}
