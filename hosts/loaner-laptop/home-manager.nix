args@{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:

let
    cfg = config.services.arch-home-manager;
    colors = {
        reset = "\\e[0m";
        bold = "\\e[1m";
        green = "\\e[32m";
    };
    dotfiles = pkgs.fetchFromGitHub {
        owner = "RemasteredArch";
        repo = "dotfiles";
        rev = "6563a56525a6fd42d998b0314447de261d844428";
        sha256 = "sha256-GEsj0V1vHCpxcncuCOG4Oa5NTWcAlH2ggMFG9B0od7Q=";
    };
    nvim-config =
        if cfg.trackedNeovimConfig then
            pkgs.fetchFromGitHub {
                owner = "RemasteredArch";
                repo = "nvim-config";
                rev = "e2fe65d112db7228e1b1202994eb054506ba1f0b";
                sha256 = "sha256-SuGCJgA1e4PZFIXCSj+Ehxy5RDZzmK0iS3cWIXyYO0E=";
            }
        else
            "";
    wezterm-config =
        if cfg.trackedWezTermConfig then
            pkgs.fetchFromGitHub {
                owner = "RemasteredArch";
                repo = "wezterm_config";
                rev = "d8bdf369e8ffda8ce65327e9e06a70835061e0fd";
                sha256 = "sha256-0iGBwux44NBkXNmxeyOTTD1Dwsx/uvpOYXPCNfKYMJM=";
            }
        else
            "";
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
        # What exactly does this do?
        home-manager.extraSpecialArgs = {
            nixpkgs = inputs.nixpkgs;
        };

        # # Allow specific unfree packages to be installed.
        # #
        # # <https://nixos.wiki/wiki/Unfree_Software>
        # nixpkgs.config.allowUnfreePredicate =
        #     pkg:
        #     builtins.elem (lib.getName pkg) [
        #         # Add additional package names here
        #         "discord"
        #     ];

        fonts = lib.mkIf cfg.desktop {
            packages = with pkgs; [
                newcomputermodern
                ibm-plex
                nerd-fonts.caskaydia-cove
            ];
            # Some safe default fonts.
            enableDefaultPackages = true;
        };

        home-manager.users.arch =
            { nixpkgs, ... }:
            let
                packages = nixpkgs.legacyPackages.x86_64-linux;
                util = import ../../common/util.nix { pkgs = packages; };
            in
            {
                # Probably not necessary.
                fonts.fontconfig.enable = lib.mkIf cfg.desktop true;

                home.packages =
                    with packages;
                    [
                        # Development tools.
                        #
                        # Some of these should probably be system packages, not user packages, but
                        # I'll move them when I actually get around to using them.
                        act
                        gdb
                        (neovim.overrideAttrs (prevAttrs: {
                            runtimeDeps = prevAttrs.runtimeDeps ++ [
                                gcc
                                gnumake
                                go
                                nodejs_24
                                python3
                                unzip

                                wl-clipboard
                                (util.withFonts silicon [
                                    nerd-fonts.caskaydia-cove
                                    noto-fonts-color-emoji
                                ])

                                cmake
                                javaPackages.compiler.openjdk25
                                tree-sitter
                                python3Packages.pip # Not actually used by Mason :/

                                # Optional performance improvements.
                                fd
                                inotify-tools

                                clang-tools # For `clangd`.
                            ];
                        }))
                        rustup
                        shellcheck

                        # Server tools
                        caddy
                        xcaddy
                        # cloudflared
                        docker

                        # Compilers and build tools
                        cmake
                        ninja
                        # clang
                        gcc
                        javaPackages.compiler.openjdk25
                        typst

                        # File searching/viewing/manipulation
                        b3sum
                        bat
                        dos2unix
                        eza
                        file
                        fzf
                        jq
                        ripgrep

                        # Compression and encryption
                        gnupg
                        unzip
                        zip

                        # Utilities
                        bc
                        tealdeer

                        # Fun
                        fastfetch
                        pfetch
                        toilet

                        # Provides man pages for Linux and POSIX APIs.
                        man-pages
                        man-pages-posix

                        # Provides a `batman` command, which is like `man` but syntax highlighted
                        # with colors.
                        bat-extras.batman

                        # GUI utilities
                        baobab
                        seahorse

                        # Miscellaneous
                        openvpn
                    ]
                    ++ (if cfg.wsl then [ (import ../../pkgs/wslu/package.nix args) ] else [ ])
                    ++ (
                        if cfg.desktop then
                            with packages;
                            [
                                brave
                                # discord # Installing Discord from Nixpkgs disables Krisp.
                                gimp
                                onlyoffice-desktopeditors
                                obs-studio
                                rpi-imager
                                vlc
                                wezterm
                            ]
                        else
                            [ ]
                    );

                programs.starship = import ../../common/starship.nix;

                programs.bash = {
                    enable = true;
                    sessionVariables = {
                        # Prompt for non-tmux sessions.
                        PS1 = "\\[${colors.green}\\]$ \\u @ \\H > \\w > \\[${colors.reset}\\]";

                        EDITOR = "nvim";
                        VISUAL = "$EDITOR";
                        SYSTEMD_EDITOR = "$EDITOR";

                        # GPG signing passphrase prompt.
                        GPG_TTY = "$(tty)";
                    };
                    initExtra = ''
                        has() {
                            [ "$(type "$1" 2> /dev/null)" ]
                        }

                        [ -n "$TMUX" ] && has starship && eval "$(starship init bash)"

                        alias clock="${dotfiles}/scripts/dotfiles/clock.sh"
                        . "${dotfiles}/scripts/dotfiles/number_conversion.sh"
                        . "$HOME/.arch_aliases"
                    '';
                };
                home.file.".arch_aliases".source = dotfiles + "/.arch_aliases";
                programs.readline = {
                    enable = true;
                    variables = {
                        # Case insensitive tab completion.
                        completion-ignore-case = true;
                        # Stop ringing bells in the shell.
                        bell-style = "none";
                    };
                };

                programs.tmux = import ../../common/tmux.nix (args // { minimal = false; });

                home.file.".config/nvim" = lib.mkIf cfg.trackedNeovimConfig {
                    source = nvim-config;
                };
                home.file.".config/wezterm" = lib.mkIf cfg.trackedWezTermConfig {
                    source = wezterm-config;
                };
                home.file.".config/gdb".source = dotfiles + "/.config/gdb";

                programs.git = {
                    enable = true;
                    settings = {
                        init.defaultBranch = "main";
                        pull.rebase = false;
                        user = {
                            name = "RemasteredArch";
                            email = "81265470+RemasteredArch@users.noreply.github.com";
                            signingKey = "F1FC345F046EBB98";
                        };
                        gpg.format = "openpgp";
                        commit.gpgsign = true;
                    };
                };
                programs.gh = {
                    enable = true;
                    gitCredentialHelper.enable = true;
                };

                # Taken from <https://github.com/catppuccin/btop>, licensed under the MIT License,
                # found at:
                #
                # - <https://github.com/catppuccin/btop/blob/cf50077/LICENSE>
                # - <https://opensource.org/license/mit>
                #
                # Copyright (c) 2024 Catppuccin
                programs.btop = {
                    enable = true;
                    settings.color_theme = "catppuccin_mocha";
                    themes.catppuccin_mocha = ''
                        # Main background, empty for terminal default, need to be empty if you want transparent background
                        theme[main_bg]="#1e1e2e"

                        # Main text color
                        theme[main_fg]="#cdd6f4"

                        # Title color for boxes
                        theme[title]="#cdd6f4"

                        # Highlight color for keyboard shortcuts
                        theme[hi_fg]="#89b4fa"

                        # Background color of selected item in processes box
                        theme[selected_bg]="#45475a"

                        # Foreground color of selected item in processes box
                        theme[selected_fg]="#89b4fa"

                        # Color of inactive/disabled text
                        theme[inactive_fg]="#7f849c"

                        # Color of text appearing on top of graphs, i.e uptime and current network graph scaling
                        theme[graph_text]="#f5e0dc"

                        # Background color of the percentage meters
                        theme[meter_bg]="#45475a"

                        # Misc colors for processes box including mini cpu graphs, details memory graph and details status text
                        theme[proc_misc]="#f5e0dc"

                        # CPU, Memory, Network, Proc box outline colors
                        theme[cpu_box]="#cba6f7" #Mauve
                        theme[mem_box]="#a6e3a1" #Green
                        theme[net_box]="#eba0ac" #Maroon
                        theme[proc_box]="#89b4fa" #Blue

                        # Box divider line and small boxes line color
                        theme[div_line]="#6c7086"

                        # Temperature graph color (Green -> Yellow -> Red)
                        theme[temp_start]="#a6e3a1"
                        theme[temp_mid]="#f9e2af"
                        theme[temp_end]="#f38ba8"

                        # CPU graph colors (Teal -> Lavender)
                        theme[cpu_start]="#94e2d5"
                        theme[cpu_mid]="#74c7ec"
                        theme[cpu_end]="#b4befe"

                        # Mem/Disk free meter (Mauve -> Lavender -> Blue)
                        theme[free_start]="#cba6f7"
                        theme[free_mid]="#b4befe"
                        theme[free_end]="#89b4fa"

                        # Mem/Disk cached meter (Sapphire -> Lavender)
                        theme[cached_start]="#74c7ec"
                        theme[cached_mid]="#89b4fa"
                        theme[cached_end]="#b4befe"

                        # Mem/Disk available meter (Peach -> Red)
                        theme[available_start]="#fab387"
                        theme[available_mid]="#eba0ac"
                        theme[available_end]="#f38ba8"

                        # Mem/Disk used meter (Green -> Sky)
                        theme[used_start]="#a6e3a1"
                        theme[used_mid]="#94e2d5"
                        theme[used_end]="#89dceb"

                        # Download graph colors (Peach -> Red)
                        theme[download_start]="#fab387"
                        theme[download_mid]="#eba0ac"
                        theme[download_end]="#f38ba8"

                        # Upload graph colors (Green -> Sky)
                        theme[upload_start]="#a6e3a1"
                        theme[upload_mid]="#94e2d5"
                        theme[upload_end]="#89dceb"

                        # Process box color gradient for threads, mem and cpu usage (Sapphire -> Mauve)
                        theme[process_start]="#74c7ec"
                        theme[process_mid]="#b4befe"
                        theme[process_end]="#cba6f7"
                    '';
                };

                # I don't use Firefox on a daily basis, so something minimal like this is fine.
                programs.firefox = lib.mkIf cfg.desktop {
                    enable = true;
                    languagePacks = [ "en-US" ];
                    configPath = "~/.config/mozilla/firefox";
                    # <https://firefox-admin-docs.mozilla.org/reference/policies/>
                    policies = {
                        DisplayBookmarksToolbar = "never";
                        NoDefaultBookmarks = true;
                        GenerativeAI = {
                            Enabled = false;
                            Locked = true;
                        };
                        DisableAppUpdate = true;
                        ExtensionSettings = {
                            "uBlock0@raymondhill.net" = {
                                default_area = "menupanel";
                                install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
                                installation_mode = "force_installed";
                                private_browsing = true;
                            };
                        };
                        SearchEngines.Default = "DuckDuckGo";
                        FirefoxSuggest = {
                            # Also disable other forms of Firefox Suggest.
                            WebSuggestions = false;
                            Locked = true;
                        };
                        DontCheckDefaultBrowser = true;
                        FirefoxHome = {
                            Search = false;
                            TopSites = false;
                            SponsoredTopSites = false;
                            Highlights = false;
                            Pocket = false;
                            Stories = false;
                            SponsoredPocket = false;
                            SponsoredStories = false;
                            Snippets = false;
                            Locked = true;
                        };
                    };
                };

                # The state version is required and should stay at the version you
                # originally installed.
                home.stateVersion = "25.11";
            };
    };
}
