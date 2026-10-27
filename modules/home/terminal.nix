# =============================================================================
# modules/home/terminal.nix  —  Terminal (Ghostty) y explorador TUI (Yazi)
# =============================================================================
#
# Home Manager configura estos programas para TU usuario. Los archivos de
# configuración se generan solos (no los editas a mano).
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # GHOSTTY (terminal)
  # ---------------------------------------------------------------------------
  # Terminal moderno con aceleración por GPU.
  programs.ghostty = {
    enable = true;

    # `settings` son ajustes de Ghostty. Cada clave = lo que pondrías en su
    # archivo de configuración.
    settings = {
      font-family = "JetBrainsMono Nerd Font";  # fuente (con iconos)
      font-size = 13.5;                          # tamaño
      cursor-style = "block";                    # forma del cursor
      cursor-style-blink = true;                 # cursor parpadeante
      window-padding-x = 16;                     # margen horizontal interno
      window-padding-y = 14;                     # margen vertical interno
      window-padding-balance = true;             # reparte el padding por igual
      window-decoration = false;                 # sin barra de título (la pone Hyprland)
      background-opacity = 0.90;                 # transparencia (Hyprland le aplica blur)

      # --- Colores Tokyo Night ---
      # Si no se ponen, Ghostty usa SU tema por defecto (un gris azulado más
      # claro, #282c34) y la terminal desentona con el resto del escritorio.
      background = "#16161e";
      foreground = "#c0caf5";
      cursor-color = "#c0caf5";
      selection-background = "#33467c";
      selection-foreground = "#c0caf5";
      palette = [
        "0=#15161e"  "1=#f7768e"  "2=#9ece6a"  "3=#e0af68"
        "4=#7aa2f7"  "5=#bb9af7"  "6=#7dcfff"  "7=#a9b1d6"
        "8=#414868"  "9=#f7768e"  "10=#9ece6a" "11=#e0af68"
        "12=#7aa2f7" "13=#bb9af7" "14=#7dcfff" "15=#c0caf5"
      ];
      minimum-contrast = 1.1;                    # evita texto ilegible sobre el fondo
      confirm-close-surface = false;             # cerrar con Cmd+W sin preguntar

      # Atajos de teclado propios de Ghostty.
      # `super` en Linux = la tecla Cmd/Windows.
      keybind = [
        "super+enter=new_tab"          # Cmd+Enter → nueva pestaña
        "super+shift+enter=new_window" # Cmd+Shift+Enter → nueva ventana
      ];
    };
  };

  # ---------------------------------------------------------------------------
  # YAZI (explorador de archivos en terminal)
  # ---------------------------------------------------------------------------
  programs.yazi.enable = true;

  # ---------------------------------------------------------------------------
  # INTEGRACIÓN DE YAZI CON ZSH
  # ---------------------------------------------------------------------------
  # Esta función `y` abre Yazi y, al salir (q), te deja en la carpeta en la
  # que estabas en Yazi. `programs.zsh.initContent` añade código a tu .zshrc.
  #
  # `lib.mkBefore ''...''` → este texto se pone ANTES del resto del .zshrc.
  # `''...''` → cadena de varias líneas (aquí es un script de shell).
  programs.zsh.initContent = lib.mkBefore ''
    function y() {
      local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
      yazi "$@" --cwd-file="$tmp"
      if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
      fi
      rm -f -- "$tmp"
    }
  '';
}
