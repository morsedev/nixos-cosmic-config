# =============================================================================
# modules/home/themes.nix  —  Tema del usuario (cursores)
# =============================================================================
#
# Stylix ya se encarga de GTK, Qt, iconos, cursores y fuentes de forma global
# (ver modules/stylix.nix). Aquí SOLO añadimos el cursor, para asegurarnos de
# que se aplica también en COSMIC.
#
# ⚠️ No dupliques aquí `gtk.*` ni `qt.*`: chocarían con Stylix.
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # `home.pointerCursor` define el cursor del ratón para este usuario.
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";  # nombre del tema de cursor
    package = pkgs.bibata-cursors;   # paquete que lo contiene
    size = 24;                       # tamaño en píxeles
    gtk.enable = true;               # aplicarlo también en apps GTK
  };

  # Nota: Neovim se temática con tokyonight.nvim (ver modules/home/nvim.nix),
  # y Ghostty/Zen heredan el esquema de Stylix automáticamente.
}
