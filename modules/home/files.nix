# =============================================================================
# modules/home/files.nix  —  Gestor de archivos (Nautilus) + Yazi
# =============================================================================
#
# Nautilus (el "Files" de GNOME) es el gestor gráfico. Yazi es el gestor en
# terminal. Aquí afinamos algunos ajustes de ambos.
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # NAUTILUS (ajustes vía dconf)
  # ---------------------------------------------------------------------------
  # dconf es la base de datos de configuración de las apps GTK/GNOME.
  # Cada bloque es una "ruta" de configuración y sus valores.
  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";  # ver archivos en lista (no mosaico)
      show-hidden-files = true;             # mostrar archivos ocultos (.)
    };
    "org/gtk/settings/file-chooser" = {
      sort-directories-first = true;        # carpetas antes que archivos
    };
  };

  # ---------------------------------------------------------------------------
  # YAZI (previsualización)
  # ---------------------------------------------------------------------------
  # Tamaño máximo (en píxeles) de las imágenes que Yazi previsualiza.
  programs.yazi.settings.preview.max_width = 1000;
  programs.yazi.settings.preview.max_height = 1000;
}
