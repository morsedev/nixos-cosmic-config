# =============================================================================
# modules/home/hyprland.nix  —  Configuración de Hyprland (Home Manager)
# =============================================================================
# Aquí van las reglas visuales, animaciones, atajos y programas que arrancan
# con Hyprland. Los colores son Tokyo Night.
#
# Sintaxis: `settings` es un attrset de Nix que se traduce al hyprland.conf.
# Las listas (`bind`, `exec-once`) son listas de textos.
# =============================================================================

{ config, pkgs, lib, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    # Usar la config clásica (hyprlang): exec-once/bind/monitor fiables.
    # El formato Lua que genera HM en tu versión no ejecuta bien exec-once.
    configType = "hyprlang";
    # Integración con systemd (mejor gestión de la sesión y servicios).
    systemd.enable = true;

    settings = {
      # La tecla "Super" (en el Mac es Cmd). Se usa como $mod.
      "$mod" = "SUPER";

      # --- Monitor: eDP-1 es la pantalla del portátil ---
      monitor = [
        "eDP-1,preferred,auto,1.25"   # pantalla principal (2560x1600)
        "DSI-1,disable"               # Touch Bar: no usarla como monitor
      ];

      # --- Apariencia general ---
      general = {
        gaps_in = 5;
        gaps_out = 15;
        border_size = 2;
        # (los colores del borde los pone Stylix automáticamente — Tokyo Night)
        layout = "dwindle";
        resize_on_border = true;
        allow_tearing = false;
      };

      # --- Decoración (redondeo, sombras, blur) ---
      decoration = {
        rounding = 12;
        active_opacity = 1.0;
        inactive_opacity = 0.92;
        fullscreen_opacity = 1.0;

        shadow = {
          enabled = true;
          range = 20;
          render_power = 3;
          # (el color de la sombra lo pone Stylix)
        };

        blur = {
          enabled = true;
          size = 6;
          passes = 3;
          new_optimizations = true;
          xray = false;
          noise = 0.02;
          contrast = 1.1;
          brightness = 0.9;
          # Desactivar blur en apps concretas (opcional)
          popups = true;
        };
      };

      # --- Animaciones suaves ---
      animations = {
        enabled = true;
        bezier = [
          "ease,0.05,0.9,0.1,1.05"
          "linear,0,0,1,1"
        ];
        animation = [
          "windows,1,6,ease"
          "windowsOut,1,6,ease"
          "windowsMove,1,6,ease"
          "fade,1,10,ease"
          "fadeOut,1,10,ease"
          "workspaces,1,5,ease"
          "border,1,10,ease"
          "borderangle,1,30,linear,loop"
          "specialWorkspace,1,4,ease"
        ];
      };

      # --- Teclado y touchpad ---
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
          disable_while_typing = true;
        };
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
      master.new_status = "master";

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      # --- Programas que arrancan con la sesión ---
      exec-once = [
        "waybar"
        "swaybg -c '#1a1b26'"
        "nm-applet --indicator"
        "/run/current-system/sw/libexec/polkit-gnome-authentication-agent-1"
      ];

      # --- ATAJOS DE TECLADO ---
      # Formato: "mod, tecla, accion, argumentos"
      bind = [
        # Terminal / lanzador / archivos
        "$mod, RETURN, exec, ghostty"
        "$mod, D, exec, walker"
        "$mod, E, exec, nautilus"
        "$mod, Q, killactive,"
        "$mod, M, exit,"
        "$mod, F, fullscreen,"
        "$mod, V, togglefloating,"
        "$mod, P, pseudo,"
        "$mod, J, togglesplit,"

        # Bloqueo y capturas
        "$mod, L, exec, hyprlock"
        "$mod, S, exec, grim -g \"$(slurp)\" - | satty --filename -"
        "$mod SHIFT, S, exec, grim - | satty --filename -"

        # Portapapeles
        "$mod, C, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"

        # Mover el foco
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        # Cambiar de workspace (1-9)
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"

        # Mover ventana a workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"

        # Scroll entre workspaces
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"

        # Redimensionar con ratón (Super + botón derecho)
        "$mod, mouse:273, resizewindow"

        # Multimedia (teclas del Mac)
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
      ];

      # Mover/redimensionar ventanas con el ratón + Super
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # --- Reglas de ventanas ---
      windowrule = [
        "float, class:^(pavucontrol)$"
        "float, class:^(nm-connection-editor)$"
        "float, class:^(blueman-manager)$"
        "float, title:^(Picture-in-Picture)$"
        "opacity 0.95 0.90, class:^(ghostty)$"
        "size 900 600, class:^(pavucontrol)$"
      ];

      # Capa de la barra (waybar) reservando espacio arriba
      layerrule = [
        "blur, waybar"
        "ignorezero, waybar"
      ];
    };
  };
}
