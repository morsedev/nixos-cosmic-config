{ config, pkgs, lib, ... }:

{
  # ============ THEMES DE USUARIO ============
  # NOTA: Stylix ya se encarga de GTK, Qt, iconos, cursores y fuentes de forma
  # global (ver modules/stylix.nix). Aquí NO duplicamos esas opciones porque
  # entrarían en conflicto con Stylix. Solo añadimos lo que Stylix no cubre.

  # Cursores extra (por si Stylix no los aplica en COSMIC)
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
  };

  # Nvim se temática con tokyonight.nvim (ver nvim/init.lua).
  # Ghostty y Zen heredan el esquema de Stylix automáticamente.
}
