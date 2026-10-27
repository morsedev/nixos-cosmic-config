# =============================================================================
# modules/home/bar.nix  —  Barra + paneles estilo Noctalia (Tokyo Night)
# =============================================================================
# - Waybar: barra flotante en "pastillas" (como Noctalia)
# - swaync: notificaciones + CENTRO DE CONTROL con toggles (wifi, bt, volumen...)
# - walker: lanzador de apps
# - hyprlock / hypridle: bloqueo e inactividad
# - cliphist: historial de portapapeles
#
# Los iconos son glifos de "Nerd Font" (JetBrainsMono Nerd Font los incluye).
# Por eso la familia de fuentes de los iconos es la monoespaciada y el texto
# normal usa "Inter".
# =============================================================================

{ config, pkgs, lib, ... }:

let
  # ---------------------------------------------------------------------------
  # GLIFOS NERD FONT
  # ---------------------------------------------------------------------------
  # Los iconos de la barra son caracteres Unicode del rango "Private Use Area".
  # Si se copian/pegan a mano es fácil que se corrompan (y aparecen cuadrados o
  # desaparecen). Por eso los generamos a partir de su código hexadecimal:
  #   glyph "f313"           → logo de NixOS
  #   glyph "f028"           → altavoz alto
  # `builtins.fromJSON` interpreta el texto "\uf313" como JSON y devuelve el
  # carácter. Solo vale para códigos hasta FFFF (los que usamos aquí).
  glyph = code: builtins.fromJSON ("\"\\u" + code + "\"");

  # Iconos concretos que usamos (código + para qué sirve).
  ico = {
    nix = glyph "f313";        # logo de NixOS
    volDown = glyph "f027";    # altavoz bajo
    volUp = glyph "f028";      # altavoz alto
    mute = glyph "f026";       # altavoz silenciado
    wifi = glyph "f1eb";       # wifi
    ethernet = glyph "f233";   # servidor / LAN
    warning = glyph "f071";    # aviso (sin conexión)
    bolt = glyph "f0e7";       # rayo (cargando)
    sliders = glyph "f1de";    # controles / centro de control
    batEmpty = glyph "f244";
    batQuarter = glyph "f243";
    batHalf = glyph "f242";
    batThreeQuarter = glyph "f241";
    batFull = glyph "f240";
  };
in
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
      height = 36;        # 36px: por debajo de 32 la barra parece "de juguete"
      spacing = 8;

      # Flotante: márgenes alrededor (look Noctalia)
      margin-top = 8;
      margin-left = 10;
      margin-right = 10;

      modules-left = [ "custom/launcher" "hyprland/workspaces" ];
      modules-center = [ "clock" "custom/date" ];
      modules-right = [ "tray" "pulseaudio" "network" "battery" "custom/control" "custom/power" ];

      # Logo / botón de apps (abre el lanzador)
      # glyph "f313" = logo de NixOS (Nerd Font)
      "custom/launcher" = {
        format = ico.nix;
        tooltip = false;
        on-click = "walker";
      };

      # Workspaces NUMERADOS (1..5 siempre visibles).
      # Antes eran iconos, y como todos apuntaban al mismo glifo parecía un
      # punto borroso. Los números se leen mejor y son más "de diseño".
      "hyprland/workspaces" = {
        format = "{name}";
        on-click = "activate";
        all-outputs = true;
        # Mostrar siempre los workspaces 1-5 aunque estén vacíos.
        persistent-workspaces = { "*" = 5; };
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

      # Fecha corta al lado del reloj (segunda mitad del "centro")
      "custom/date" = {
        exec = "date '+%a %d %b'";
        interval = 60;
        tooltip = false;
        on-click = "walker --provider calendar";
      };

      # Bandeja del sistema
      tray = {
        spacing = 12;
        icon-size = 18;
      };

      # Volumen: icono + porcentaje (el icono cambia con el nivel)
      pulseaudio = {
        format = "${ico.volUp}  {volume}%";
        format-muted = "${ico.mute}  {volume}%";
        format-icons = {
          # bajo / medio / alto  (Font Awesome: volume-down / up)
          default = [ ico.volDown ico.volDown ico.volUp ];
        };
        tooltip-format = "{desc} · {volume}%";
        on-click = "pavucontrol";
        on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        scroll-step = 5;
      };

      # Red: SOLO icono (el nombre del wifi va en el tooltip, ocupaba media barra)
      network = {
        format-wifi = ico.wifi;
        format-ethernet = ico.ethernet;
        format-disconnected = ico.warning;
        format-linked = ico.warning;
        tooltip-format = "{essid} ({signalStrength}%)";
        on-click = "nm-connection-editor";
      };

      # Batería
      battery = {
        states = { warning = 25; critical = 10; };
        format = "{icon}  {capacity}%";
        format-charging = "${ico.bolt}  {capacity}%";
        format-plugged = "${ico.bolt}  {capacity}%";
        # vacía / 1/4 / 1/2 / 3/4 / llena
        format-icons = [
          ico.batEmpty ico.batQuarter ico.batHalf ico.batThreeQuarter ico.batFull
        ];
        tooltip-format = "{timeTo} · {capacity}%";
      };

      # Botón que abre el CENTRO DE CONTROL (swaync)
      "custom/control" = {
        format = ico.sliders;
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
    # ESTILO (CSS) — Tokyo Night, barra flotante en pastillas
    # =========================================================================
    # Reglas de diseño que se siguen aquí:
    #   - UNA sola fuente de texto (Inter) + Nerd Font para iconos.
    #   - UN solo color de acento (azul #7aa2f7). El resto, texto claro.
    #   - El color SOLO indica estado (batería baja, mute, carga...).
    #   - Espaciado en múltiplos de 4 (4/8/12/16) y nada por debajo de 11px.
    style = ''
      * {
        font-family: "Inter", "JetBrainsMono Nerd Font", "Symbols Nerd Font", sans-serif;
        font-size: 13px;
        font-weight: 500;
        border: none;
        border-radius: 0;
        min-height: 0;
      }

      window#waybar {
        background: transparent;
        color: #c0caf5;
      }

      /* Las tres "pastillas" flotantes */
      .modules-left,
      .modules-center,
      .modules-right {
        background: rgba(22, 22, 30, 0.70);
        border: 1px solid rgba(192, 202, 245, 0.07);
        border-radius: 13px;
        padding: 0 10px;
        margin: 0 4px;
        box-shadow: 0 6px 20px rgba(0, 0, 0, 0.45);
      }

      /* --- Workspaces numerados --- */
      #workspaces {
        padding: 0 2px;
      }
      #workspaces button {
        padding: 0 9px;
        margin: 6px 2px;
        min-width: 16px;
        color: #7f8bb5;
        border-radius: 8px;
        font-weight: 600;
        font-size: 12px;
        transition: all 0.2s ease;
      }
      #workspaces button:hover {
        background: rgba(122, 162, 247, 0.14);
        color: #c0caf5;
      }
      #workspaces button.active {
        background: #7aa2f7;
        color: #16161e;
      }
      #workspaces button.urgent {
        background: #f7768e;
        color: #16161e;
      }

      /* --- Título de ventana --- */
      #window {
        color: #a9b1d6;
        padding: 0 10px 0 6px;
        font-size: 12.5px;
      }

      /* --- Reloj y fecha --- */
      #clock {
        color: #c0caf5;
        font-weight: 600;
        padding: 0 6px 0 10px;
        font-size: 13px;
      }
      #custom-date {
        color: #565f89;
        font-size: 11.5px;
        padding: 0 10px 0 0;
      }

      /* --- Módulos de la derecha: mismo color, icono + número --- */
      #pulseaudio,
      #network,
      #battery {
        padding: 0 8px;
        margin: 0 2px;
        color: #c0caf5;
        min-width: 34px;
      }
      #pulseaudio.muted { color: #565f89; }
      #network.disconnected { color: #565f89; }
      #battery.charging,
      #battery.plugged { color: #9ece6a; }
      #battery.warning:not(.charging) { color: #e0af68; }
      #battery.critical:not(.charging) { color: #f7768e; }

      #tray { padding: 0 8px 0 4px; }
      #tray > .passive { -gtk-icon-effect: dim; }

      /* --- Botones --- */
      #custom-launcher {
        color: #a9b1d6;
        font-family: "JetBrainsMono Nerd Font";
        font-size: 15px;
        padding: 0 8px 0 6px;
      }
      #custom-control {
        color: #a9b1d6;
        font-family: "JetBrainsMono Nerd Font";
        font-size: 15px;
        padding: 0 8px;
      }
      #custom-power {
        color: #565f89;
        font-size: 14px;
        padding: 0 10px 0 6px;
      }

      #custom-launcher:hover,
      #custom-control:hover { color: #7aa2f7; }
      #custom-power:hover { color: #f7768e; }

      tooltip {
        background: rgba(22, 22, 30, 0.97);
        border: 1px solid rgba(122, 162, 247, 0.25);
        border-radius: 10px;
      }
      tooltip label { color: #c0caf5; font-size: 12px; }
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

      # Quitar los "chips" de teclas (F1..F4, pin, start): era UI de debug.
      hide_quick_activation = true;
      hide_action_hints = true;
      hide_return_action = true;

      # Pedir al compositor que difumine detrás (Hyprland lo soporta).
      ext_background_effect_blur = true;
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

        * {
          all: unset;
          font-family: "Inter", "JetBrainsMono Nerd Font", sans-serif;
          font-size: 14px;
        }

        popover {
          background: transparent;
          border: none;
          padding: 0;
        }

        /* El panel en sí */
        .box-wrapper {
          min-width: 620px;
          background: rgba(22, 22, 30, 0.82);
          border: 1px solid rgba(122, 162, 247, 0.16);
          border-radius: 16px;
          padding: 16px;
          box-shadow:
            0 24px 48px rgba(0, 0, 0, 0.55),
            0 8px 16px rgba(0, 0, 0, 0.35);
        }

        .preview-box, .elephant-hint, .placeholder { color: @theme_fg_color; }
        .placeholder { color: #565f89; font-size: 13px; }

        /* Campo de búsqueda: alto y cómodo (antes 25px, parecía una etiqueta) */
        .input {
          caret-color: @theme_fg_color;
          background: #24283b;
          padding: 13px 14px;
          border-radius: 11px;
          color: @theme_fg_color;
          font-size: 14.5px;
        }
        .input placeholder { opacity: 0.5; }
        .input selection { background: rgba(122, 162, 247, 0.35); }

        /* Lista de resultados */
        .list { color: @theme_fg_color; }
        .item-box {
          border-radius: 10px;
          padding: 9px 12px;
          margin: 2px 0;
        }

        /* Selección: fondo azul suave + barra de acento a la izquierda.
           (Antes era un degradado azul->morado que parecía una barra de carga) */
        child:selected .item-box,
        row:selected .item-box {
          background: rgba(122, 162, 247, 0.16);
          box-shadow: inset 3px 0 0 #7aa2f7;
        }

        .item-text-box { font-size: 14px; }
        .item-subtext { font-size: 12px; color: #565f89; }
        .item-image { -gtk-icon-size: 22px; }
        .item-image-text { font-size: 22px; }
        .normal-icons { -gtk-icon-size: 18px; }
        .large-icons { -gtk-icon-size: 48px; }

        .preview {
          border: 1px solid rgba(122, 162, 247, 0.16);
          border-radius: 12px;
          color: @theme_fg_color;
        }

        /* Pie con los atajos: una sola línea discreta */
        .keybinds {
          padding-top: 10px;
          border-top: 1px solid rgba(122, 162, 247, 0.10);
          font-size: 11px;
          color: #565f89;
        }
        .keybind-bind { text-transform: lowercase; opacity: 0.6; }
        .keybind-label {
          padding: 1px 5px;
          border-radius: 4px;
          border: 1px solid rgba(86, 95, 137, 0.5);
        }

        .error { padding: 10px; background: @error_bg_color; color: @error_fg_color; border-radius: 10px; }
      '';
    };
  };

  # ===========================================================================
  # WOFI (solo para menús auxiliares: energía, portapapeles)
  # ===========================================================================
  programs.wofi = {
    enable = true;
    settings = {
      width = 520;
      height = 380;
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
        background-color: rgba(22, 22, 30, 0.96);
        border: 1px solid rgba(122, 162, 247, 0.16);
        border-radius: 16px;
        font-family: "Inter";
        font-size: 14px;
      }
      #input {
        margin: 14px;
        padding: 11px 13px;
        background-color: #24283b;
        color: #c0caf5;
        border: none;
        border-radius: 11px;
      }
      #inner-box { margin: 0 14px 14px 14px; }
      #entry {
        padding: 10px;
        border-radius: 10px;
        color: #c0caf5;
      }
      #entry:selected {
        background: rgba(122, 162, 247, 0.16);
        color: #c0caf5;
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
      control-center-height = 620;
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
        font-family: "Inter", "JetBrainsMono Nerd Font", sans-serif;
        font-size: 13px;
      }

      /* Panel: flotante, con margen real y esquinas suaves */
      .control-center {
        background: rgba(22, 22, 30, 0.74);
        border: 1px solid rgba(192, 202, 245, 0.07);
        border-radius: 16px;
        color: #c0caf5;
        padding: 14px;
        margin: 8px;
      }

      .control-center .widget-title > label {
        color: #c0caf5;
        font-size: 15px;
        font-weight: 600;
      }
      /* "Limpiar" como icono fantasma, no como botón con borde */
      .control-center .widget-title > button {
        background: transparent;
        border: none;
        color: #565f89;
        border-radius: 8px;
        padding: 2px 8px;
        font-size: 12px;
      }
      .control-center .widget-title > button:hover { color: #7aa2f7; }

      /* Fila de "No molestar" como tarjeta */
      .control-center .widget-dnd {
        background: #1f2335;
        border-radius: 12px;
        padding: 10px 12px;
        margin: 6px 0;
        color: #a9b1d6;
      }
      .control-center .widget-dnd > switch {
        background: #292e42;
        border-radius: 12px;
        min-width: 42px;
        min-height: 22px;
        border: none;
        box-shadow: none;
        outline: none;
      }
      .control-center .widget-dnd > switch:checked { background: #7aa2f7; }
      .control-center .widget-dnd > switch slider {
        background: #c0caf5;
        border-radius: 50%;
        min-width: 18px;
        min-height: 18px;
        border: none;
      }

      /* Notificaciones */
      .notification-row { padding: 3px 0; }
      .notification {
        background: #1f2335;
        border: 1px solid rgba(122, 162, 247, 0.10);
        border-radius: 12px;
        color: #c0caf5;
        margin: 3px 0;
      }
      .notification-content { padding: 10px; }
      .notification-default-action:hover { background: rgba(122, 162, 247, 0.06); }
      .close-button {
        background: transparent;
        color: #565f89;
        border-radius: 50%;
        margin: 6px;
      }
      .close-button:hover { background: rgba(247, 118, 142, 0.16); color: #f7768e; }

      /* Estado vacío: icono discreto, no una imagen raster ampliada */
      .control-center .empty-state image {
        -gtk-icon-size: 40px;
        opacity: 0.25;
        margin-bottom: 4px;
      }
      .control-center .empty-state label {
        color: #565f89;
        font-size: 12px;
      }

      /* Sliders: pista fina, relleno azul, pomo pequeño */
      .control-center scale trough {
        background: #292e42;
        border-radius: 8px;
        min-height: 6px;
        border: none;
      }
      .control-center scale trough highlight {
        background: #7aa2f7;
        border-radius: 8px;
      }
      .control-center scale slider {
        background: #c0caf5;
        border-radius: 50%;
        min-width: 12px;
        min-height: 12px;
        border: none;
        box-shadow: none;
      }
      .control-center .widget-volume,
      .control-center .widget-backlight { color: #a9b1d6; }
      .control-center .widget-battery { color: #c0caf5; }

      /* MPRIS (reproductor) */
      .control-center .widget-mpris {
        background: #1f2335;
        border-radius: 12px;
        padding: 10px;
        margin: 6px 0;
      }
      .control-center .widget-mpris-title { color: #c0caf5; font-weight: 600; font-size: 13px; }
      .control-center .widget-mpris-subtitle { color: #565f89; font-size: 12px; }
      .control-center .widget-mpris button {
        background: transparent;
        color: #a9b1d6;
        border: none;
        border-radius: 8px;
      }
      .control-center .widget-mpris button:hover { color: #7aa2f7; }

      /* Grid de botones (si se añade más adelante) */
      .control-center .widget-buttons-grid > flowbox > flowboxchild > button {
        background: #1f2335;
        color: #a9b1d6;
        border-radius: 12px;
        margin: 3px;
        padding: 10px;
        border: none;
      }
      .control-center .widget-buttons-grid > flowbox > flowboxchild > button:hover {
        background: rgba(122, 162, 247, 0.16);
        color: #c0caf5;
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

      # Fondo: el mismo wallpaper, difuminado. Mucho más elegante que negro.
      background = [
        {
          monitor = "";
          path = "/etc/tokyo-night-wallpaper.png";
          blur_passes = 3;
          blur_size = 8;
          brightness = 0.5;
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "260, 48";
          outline_thickness = 2;
          dots_center = true;
          rounding = 12;
          outer_color = "rgb(7aa2f7)";
          inner_color = "rgba(22, 22, 30, 0.9)";
          font_color = "rgb(c0caf5)";
          placeholder_text = "Contraseña…";
          fade_on_empty = false;
          position = "0, -120";
          halign = "center";
          valign = "center";
        }
      ];

      label = [
        {
          monitor = "";
          text = "$TIME";
          color = "rgb(c0caf5)";
          font_size = 96;
          font_family = "Inter";
          position = "0, 120";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "macnix · NixOS";
          color = "rgb(86, 95, 137)";
          font_size = 14;
          font_family = "Inter";
          position = "0, 60";
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
