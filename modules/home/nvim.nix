{ config, pkgs, lib, ... }:

{
  # ============ NEOVIM ============
  # Instala Neovim y coloca el init.lua estilo kickstart en ~/.config/nvim.
  # Los plugins se instalan solos al primer arranque (lazy.nvim).
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      # LSP servers (ya declarados en development.nix, pero por si acaso)
      nil                       # Nix LSP
      rust-analyzer             # Rust LSP
      sourcekit-lsp             # Swift LSP
      dart                      # Dart SDK (para dartls)
      pyright
      nodePackages.typescript-language-server
      lua-language-server
      clang-tools
      # Herramientas de DAP
      codelldb                  # debugger para Rust/C/C++
      lldb                      # debugger para Swift
      # Formatters / utilidades
      nixpkgs-fmt
      stylua
      nodePackages.prettier
      ripgrep                   # para Telescope live_grep
      fd                        # para Telescope find_files
    ];
  };

  # Colocar el init.lua estilo kickstart
  home.file.".config/nvim/init.lua".source = ./nvim/init.lua;
}
