{
    config,
    lib,
    pkgs,
    ...
}:

{
    enable = true;
    extraConfig = ''
        # True color support.
        set -sa terminal-overrides ",xterm*:Tc"
        set -g default-terminal "tmux-256color"

        # More ergonomic leader key.
        set -g prefix C-s

        # Set escape sequence delay to 10 ms.
        #
        # See: <https://github.com/tmux/tmux/wiki/FAQ#what-is-the-escape-time-option-is-zero-a-good-value>.
        set -sg escape-time 10

        # Pass through focus events, allowing (Neo)vim to correctly 'autoread' file changes.
        set -g focus-events on
    '';
}
