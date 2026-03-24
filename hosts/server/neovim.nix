{ config, lib, pkgs, ... }:

let
  nixvim = import (builtins.fetchGit {
    url = "https://github.com/nix-community/nixvim";
    ref = "nixos-25.11";
  });
in
{
  imports = [
    nixvim.nixosModules.nixvim
  ];

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
      cursorline = true;     # Highlights the current line.
      number = true;         # Sets line numbers.
      relativenumber = true; # Sets line numbering as relative to current line.

      # Wrap lines on whitespace, etc. instead of at the last character that fits.
      linebreak = true;

      # Do nothing to buffer text of first line except a background highlight.
      foldtext = "";
      # Spaces (instead of dots) filling the blank space to the right of the line.
      fillchars = "fold: ";

      # Default to everything unfolded.
      #
      # Attempting to fold with `zf` will spit out an error: "E350: Cannot create fold with current
      # 'foldmethod'". However, it seems that because these folds exist and this setting just makes
      # them default to being open, one can simply _close_ them (instead of _creating_ them) with
      # `zc`.
      foldlevel = 99;
    };

    plugins = {
      treesitter = {
        enable = true;

        settings.highlight.enable = true;
        settings.indent.enable = true;
        folding = true;

        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
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
