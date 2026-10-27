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

let
  # ---------------------------------------------------------------------------
  # CHULETA DE ATAJOS  (Super + /)
  # ---------------------------------------------------------------------------
  # `hyprkeys` lee los atajos REALES del compositor (hyprctl binds) y los pinta
  # agrupados en español. Al añadir un atajo nuevo aparece solo.
  # `flakeIgnore` desactiva el aviso de "línea demasiado larga" (E501): el
  # script tiene textos largos a propósito y se lee mejor así.
  hyprkeys = pkgs.writers.writePython3Bin "hyprkeys" {
    flakeIgnore = [ "E501" ];
  } ./hyprkeys.py;

  # ---------------------------------------------------------------------------
  # CAMBIAR DE FONDO  (Super + W / Super + Shift + W)
  # ---------------------------------------------------------------------------
  # Script pequeño con tres modos:
  #   wallpaper restore   -> aplica el último usado (al iniciar sesión)
  #   wallpaper next      -> pasa al siguiente de la lista
  #   wallpaper menu      -> abre un menú para elegir
  # Guarda la elección en ~/.cache/wallpaper para recordarla al reiniciar.
  wallpaper = pkgs.writeShellScriptBin "wallpaper" ''
    set -euo pipefail

    dir=/etc/wallpapers
    cache="''${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper"
    mkdir -p "$(dirname "$cache")"

    # OJO: /etc/wallpapers son enlaces simbólicos, así que hay que aceptar
    # tanto ficheros normales (-type f) como enlaces (-type l).
    mapfile -t files < <(find "$dir" -maxdepth 1 \( -type f -o -type l \) \( -iname '*.jpg' -o -iname '*.png' \) | sort)
    if [ "''${#files[@]}" -eq 0 ]; then
      notify-send "Fondos" "No hay imágenes en $dir" 2>/dev/null || true
      exit 1
    fi

    current=""
    [ -f "$cache" ] && current="$(cat "$cache")"

    case "''${1:-restore}" in
      restore)
        pick="''${current:-''${files[0]}}"
        ;;
      next)
        idx=-1
        for i in "''${!files[@]}"; do
          [ "''${files[$i]}" = "$current" ] && idx=$i
        done
        pick="''${files[$(( (idx + 1) % ''${#files[@]} ))]}"
        ;;
      menu)
        name="$(printf '%s\n' "''${files[@]}" | xargs -n1 basename | wofi --dmenu --prompt 'Fondo' --width 420 --height 320 || true)"
        [ -n "$name" ] || exit 0
        pick="$dir/$name"
        ;;
      *)
        pick="$dir/$1"
        ;;
    esac

    [ -f "$pick" ] || pick="''${files[0]}"

    pkill -f 'swaybg -i' 2>/dev/null || true
    setsid -f swaybg -i "$pick" -m fill >/dev/null 2>&1
    echo "$pick" > "$cache"
    notify-send -a wallpaper "Fondo de pantalla" "$(basename "$pick")" 2>/dev/null || true
  '';

  # Abre la chuleta en una ventana flotante y centrada.
  # El prefijo [float;center;size W H] es una "regla de ejecución" de Hyprland.
  # `lib.getExe` da la ruta absoluta del programa: así el atajo funciona aunque
  # el PATH de la sesión no incluya el perfil del usuario.
  hyprkeys-open = pkgs.writeShellScriptBin "hyprkeys-open" ''
    exec hyprctl dispatch exec "[float;center;size 1180 820] ghostty -e ${lib.getExe hyprkeys}"
  '';
in
{
  # Los dos comandos quedan disponibles en la terminal.
  home.packages = [ hyprkeys hyprkeys-open wallpaper ];

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

      # Variables de entorno de la sesión.
      # El cursor es lo primero que "delata" un escritorio sin personalizar.
      env = [
        "XCURSOR_THEME,Bibata-Modern-Ice"
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_THEME,Bibata-Modern-Ice"
        "HYPRCURSOR_SIZE,24"
      ];

      # --- Apariencia general ---
      general = {
        gaps_in = 5;
        gaps_out = 12;
        border_size = 2;

        layout = "dwindle";
        resize_on_border = true;
        allow_tearing = false;
      };

      # --- Decoración (redondeo, sombras, blur) ---
      decoration = {
        rounding = 14;
        # Un pelín de transparencia: deja ver el blur del fondo.
        active_opacity = 0.97;
        inactive_opacity = 0.90;
        fullscreen_opacity = 1.0;

        shadow = {
          enabled = true;
          range = 24;
          render_power = 3;
          color = lib.mkForce "rgba(00000066)";
        };

        blur = {
          enabled = true;
          size = 7;
          passes = 3;
          new_optimizations = true;
          xray = false;
          noise = 0.02;
          contrast = 1.05;
          brightness = 0.9;
          popups = true;
        };
      };

      # --- Animaciones suaves ---
      animations = {
        enabled = true;
        bezier = [
          "ease,0.05,0.9,0.1,1"
          "linear,0,0,1,1"
        ];
        animation = [
          "windows,1,4,ease"
          "windowsOut,1,4,ease"
          "windowsMove,1,4,ease"
          "fade,1,8,ease"
          "fadeOut,1,8,ease"
          "workspaces,1,4,ease"
          "border,1,8,ease"
          "borderangle,1,30,linear,loop"
          "specialWorkspace,1,4,ease"
          "layers,1,3,ease"
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
        preserve_split = true;
      };
      master.new_status = "master";

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      # --- Reglas de CAPAS (waybar, walker, swaync) ---
      # `blur <namespace>` difumina lo que hay DETRÁS de esa capa.
      # Así los paneles translúcidos se ven "de cristal" sobre el wallpaper.
      #
      # OJO (Hyprland 0.56): la sintaxis nueva separa con ESPACIO, no con coma.
      # `layerrule = blur, walker` (formato antiguo) ya NO es válido.
      #
      # Tampoco aplicamos blur a `waybar`: su capa ocupa todo el ancho de la
      # pantalla y difuminaría una franja completa en vez de solo la barra.
      layerrule = [
        "blur walker"
        "blur swaync-control-center"
        "blur swaync-notification-window"
      ];

      # --- Programas que arrancan con la sesión ---
      exec-once = [
        "waybar"

        # Fondo de pantalla (restaura el último elegido con Super+W).
        "${lib.getExe wallpaper} restore"

        # Icono de red y diálogos de permisos.
        "nm-applet --indicator"
        "/run/current-system/sw/libexec/polkit-gnome-authentication-agent-1"

        # Guardar el portapapeles en el historial (sin esto `Super+C` sale vacío).
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"

        # Cursor coherente en toda la sesión.
        "hyprctl setcursor Bibata-Modern-Ice 24"
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

        # Bloqueo y capturas
        "$mod, L, exec, hyprlock"
        "$mod, S, exec, grim -g \"$(slurp)\" - | satty --filename -"
        "$mod SHIFT, S, exec, grim - | satty --filename -"

        # Portapapeles
        "$mod, C, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"

        # Chuleta de atajos (ventana flotante)
        "$mod, slash, exec, ${lib.getExe hyprkeys-open}"

        # Menús del sistema
        "$mod, N, exec, wifi"
        "$mod, B, exec, bluetooth"
        "$mod, A, exec, pwvucontrol"

        # Fondos de pantalla
        "$mod, W, exec, ${lib.getExe wallpaper} next"
        "$mod SHIFT, W, exec, ${lib.getExe wallpaper} menu"

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


    };

    # -------------------------------------------------------------------------
    # LÍNEAS ESCRITAS A MANO EN hyprland.conf
    # -------------------------------------------------------------------------
    # El borde con degradado hay que escribirlo aquí porque el módulo de Home
    # Manager convierte la clave "col.active_border" en un bloque anidado
    # (`col { active_border = ... }`) que Hyprland 0.56 no entiende.
    # Con `general { col.algo = ... }` le llega la sintaxis correcta.
    extraConfig = ''
      # Borde ACTIVO: degradado azul -> morado en diagonal (45deg).
      # Es el truco más barato para que una ventana parezca "premium".
      general {
        col.active_border = rgba(7aa2f7ee) rgba(bb9af7ee) 45deg
        col.inactive_border = rgba(292e42ff)
      }
    '';
  };
}
