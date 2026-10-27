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

    # Colores exactos de Tokyo Night para apps GTK3 (pavucontrol,
    # nm-connection-editor, diálogos de archivo...).
    gtk3.extraCss = ''
      @define-color theme_bg_color #1a1b26;
      @define-color theme_fg_color #c0caf5;
      @define-color theme_base_color #16161e;
      @define-color theme_text_color #c0caf5;
      @define-color theme_selected_bg_color #7aa2f7;
      @define-color theme_selected_fg_color #16161e;
      @define-color insensitive_bg_color #1f2335;
      @define-color insensitive_fg_color #565f89;
      @define-color borders #292e42;

      headerbar, .titlebar { background: #16161e; color: #c0caf5; }
      headerbar label, .titlebar label { color: #c0caf5; }
      button {
        background: #1f2335;
        color: #c0caf5;
        border: 1px solid #292e42;
      }
      button:hover { background: #292e42; }
      tooltip { background: #1f2335; color: #c0caf5; }
    '';

    # Los mismos colores para GTK4/libadwaita (Nautilus, File Roller,
    # pwvucontrol). Aquí se sobreescriben las variables de libadwaita.
    gtk4.extraCss = ''
      @define-color accent_bg_color #7aa2f7;
      @define-color accent_color #7aa2f7;
      @define-color accent_fg_color #16161e;
      @define-color window_bg_color #1a1b26;
      @define-color window_fg_color #c0caf5;
      @define-color view_bg_color #16161e;
      @define-color view_fg_color #c0caf5;
      @define-color headerbar_bg_color #16161e;
      @define-color headerbar_fg_color #c0caf5;
      @define-color headerbar_border_color #292e42;
      @define-color sidebar_bg_color #16161e;
      @define-color sidebar_fg_color #a9b1d6;
      /* Estado "backdrop" = ventana SIN foco. Si estas variables no se
         definen, libadwaita usa las del tema claro y el sidebar se ve BLANCO
         al desenfocar (era el fallo del panel de ajustes). */
      @define-color sidebar_backdrop_bg_color #16161e;
      @define-color sidebar_backdrop_fg_color #565f89;
      @define-color sidebar_shade_color #0f1017;
      @define-color second_sidebar_bg_color #16161e;
      @define-color second_sidebar_backdrop_bg_color #16161e;
      @define-color card_bg_color #1f2335;
      @define-color card_fg_color #c0caf5;
      @define-color popover_bg_color #1f2335;
      @define-color dialog_bg_color #1a1b26;
      @define-color borders #292e42;

      /* Botones normales: fondo de tarjeta, texto claro (si no, quedan
         "fantasma" sobre el fondo oscuro). */
      button:not(.suggested-action):not(.destructive-action) {
        background: #1f2335;
        color: #c0caf5;
      }
      button:not(.suggested-action):not(.destructive-action):hover {
        background: #292e42;
      }

      /* Sidebar de navegación (Ajustes, Nautilus, etc.) siempre oscuro,
         también cuando la ventana pierde el foco. */
      .navigation-sidebar,
      list.navigation-sidebar,
      .sidebar-panel,
      window:backdrop .navigation-sidebar,
      window:backdrop list.navigation-sidebar {
        background-color: #16161e !important;
        color: #a9b1d6 !important;
      }
      window:backdrop list.navigation-sidebar row,
      window:backdrop .navigation-sidebar row { color: #a9b1d6 !important; }
    '';

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
  # `dconf.enable` es OBLIGATORIO: sin esta línea Home Manager no escribe los
  # ajustes y las apps GTK4 (Nautilus, File Roller...) siguen en CLARO.
  dconf.enable = true;
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
