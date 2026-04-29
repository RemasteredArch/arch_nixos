{
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
    # imports = [
    #     nixvim.nixosModules.nixvim
    # ];

    programs.nixvim = {
        enable = true;
        defaultEditor = true;

        colorschemes.catppuccin.enable = true;

        globals.mapleader = " ";
        opts = {
            # Use four spaces instead of tabs.
            tabstop = 8;
            softtabstop = 0;
            expandtab = true;
            shiftwidth = 4;

            # Current line behavior
            cursorline = true; # Highlights the current line.
            number = true; # Sets line numbers.
            relativenumber = true; # Sets line numbering as relative to current line.

            # Wrap lines on whitespace, etc. instead of at the last character that fits.
            linebreak = true;

            # Do nothing to buffer text of first line except a background highlight.
            foldtext = "";
            # Spaces (instead of dots) filling the blank space to the right of the line.
            fillchars = "fold: ";

            # Default to everything unfolded.
            #
            # Attempting to fold with `zf` will spit out an error: "E350: Cannot create fold with
            # current 'foldmethod'". However, it seems that because these folds exist and this
            # setting just makes them default to being open, one can simply _close_ them (instead of
            # _creating_ them) with `zc`.
            foldlevel = 99;
        };

        plugins = {
            telescope = {
                enable = true;
                settings.defaults.wrap_results = true;
                extensions.fzf-native.enable = true;
                keymaps = {
                    "ff" = {
                        action = "find_files";
                        options.desc = "Open a file picker for the current directory";
                    };
                    "fg" = {
                        action = "git_files";
                        options.desc = "Open a file picker for Git files";
                    };
                    "flg" = {
                        action = "live_grep";
                        options.desc = "Open a live regex search";
                    };
                    "fls" = {
                        action = "lsp_document_symbols";
                        options.desc = "Open a live document symbol search from LSP";
                    };
                    "flh" = {
                        action = "help_tags";
                        options.desc = "Open a help tag search";
                    };

                };
            };
            web-devicons.enable = true; # Used by Telescope.

            treesitter = {
                enable = true;

                settings.highlight.enable = true;
                settings.indent.enable = true;
                # folding = true;
                folding.enable = true;

                grammarPackages = with packages.vimPlugins.nvim-treesitter.builtGrammars; [
                    caddy
                    cmake
                    cpp
                    css
                    diff
                    dockerfile
                    editorconfig
                    git_config
                    git_rebase
                    gitcommit
                    go
                    gomod
                    gosum
                    html
                    ini
                    javascript
                    json
                    just
                    lua
                    make
                    markdown
                    markdown_inline
                    nix
                    python
                    query
                    regex
                    rust
                    sql
                    ssh_config
                    tmux
                    toml
                    typescript
                    vim
                    vimdoc
                    xml
                    yaml
                ];
            };
        };
    };
}
