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
in
{
  # Cada layout se instala como /etc/tiny-dfr/presets/<nombre>.toml
  environment.etc = lib.mapAttrs'
    (name: value: lib.nameValuePair "tiny-dfr/presets/${name}.toml" {
      source = toml.generate "touchbar-${name}.toml" value;
    })
    presets;

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
  ];
}
