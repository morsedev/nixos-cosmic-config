# =============================================================================
# modules/home/bar.nix  —  Barra + paneles estilo Noctalia (Tokyo Night)
# =============================================================================
# - Waybar: barra flotante redondeada (como Noctalia)
# - swaync: notificaciones + CENTRO DE CONTROL con toggles (wifi, bt, volumen...)
# - wofi: lanzador de apps
# - hyprlock / hypridle: bloqueo e inactividad
# - cliphist: historial de portapapeles
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # Menú de energía (lo usa el botón ⏻ de la barra)
  home.packages = [
    (pkgs.writeShellScriptBin "wofi-power" ''
      choice=$(printf '%s\n' "   Apagar" "   Reiniciar" "   Cerrar sesión" "   Bloquear" | wofi --dmenu --prompt "Energía" --width 300 --height 300)
      case "$choice" in
        *Apagar*) systemctl poweroff ;;
        *Reiniciar*) systemctl reboot ;;
        *"Cerrar sesión"*) hyprctl dispatch exit ;;
        *Bloquear*) hyprlock ;;
      esac
    '')
  ];

  # ===========================================================================
  # WAYBAR (barra flotante)
  # ===========================================================================
  programs.waybar = {
    enable = true;

    # `settings` es una LISTA de barras (aquí una sola).
    settings = [{
      layer = "top";
      position = "top";
      height = 38;
      spacing = 6;

      # Flotante: márgenes alrededor (look Noctalia)
      margin-top = 8;
      margin-left = 10;
      margin-right = 10;

      modules-left = [ "custom/launcher" "hyprland/workspaces" "hyprland/window" ];
      modules-center = [ "clock" ];
      modules-right = [ "tray" "pulseaudio" "network" "battery" "custom/control" "custom/power" ];

      # Botón de apps (abre wofi)
      "custom/launcher" = {
        format = "";
        tooltip = false;
        on-click = "walker";
      };

      # Workspaces de Hyprland como puntitos
      "hyprland/workspaces" = {
        format = "{icon}";
        on-click = "activate";
        all-outputs = true;
        format-icons = {
          "1" = "";
          "2" = "";
          "3" = "";
          default = "";
          urgent = "";
          active = "";
        };
      };

      # Título de la ventana activa
      "hyprland/window" = {
        format = "{title}";
        max-length = 45;
        separate-outputs = true;
        rewrite = {
          "(.*) — Mozilla Firefox" = "$1";
        };
      };

      # Reloj
      clock = {
        format = "{:%H:%M}";
        format-alt = "{:%a %d %b  %H:%M}";
        tooltip-format = "<tt>{calendar}</tt>";
        calendar = {
          mode = "month";
          weeks-pos = "left";
          format = {
            months = "<span color='#7aa2f7'><b>{}</b></span>";
            days = "<span color='#c0caf5'>{}</span>";
            today = "<span color='#bb9af7'><b>{}</b></span>";
          };
        };
      };

      # Bandeja del sistema
      tray = {
        spacing = 12;
        icon-size = 18;
      };

      # Volumen
      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "󰝟 mute";
        format-icons = { default = [ "" "" "" ]; };
        on-click = "pavucontrol";
        on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        scroll-step = 5;
      };

      # Red
      network = {
        format-wifi = " {essid}";
        format-ethernet = "󰈀 LAN";
        format-disconnected = "󰤭 off";
        tooltip-format = "{ifname} via {gwaddr}";
        on-click = "nm-connection-editor";
      };

      # Batería
      battery = {
        states = { warning = 30; critical = 15; };
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-plugged = "󰚥 {capacity}%";
        format-icons = [ "" "" "" "" "" ];
      };

      # Botón que abre el CENTRO DE CONTROL (swaync)
      "custom/control" = {
        format = "";
        tooltip = true;
        tooltip-format = "Centro de control";
        on-click = "swaync-client -t -sw";
      };

      # Botón de apagado (menú)
      "custom/power" = {
        format = "⏻";
        tooltip = false;
        on-click = "wofi-power";
      };
    }];

    # =========================================================================
    # ESTILO (CSS) — Tokyo Night, barra flotante redondeada
    # =========================================================================
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", "Symbols Nerd Font", sans-serif;
        font-size: 13px;
        font-weight: 600;
        border: none;
        border-radius: 0;
        min-height: 0;
      }

      window#waybar {
        background: transparent;
        color: #c0caf5;
      }

      /* Grupos flotantes */
      .modules-left,
      .modules-center,
      .modules-right {
        background: rgba(26, 27, 38, 0.82);
        border: 1px solid rgba(122, 162, 247, 0.25);
        border-radius: 14px;
        padding: 2px 12px;
        margin: 0 4px;
        box-shadow: 0 4px 14px rgba(0, 0, 0, 0.45);
      }

      /* Workspaces */
      #workspaces {
        padding: 0 4px;
      }
      #workspaces button {
        padding: 0 6px;
        margin: 2px 2px;
        color: #565f89;
        border-radius: 10px;
        transition: all 0.25s ease;
      }
      #workspaces button:hover {
        background: rgba(122, 162, 247, 0.15);
        color: #c0caf5;
      }
      #workspaces button.active {
        color: #1a1b26;
        background: linear-gradient(45deg, #7aa2f7, #bb9af7);
        box-shadow: 0 0 10px rgba(122, 162, 247, 0.6);
      }
      #workspaces button.urgent {
        color: #1a1b26;
        background: #f7768e;
      }

      /* Ventana activa */
      #window {
        color: #a9b1d6;
        padding: 0 8px;
        font-weight: 500;
      }

      /* Reloj */
      #clock {
        color: #7aa2f7;
        font-weight: 700;
        padding: 0 6px;
      }

      /* Módulos de la derecha */
      #pulseaudio { color: #7dcfff; padding: 0 6px; }
      #network   { color: #9ece6a; padding: 0 6px; }
      #battery   { color: #e0af68; padding: 0 6px; }
      #battery.charging { color: #9ece6a; }
      #battery.warning  { color: #e0af68; }
      #battery.critical { color: #f7768e; animation: blink 1s infinite; }

      #tray { padding: 0 8px; }
      #tray > .passive { -gtk-icon-effect: dim; }

      #custom-launcher { color: #bb9af7; font-size: 17px; padding: 0 8px; }
      #custom-control  { color: #7aa2f7; font-size: 15px; padding: 0 6px; }
      #custom-power    { color: #f7768e; font-size: 15px; padding: 0 8px; }

      #custom-launcher:hover,
      #custom-control:hover,
      #custom-power:hover { background: rgba(122, 162, 247, 0.15); border-radius: 10px; }

      @keyframes blink {
        to { color: #1a1b26; }
      }

      tooltip {
        background: rgba(26, 27, 38, 0.95);
        border: 1px solid rgba(122, 162, 247, 0.4);
        border-radius: 10px;
      }
      tooltip label { color: #c0caf5; }
    '';
  };

  # ===========================================================================
  # WALKER + ELEPHANT (lanzador de apps, Wayland nativo y precioso)
  # ===========================================================================
  # Elephant es el "proveedor" de datos (apps, archivos, etc.) que usa Walker.
  services.elephant.enable = true;

  services.walker = {
    enable = true;
    systemd.enable = true;
    enableElephantIntegration = true;

    settings = {
      close_when_open = true;
      disable_click_to_close = false;
      force_keyboard_focus = true;
      hotreload_theme = false;
      timeout = 0;
    };

    # Tema Tokyo Night (GTK CSS)
    theme = {
      name = "tokyo-night";
      style = ''
        @define-color window_bg_color #1a1b26;
        @define-color accent_bg_color #7aa2f7;
        @define-color theme_fg_color #c0caf5;
        @define-color error_bg_color #f7768e;
        @define-color error_fg_color #c0caf5;

        * { all: unset; font-family: "JetBrainsMono Nerd Font", sans-serif; }

        popover {
          background: rgba(26, 27, 38, 0.97);
          border: 1px solid rgba(122, 162, 247, 0.35);
          border-radius: 20px;
          padding: 10px;
        }

        .box-wrapper {
          box-shadow: 0 19px 38px rgba(0,0,0,0.45), 0 15px 12px rgba(0,0,0,0.30);
          background: @window_bg_color;
          padding: 20px;
          border-radius: 20px;
          border: 1px solid rgba(122, 162, 247, 0.35);
        }

        .preview-box, .elephant-hint, .placeholder { color: @theme_fg_color; }

        .input {
          caret-color: @theme_fg_color;
          background: #24283b;
          padding: 12px 14px;
          border-radius: 12px;
          color: @theme_fg_color;
          font-size: 15px;
        }
        .input placeholder { opacity: 0.45; }
        .input selection { background: rgba(122,162,247,0.35); }

        .list { color: @theme_fg_color; }
        .item-box { border-radius: 12px; padding: 10px; margin: 2px 0; }
        child:selected .item-box, row:selected .item-box {
          background: linear-gradient(45deg, rgba(122,162,247,0.85), rgba(187,154,247,0.85));
          color: #1a1b26;
        }
        .item-text-box { font-size: 14px; }
        .item-subtext { font-size: 12px; opacity: 0.55; }
        .item-image-text { font-size: 28px; }

        .preview {
          border: 1px solid rgba(122,162,247,0.3);
          border-radius: 12px;
          color: @theme_fg_color;
        }
        .keybinds {
          padding-top: 10px;
          border-top: 1px solid rgba(122,162,247,0.2);
          font-size: 12px;
          color: @theme_fg_color;
        }
        .keybind-label { padding: 2px 4px; border-radius: 4px; border: 1px solid @theme_fg_color; }
        .error { padding: 10px; background: @error_bg_color; color: @error_fg_color; border-radius: 10px; }
      '';
    };
  };

  # ===========================================================================
  # WOFI (lanzador de apps)
  # ===========================================================================
  programs.wofi = {
    enable = true;
    settings = {
      width = 640;
      height = 420;
      location = "center";
      show = "drun";
      prompt = "  Buscar…";
      filter_rate = 100;
      allow_markup = true;
      no_actions = true;
      halign = "fill";
      orientation = "vertical";
      content_halign = "fill";
      insensitive = true;
      allow_images = true;
      image_size = 24;
      gtk_dark = true;
    };
    style = ''
      window {
        background-color: rgba(26, 27, 38, 0.96);
        border: 1px solid rgba(122, 162, 247, 0.35);
        border-radius: 16px;
        font-family: "JetBrainsMono Nerd Font";
        font-size: 14px;
      }
      #input {
        margin: 12px;
        padding: 8px 12px;
        background-color: #24283b;
        color: #c0caf5;
        border: 1px solid rgba(122, 162, 247, 0.3);
        border-radius: 10px;
      }
      #inner-box { margin: 6px 12px 12px 12px; }
      #entry {
        padding: 8px 10px;
        border-radius: 10px;
        color: #c0caf5;
      }
      #entry:selected {
        background: linear-gradient(45deg, #7aa2f7, #bb9af7);
        color: #1a1b26;
      }
      #text { color: inherit; }
    '';
  };

  # ===========================================================================
  # SWAYNC (notificaciones + CENTRO DE CONTROL)
  # ===========================================================================
  # Es lo que da el "panel" tipo Noctalia: al pulsar el icono de la barra se
  # abre un centro de control con toggles (wifi, bluetooth, volumen, etc.).
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      cssPriority = "user";
      notification-icon-size = 48;
      notification-body-image-height = 120;
      notification-body-image-width = 200;
      timeout = 6;
      timeout-low = 4;
      timeout-critical = 0;
      fit-to-screen = true;
      control-center-width = 380;
      control-center-height = 700;
      notification-window-width = 380;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      widgets = [
        "title"
        "dnd"
        "notifications"
        "volume"
        "backlight"
        "network"
        "bluetooth"
        "battery"
        "power-profiles"
        "mpris"
      ];
      widget-config = {
        title = { text = "Centro de control"; clear-all-button = true; button-text = "Limpiar"; };
        dnd = { text = "No molestar"; };
        volume = { label = ""; show-per-app = true; };
        backlight = { label = ""; };
        network = { label = "Red"; };
        bluetooth = { label = "Bluetooth"; };
        battery = { label = "Batería"; };
        mpris = { image-size = 96; image-radius = 8; };
      };
    };
    # Estilo Tokyo Night del centro de control / notificaciones
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", sans-serif;
        font-size: 13px;
      }
      .control-center {
        background: rgba(26, 27, 38, 0.97);
        border: 1px solid rgba(122, 162, 247, 0.35);
        border-radius: 16px;
        color: #c0caf5;
        padding: 12px;
      }
      .control-center .widget-title > label {
        color: #7aa2f7;
        font-size: 16px;
        font-weight: 700;
      }
      .notification-row { padding: 4px; }
      .notification {
        background: #24283b;
        border: 1px solid rgba(122, 162, 247, 0.25);
        border-radius: 12px;
        color: #c0caf5;
        margin: 4px 0;
      }
      .notification-content { padding: 8px; }
      .close-button { color: #f7768e; }
      .widget-dnd > switch { background: #414868; border-radius: 12px; }
      .widget-dnd > switch:checked { background: #7aa2f7; }
      .widget-volume { color: #7dcfff; }
      .widget-battery { color: #e0af68; }
      .widget-buttons-grid > flowbox > flowboxchild > button {
        background: #24283b;
        color: #c0caf5;
        border-radius: 10px;
        margin: 3px;
      }
      .widget-buttons-grid > flowbox > flowboxchild > button:hover {
        background: #7aa2f7;
        color: #1a1b26;
      }
    '';
  };

  # ===========================================================================
  # HYPRLOCK (pantalla de bloqueo)
  # ===========================================================================
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        grace = 0;
      };
      background = [{
        monitor = "";
        color = "rgba(26, 27, 38, 1.0)";
        blur_passes = 0;
      }];
      input-field = [{
        monitor = "";
        size = "280, 60";
        outline_thickness = 2;
        dots_size = 0.25;
        dots_spacing = 0.3;
        dots_center = true;
        outer_color = "rgba(122, 162, 247, 0.7)";
        inner_color = "rgba(36, 40, 59, 0.9)";
        font_color = "rgb(c0caf5)";
        placeholder_text = "Contraseña…";
        fail_text = "Error";
        rounding = 14;
        position = "0, -80";
        halign = "center";
        valign = "center";
      }];
      label = [
        {
          monitor = "";
          text = "$TIME";
          color = "rgb(122, 162, 247)";
          font_size = 96;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 180";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "  macnix";
          color = "rgb(c0caf5)";
          font_size = 18;
          position = "0, 90";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  # ===========================================================================
  # HYPRIDLE (bloqueo y suspensión por inactividad)
  # ===========================================================================
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        { timeout = 300; on-timeout = "pgrep hyprlock || hyprlock"; }
        { timeout = 600; on-timeout = "hyprctl dispatch dpms off"; on-resume = "hyprctl dispatch dpms on"; }
        { timeout = 1800; on-timeout = "systemctl suspend"; }
      ];
    };
  };

  # ===========================================================================
  # CLIPHIST (historial de portapapeles)
  # ===========================================================================
  services.cliphist.enable = true;
}
