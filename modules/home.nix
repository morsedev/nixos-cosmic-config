# =============================================================================
# modules/home.nix  —  MÓDULO DE USUARIO (homeManagerModules.nixarchy)
# =============================================================================
#
# Home Manager configura TU USUARIO (no el sistema): programas personales,
# tus dotfiles (`~/.config/...`), el shell, el editor...
#
# Se importa en el flake del usuario así:
#
#   home-manager.users.macnix = {
#     imports = [ nixarchy.homeModules.nixarchy ];
#     programs.nixarchy.enable = true;
#   };
#
# -----------------------------------------------------------------------------
# Sobre `{ inputs }:` + `{ config, lib, pkgs, ... }:` (ver modules/nixos.nix):
# -----------------------------------------------------------------------------
# Igual que el módulo de sistema: primero recibe `inputs` (para poder usar
# inputs.nixvim, inputs.zen-browser...), y devuelve el módulo de Home Manager.
# =============================================================================

{ inputs }:
{ config, lib, pkgs, ... }:

{
  # ---------------------------------------------------------------------------
  # IMPORTS: piezas del usuario
  # ---------------------------------------------------------------------------
  imports = [
    # Neovim como IDE (NixVim). Recibe `inputs` porque necesita inputs.nixvim.
    (import ./home/nvim.nix { inherit inputs; })

    # Zen Browser. Recibe `inputs` porque necesita inputs.zen-browser.
    (import ./home/browser.nix { inherit inputs; })

    # Terminal Ghostty + Yazi.
    ./home/hyprland.nix
    ./home/bar.nix

    ./home/terminal.nix

    # Menús del sistema (wifi, bluetooth) hechos con wofi.
    ./home/menus.nix

    # Gestor de archivos (Nautilus + Yazi).
    ./home/files.nix

    # Shell (zsh) + prompt + aliases.
    ./home/shell.nix

    # Cursores / temas de usuario.
    ./home/themes.nix
  ];

  # ---------------------------------------------------------------------------
  # OPCIÓN DE ACTIVACIÓN
  # ---------------------------------------------------------------------------
  # Igual que en el módulo de sistema: opción de COMPATIBILIDAD para que el
  # flake pueda seguir escribiendo `programs.nixarchy.enable = true;`.
  options.programs.nixarchy.enable = lib.mkEnableOption "perfil Home Manager (IDE, terminal, apps)";

  # ---------------------------------------------------------------------------
  # CONFIG REAL
  # ---------------------------------------------------------------------------
  # `config = { ... }` es donde se ponen los ajustes (frente a `options`, que
  # solo DECLARA opciones).
  config = {
    # Versión de estado de Home Manager.
    # `lib.mkDefault` = valor por defecto que tú puedes cambiar en tu config.
    home.stateVersion = lib.mkDefault "26.11";
  };
}
