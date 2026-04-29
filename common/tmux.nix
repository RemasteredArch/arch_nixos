{
    config,
    lib,
    pkgs,
    inputs,
    minimal ? true,
    ...
}:

let
    catppuccin = if minimal then
        ""
    else
        # TO-DO: does the `run` path need spaces escaped in some way?
        ''
            # Modified from <https://github.com/catppuccin/tmux/tree/c26d7b8#config-3>. Licensed
            # under the MIT License, found at:
            #
            # - <https://github.com/catppuccin/tmux/blob/c26d7b8/LICENSE>
            # - <https://opensource.org/license/mit>
            #
            # Copyright (c) 2024 Catppuccin

            set -g @catppuccin_flavor "mocha"

            set -g @catppuccin_window_left_separator ""
            set -g @catppuccin_window_right_separator " "
            set -g @catppuccin_window_middle_separator " █"
            set -g @catppuccin_window_number_position "right"

            set -g @catppuccin_window_default_fill "number"
            set -g @catppuccin_window_default_text "#W"

            set -g @catppuccin_window_current_fill "number"
            set -g @catppuccin_window_current_text "#W"

            set -g @catppuccin_status_modules_right "directory session"
            set -g @catppuccin_status_left_separator  " "
            set -g @catppuccin_status_right_separator ""
            set -g @catppuccin_status_right_separator_inverse "no"
            set -g @catppuccin_status_fill "icon"
            set -g @catppuccin_status_connect_separator "no"

            set -g @catppuccin_directory_text "#{pane_current_path}"

            run ${pkgs.fetchFromGitHub {
                owner = "catppuccin";
                repo = "tmux";
                rev = "v0.2";
                sha256 = "sha256-XikYIryhixheyI3gmcJ+AInDBzCq2TXllfarnrRifEo=";
            }}/catppuccin.tmux
        '';
in
{
    enable = true;
    extraConfig = ''
        # True color support.
        set -sa terminal-overrides ",xterm*:Tc"
        set -g default-terminal "tmux-256color"

        # More ergonomic leader key.
        set -g prefix C-s

        # Vim-style bindings instead of Emacs-style bindings.
        set-window-option -g mode-keys vi

        # Set escape sequence delay to 10 ms.
        #
        # See: <https://github.com/tmux/tmux/wiki/FAQ#what-is-the-escape-time-option-is-zero-a-good-value>.
        set -sg escape-time 10

        # Pass through focus events, allowing (Neo)vim to correctly 'autoread' file changes.
        set -g focus-events on

        ${catppuccin}
    '';
}
