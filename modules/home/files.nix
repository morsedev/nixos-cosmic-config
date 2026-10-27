{ config, pkgs, lib, ... }:

{
  # ============ NAUTILUS (GNOME Files) ============
  # Ajustes de Nautilus via dconf (estilo, tema, vista de lista, etc.)
  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
      show-hidden-files = true;
    };
    "org/gtk/settings/file-chooser" = {
      sort-directories-first = true;
    };
  };

  # ============ YAZI extras ============
  # Previsualización de imágenes en Yazi (con COSMIC/Wayland)
  programs.yazi.settings.preview.max_width = 1000;
  programs.yazi.settings.preview.max_height = 1000;
}
