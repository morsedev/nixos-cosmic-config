{ config, pkgs, lib, ... }:

{
  # ============ GHOSTTY (terminal) ============
  programs.ghostty = {
    enable = true;
    # Ghostty básico — el tema lo aplica Stylix automáticamente (Tokyo Night)
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 13;
      cursor-style = "block";
      cursor-style-blink = true;
      window-padding-x = 8;
      window-padding-y = 8;
      window-decoration = true;
      background-opacity = 0.97;
      keybind = [
        "super+enter=new_tab"
        "super+shift+enter=new_window"
      ];
    };
  };

  # ============ YAZI (file manager TUI) ============
  programs.yazi.enable = true;

  # Integración `y` para zsh (abre Yazi y cambia el cwd al salir con q)
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
