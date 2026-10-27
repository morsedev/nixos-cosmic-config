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
      font-size = 13;                            # tamaño
      cursor-style = "block";                    # forma del cursor
      cursor-style-blink = true;                 # cursor parpadeante
      window-padding-x = 8;                      # margen horizontal interno
      window-padding-y = 8;                      # margen vertical interno
      window-decoration = true;                  # muestra la barra de la ventana
      background-opacity = 0.97;                 # ligeramente transparente

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
