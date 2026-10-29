# =============================================================================
# modules/touchbar.nix  —  Layouts de la Touch Bar y comando `touchbar`
# =============================================================================
#
# tiny-dfr solo admite botones estáticos + reloj y batería en vivo, pero sí
# permite elegir QUÉ botones salen. Aquí definimos varios "layouts" y un
# comando para cambiar entre ellos sin recompilar:
#
#   touchbar            → menú (wofi)
#   touchbar media      → brillo, volumen, play, reloj, batería, atajos
#   touchbar minimal    → solo reloj + batería + brillo
#   touchbar dev        → reloj + Term/Apps/Shot + batería
#   touchbar fkeys      → teclas F1–F12 clásicas
#
# El atajo es:  Super + Shift + T
#
# OJO: `touchbar` necesita root para escribir /etc y reiniciar el servicio;
# por eso usa `sudo` (en este equipo no pide contraseña).
# =============================================================================

{ config, pkgs, lib, ... }:

let
  toml = pkgs.formats.toml { };

  # Ajustes comunes a todos los layouts.
  base = {
    ShowButtonOutlines = false;   # sin recuadros: solo icono/texto
    EnablePixelShift = true;      # mueve el contenido para cuidar el panel
    FontTemplate = ":bold";       # negrita: se lee mejor a 60 px de alto
    AdaptiveBrightness = true;    # el brillo sigue al de la pantalla
    ActiveBrightness = 200;       # máximo más alto para que se vea bien
    DoublePressSwitchLayers = 0;  # sin cambio de capa por doble Fn
  };

  # --- Botones reutilizables -------------------------------------------------
  keyBrightnessDown = { Icon = "brightness_low"; Action = "BrightnessDown"; };
  keyBrightnessUp = { Icon = "brightness_high"; Action = "BrightnessUp"; };
  keyVolumeDown = { Icon = "volume_down"; Action = "VolumeDown"; };
  keyVolumeUp = { Icon = "volume_up"; Action = "VolumeUp"; };
  keyPlayPause = { Icon = "play_pause"; Action = "PlayPause"; };
  keyClock = { Time = "%H:%M"; Action = "Time"; Stretch = 2; };
  keyBattery = { Battery = "both"; Action = "Battery"; Stretch = 2; };
  keyTerm = { Text = "Term"; Action = [ "LeftMeta" "Return" ]; };
  keyApps = { Text = "Apps"; Action = [ "LeftMeta" "D" ]; };
  keyShot = { Text = "Shot"; Action = [ "LeftMeta" "S" ]; };

  # --- Layouts ---------------------------------------------------------------
  presets = {
    # El completo: lo normal del día a día.
    media = base // {
      MediaLayerDefault = true;
      MediaLayerKeys = [
        keyBrightnessDown
        keyBrightnessUp
        keyVolumeDown
        keyVolumeUp
        keyPlayPause
        keyClock
        keyBattery
        keyTerm
        keyApps
        keyShot
      ];
    };

    # Mínimo: solo lo que se consulta de un vistazo.
    minimal = base // {
      MediaLayerDefault = true;
      MediaLayerKeys = [
        keyBrightnessDown
        keyBrightnessUp
        { Time = "%H:%M"; Action = "Time"; Stretch = 3; }
        { Battery = "both"; Action = "Battery"; Stretch = 3; }
      ];
    };

    # Desarrollo: atajos grandes y reloj.
    dev = base // {
      MediaLayerDefault = true;
      MediaLayerKeys = [
        { Time = "%H:%M"; Action = "Time"; Stretch = 2; }
        { Text = "Term"; Action = [ "LeftMeta" "Return" ]; Stretch = 2; }
        { Text = "Apps"; Action = [ "LeftMeta" "D" ]; Stretch = 2; }
        { Text = "Shot"; Action = [ "LeftMeta" "S" ]; Stretch = 2; }
        { Battery = "both"; Action = "Battery"; Stretch = 2; }
      ];
    };

    # Teclas de función clásicas.
    fkeys = base // {
      MediaLayerDefault = false;
      MediaLayerKeys = map
        (n: { Text = "F${toString n}"; Action = "F${toString n}"; })
        (lib.range 1 12);
    };
  };
  # ---------------------------------------------------------------------------
  # GATO ANIMADO (prototipo)
  # ---------------------------------------------------------------------------
  # `touchbar-pet` escribe directamente en el panel (DRM) un gato que mueve las
  # patas cuando tecleas, más el reloj y la batería.
  #
  # NO puede convivir con tiny-dfr: los dos quieren el mismo dispositivo. Por
  # eso hay un comando para alternar entre ambos:
  #
  #   touchbar-pet on    -> para tiny-dfr y arranca el gato
  #   touchbar-pet off   -> para el gato y vuelve a los botones de tiny-dfr
  #   touchbar-pet status
  #
  # Si algo va mal, `touchbar-pet off` devuelve la Touch Bar a su estado normal.
  touchbar-pet = pkgs.stdenv.mkDerivation {
    pname = "touchbar-pet";
    version = "0.1.0";
    src = ../touchbar-pet;
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.libdrm pkgs.libinput ];
    buildPhase = ''
      $CC -O2 -Wall -o touchbar-pet pet.c \
        $(pkg-config --cflags --libs libdrm libinput) -lm
    '';
    installPhase = ''
      install -Dm755 touchbar-pet $out/bin/touchbar-petd
    '';
  };
in
{
  # Cada layout se instala como /etc/tiny-dfr/presets/<nombre>.toml
  environment.etc = lib.mapAttrs'
    (name: value: lib.nameValuePair "tiny-dfr/presets/${name}.toml" {
      source = toml.generate "touchbar-${name}.toml" value;
    })
    presets;

  # Servicio del gato (arranca solo cuando se pide con `touchbar-pet on`)
  systemd.services.touchbar-pet = {
    description = "Gato animado en la Touch Bar";
    serviceConfig = {
      ExecStart = "${touchbar-pet}/bin/touchbar-petd --run";
      Restart = "no";
      # Necesita acceso al DRM y a los dispositivos de entrada.
      SupplementaryGroups = [ "input" ];
    };
  };

  # Comando `touchbar-pet` (on/off/status)


  # Comando `touchbar`
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "touchbar" ''
      set -euo pipefail

      dir=/etc/tiny-dfr/presets
      list="$(cd "$dir" && ls *.toml | sed 's/\.toml$//')"

      case "''${1:-menu}" in
        menu)
          choice="$(printf '%s\n' "$list" \
            | wofi --dmenu --dynamic-lines --prompt 'Touch Bar' \
                   --width 360 --height 280)" || exit 0
          [ -n "$choice" ] || exit 0
          preset="$choice"
          ;;
        *)
          preset="$1"
          ;;
      esac

      if [ ! -f "$dir/$preset.toml" ]; then
        notify-send -a "Touch Bar" "Layout desconocido" "$preset" 2>/dev/null || true
        exit 1
      fi

      # Sustituye el config.toml (que es un enlace de solo lectura al store)
      # y reinicia el daemon para aplicar el cambio.
      sudo rm -f /etc/tiny-dfr/config.toml
      sudo install -m 0644 "$dir/$preset.toml" /etc/tiny-dfr/config.toml
      sudo systemctl restart tiny-dfr

      notify-send -a "Touch Bar" "Layout aplicado" "$preset" 2>/dev/null || true
    '')
    (pkgs.writeShellScriptBin "touchbar-pet" ''
      case "''${1:-status}" in
        on)
          sudo systemctl stop tiny-dfr 2>/dev/null || true
          sudo systemctl start touchbar-pet
          notify-send -a "Touch Bar" "Gato activado" 2>/dev/null || true
          ;;
        off)
          sudo systemctl stop touchbar-pet 2>/dev/null || true
          sudo systemctl start tiny-dfr
          notify-send -a "Touch Bar" "Botones restaurados" 2>/dev/null || true
          ;;
        status)
          printf 'tiny-dfr:     %s\n' "$(systemctl is-active tiny-dfr)"
          printf 'touchbar-pet: %s\n' "$(systemctl is-active touchbar-pet)"
          ;;
        *)
          echo "uso: touchbar-pet on|off|status"
          exit 1
          ;;
      esac
    '')
    # Convertir cualquier imagen en sprite de la Touch Bar
    pkgs.imagemagick

    (pkgs.writeShellScriptBin "touchbar-sprite" ''
      set -euo pipefail
      if [ $# -lt 1 ]; then
        echo "uso: touchbar-sprite <imagen>"
        echo "  Convierte cualquier PNG/JPG/GIF (un fotograma) en el sprite"
        echo "  que dibuja touchbar-pet. Ejemplo:"
        echo "    touchbar-sprite ~/gato.png"
        exit 1
      fi

      src="$1"
      [ -f "$src" ] || { echo "no existe: $src"; exit 1; }

      tmpd="$(mktemp -d)"
      n="$(magick identify "$src" 2>/dev/null | wc -l)"
      if [ "$n" -gt 1 ]; then
        # GIF animado: un fotograma por fichero (el daemon los anima al teclear)
        magick "$src" -coalesce -background '#16161e' -alpha remove -alpha off \
               -resize 'x56>' -depth 8 "$tmpd/f-%03d.ppm"
      else
        magick "$src" -background '#16161e' -alpha remove -alpha off \
               -resize 'x56>' -depth 8 "$tmpd/f-000.ppm"
      fi

      sudo rm -rf /etc/touchbar-pet/frames
      sudo mkdir -p /etc/touchbar-pet/frames
      sudo install -m 0644 "$tmpd"/*.ppm /etc/touchbar-pet/frames/
      rm -rf "$tmpd"
      sudo systemctl restart touchbar-pet 2>/dev/null || true
      notify-send -a "Touch Bar" "Sprite actualizado" "$(basename "$src")" 2>/dev/null || true
      sudo systemctl restart touchbar-pet 2>/dev/null || true
      notify-send -a "Touch Bar" "Sprite actualizado" "$(basename "$src")" 2>/dev/null || true
    '')

    (pkgs.writeShellScriptBin "touchbar-shot" ''
      set -euo pipefail
      pid="$(pgrep -f touchbar-petd | head -1)"
      [ -n "$pid" ] || { echo "touchbar-pet no está en marcha"; exit 1; }
      if [ "''${1:-}" = "--storm" ]; then
        sudo kill -USR2 "$pid"
      else
        sudo kill -USR1 "$pid"
      fi
      sleep 1
      cat /tmp/touchbar-shot.ppm > "''${2:-/tmp/touchbar-shot-local.ppm}"
      echo "captura en ''${2:-/tmp/touchbar-shot-local.ppm}"
    '')

  ];
}
