# =============================================================================
# modules/home/themes.nix  —  Tema del usuario (GTK, Qt, iconos, cursor)
# =============================================================================
# Aquí se decide cómo se ven TODAS las apps "normales" del sistema:
# Nautilus, pavucontrol (audio), nm-connection-editor (wifi), diálogos de
# archivos, el agente de polkit (contraseña), visores de imágenes...
#
# ⚠️ IMPORTANTE (esto era el fallo):
# Stylix, con `autoEnable = false`, NO aplica su tema a GTK por sí solo. Si no
# se configura este módulo, GTK se queda con Adwaita CLARO por defecto y esas
# ventanas aparecen blancas, rompiendo todo el escritorio.
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # GTK 3 / GTK 4  (la mayoría de apps del sistema)
  # ---------------------------------------------------------------------------
  # `adw-gtk3-dark` es un tema que hace que las apps GTK3 se vean como las
  # modernas de GNOME (libadwaita) en oscuro. Es la base más limpia para luego
  # pintar encima los colores de Tokyo Night.
  gtk = {
    enable = true;

    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };

    iconTheme = {
      name = "Papirus-Dark";              # un solo set de iconos en todo el sistema
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
    };

    font = {
      name = "Inter";
      size = 12;
    };

    # Ajustes extra que se escriben en ~/.config/gtk-3.0/settings.ini
    gtk3.extraConfig = {
      "gtk-application-prefer-dark-theme" = 1;   # fuerza variante oscura
      "gtk-theme-name" = "adw-gtk3-dark";
      "gtk-icon-theme-name" = "Papirus-Dark";
      "gtk-font-name" = "Inter 12";
      "gtk-cursor-theme-name" = "Bibata-Modern-Ice";
      "gtk-cursor-theme-size" = 24;
      # Transparencia y bordes redondeados en menús/ventanas GTK3.
      "gtk-decoration-layout" = "appmenu:minimize,maximize,close";
    };

    # Lo mismo para apps GTK4 (Nautilus nuevo, diálogos modernos...).
    gtk4.extraConfig = {
      "gtk-application-prefer-dark-theme" = 1;
      "gtk-theme-name" = "adw-gtk3-dark";
      "gtk-icon-theme-name" = "Papirus-Dark";
      "gtk-font-name" = "Inter 12";
      "gtk-cursor-theme-name" = "Bibata-Modern-Ice";
      "gtk-cursor-theme-size" = 24;
    };
  };

  # ---------------------------------------------------------------------------
  # GNOME / libadwaita
  # ---------------------------------------------------------------------------
  # Las apps GTK4 modernas NO leen settings.ini: preguntan a dconf.
  # Sin esto, Nautilus y otras se quedan en claro aunque el resto sea oscuro.
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "adw-gtk3-dark";
    icon-theme = "Papirus-Dark";
    font-name = "Inter 12";
    cursor-theme = "Bibata-Modern-Ice";
    cursor-size = 24;
  };

  # ---------------------------------------------------------------------------
  # QT
  # ---------------------------------------------------------------------------
  # En vez de instalar Kvantum y otro tema aparte, hacemos que las apps Qt
  # usen el tema GTK. Así hay una sola estética en todo el sistema.
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

  # ---------------------------------------------------------------------------
  # CURSOR
  # ---------------------------------------------------------------------------
  # `home.pointerCursor` define el cursor del ratón para este usuario.
  # Bibata "Ice" es la variante clara/azulada: encaja mejor con Tokyo Night
  # que la "Classic" (negra). El nombre debe coincidir con el que usa
  # `hyprctl setcursor` en modules/home/hyprland.nix.
  home.pointerCursor = {
    name = "Bibata-Modern-Ice";      # nombre del tema de cursor
    package = pkgs.bibata-cursors;   # paquete que lo contiene
    size = 24;                       # tamaño en píxeles
    gtk.enable = true;               # aplicarlo también en apps GTK
  };
}
