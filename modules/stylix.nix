# =============================================================================
# modules/stylix.nix  —  THEMING HOMOGÉNEO (Tokyo Night)
# =============================================================================
#
# Stylix toma UN esquema de colores y lo aplica a TODAS las apps que puede:
# GTK, Qt, terminales, navegadores, consola, fuentes, cursores...
# Resultado: todo el escritorio con la misma paleta.
#
# El módulo de Stylix se importa en modules/nixos.nix
# (`inputs.stylix.nixosModules.stylix`). Aquí solo se CONFIGURA.
# =============================================================================

{ config, pkgs, lib, ... }:

{
  stylix = {
    # Activa el theming global.
    enable = true;

    # Esquema de colores base16 "Tokyo Night" (oscuro).
    # `${...}` inserta la RUTA del archivo dentro del paquete `base16-schemes`.
    # En NixOS, `${pkgs.algo}` = ruta en /nix/store de ese paquete.
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";

    # Fuerza modo oscuro.
    polarity = "dark";

    # Cursor del sistema (GTK + apps X11/Wayland). El cursor por defecto de
    # Adwaita es lo primero que delata un escritorio sin personalizar.
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };

    # -------------------------------------------------------------------------
    # FUENTES
    # -------------------------------------------------------------------------
    # Stylix instala y aplica estas fuentes en las apps.
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;   # fuente de código
        name = "JetBrainsMono Nerd Font";           # nombre que usan las apps
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };

      # Tamaños (en puntos) por contexto.
      # OJO: 11 es demasiado pequeño; por debajo de 12 el texto "parece de juguete".
      sizes = {
        terminal = 13;
        applications = 12;
        desktop = 12;
        popups = 12;
      };
    };

    # -------------------------------------------------------------------------
    # TARGETS (qué familias de apps se teman)
    # -------------------------------------------------------------------------
    # Stylix tiene "targets" para muchas apps. Aquí activamos los de sistema.
    # Las apps de usuario (Ghostty, Zen, Neovim) se teman desde Home Manager.
    targets = {
      gtk.enable = true;   # apps GTK (Nautilus, etc.)
      qt.enable = true;    # apps Qt
    };
  };
}
