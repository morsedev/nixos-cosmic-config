{ config, pkgs, lib, ... }:

{
  # ============ THEMES DE USUARIO (Tokyo Night) ============
  # Stylix ya aplica el esquema globalmente. Aquí afinamos apps específicas
  # que no teman por GTK/Qt.

  # GTK
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
    cursorTheme = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };
  };

  # Qt (apps Qt como las de COSMIC o VSCode)
  qt = {
    enable = true;
    platformTheme.name = "gtk3";  # usar tema GTK → coherente con el resto
    style.name = "adwaita-dark";
  };

  # Kitty/ghostty ya temado por Stylix. Nvim lo temamos en nvim.nix.

  # Fondo de pantalla (cambia esta ruta por una imagen tuya si quieres)
  # Se usa el de Stylix (generado del esquema) por defecto.
}
