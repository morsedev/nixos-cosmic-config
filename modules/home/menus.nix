# =============================================================================
# modules/home/menus.nix  —  Menús del sistema con wofi (wifi, bluetooth)
# =============================================================================
# Las apps "clásicas" de escritorio (nm-connection-editor, blueman...) se ven
# como de otro sistema operativo. Aquí creamos dos menús hechos con wofi +
# nmcli/bluetoothctl, que usan EXACTAMENTE el mismo estilo que el resto del
# escritorio (Tokyo Night, mismo redondeo, misma tipografía).
#
# Se abren con:
#   Super + N   → Wi-Fi
#   Super + B   → Bluetooth
# =============================================================================

{ config, pkgs, lib, ... }:

{
  home.packages = [
    # -------------------------------------------------------------------------
    # WIFI  (Super + N)
    # -------------------------------------------------------------------------
    (pkgs.writeShellScriptBin "wifi" ''
      set -uo pipefail
      notify() { notify-send -a "Wi-Fi" "$1" "''${2:-}" 2>/dev/null || true; }

      # --- Wi-Fi apagado: ofrecer encenderlo ---
      if [ "$(nmcli radio wifi)" != "enabled" ]; then
        choice="$(printf '%s\n' "󰖩  Encender Wi-Fi" | wofi --dmenu --prompt 'Wi-Fi' --width 420 --height 160)"
        [ -n "$choice" ] && nmcli radio wifi on && notify "Wi-Fi encendido"
        exit 0
      fi

      # --- Red conectada actualmente ---
      active="$(nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2=="802-11-wireless"{print $1; exit}')"

      # --- Lista de redes ---
      # Formato de cada línea:  "<icono>| <SSID>"
      # El separador "| " nos permite sacar el SSID sin ambigüedad.
      networks="$(nmcli -t -f IN-USE,SSID,SECURITY device wifi list --rescan yes 2>/dev/null \
        | awk -F: 'NF>=2 && $2!="" {
            mark  = ($1=="*") ? "󰄬" : (($3!="" && $3!="--") ? "󰌾" : " ");
            print mark "| " $2
          }' | sort -u -t'|' -k2)"

      # OJO con el orden: wofi preselecciona la PRIMERA línea, así que las
      # redes van arriba y las acciones destructivas (apagar) al final.
      choice="$(printf '%s\n%s\n%s\n' \
        "$networks" \
        "󰒓  Editor de red (avanzado)" \
        "󰖪  Apagar Wi-Fi" \
        | wofi --dmenu --dynamic-lines --prompt 'Wi-Fi' --width 460 --height 460)"

      case "$choice" in
        "")                     exit 0 ;;
        *"Apagar Wi-Fi")        nmcli radio wifi off; notify "Wi-Fi apagado"; exit 0 ;;
        *"Editor de red")       exec nm-connection-editor ;;
      esac

      ssid="''${choice#*| }"

      if [ "$ssid" = "$active" ]; then
        notify "Ya estás conectado" "$ssid"
        exit 0
      fi

      # --- ¿Red ya guardada? Conectar directo : pedir contraseña ---
      if nmcli -t -f NAME connection show | grep -Fqx "$ssid"; then
        nmcli connection up id "$ssid" >/dev/null 2>&1 \
          && notify "Conectado" "$ssid" \
          || notify "Error" "No se pudo conectar a $ssid"
      else
        pass="$(wofi --dmenu --password --prompt "Contraseña de $ssid" --width 420 --height 160)"
        [ -z "$pass" ] && exit 0
        nmcli device wifi connect "$ssid" password "$pass" >/dev/null 2>&1 \
          && notify "Conectado" "$ssid" \
          || notify "Error" "Contraseña incorrecta o red fuera de alcance"
      fi
    '')

    # -------------------------------------------------------------------------
    # BLUETOOTH  (Super + B)
    # -------------------------------------------------------------------------
    (pkgs.writeShellScriptBin "bluetooth" ''
      set -uo pipefail
      notify() { notify-send -a "Bluetooth" "$1" "''${2:-}" 2>/dev/null || true; }

      powered="$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2; exit}')"

      if [ "$powered" != "yes" ]; then
        choice="$(printf '%s\n' "󰂯  Encender Bluetooth" | wofi --dmenu --prompt 'Bluetooth' --width 420 --height 160)"
        [ -n "$choice" ] && bluetoothctl power on >/dev/null && notify "Bluetooth encendido"
        exit 0
      fi

      # Lista: "<estado>| <nombre>| <MAC>"  (estado = conectado o libre)
      list="$(
        bluetoothctl devices 2>/dev/null | while read -r _ mac name; do
          [ -n "''${name:-}" ] || name="$mac"
          if bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
            echo "󰄬| $name| $mac"
          else
            echo " | $name| $mac"
          fi
        done
      )"

      choice="$(printf '%s\n%s\n%s\n' \
        "$list" \
        "󰐕  Emparejar dispositivo nuevo" \
        "󰂲  Apagar Bluetooth" \
        | wofi --dmenu --dynamic-lines --prompt 'Bluetooth' --width 460 --height 420)"

      case "$choice" in
        "")                       exit 0 ;;
        *"Apagar Bluetooth")      bluetoothctl power off >/dev/null; notify "Bluetooth apagado"; exit 0 ;;
        *"Emparejar dispositivo") exec ghostty --class=bt-pair -e bluetoothctl ;;
      esac

      mac="$(printf '%s' "$choice" | awk -F'| ' '{print $NF}')"
      name="$(printf '%s' "$choice" | awk -F'| ' '{print $(NF-1)}')"

      if bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
        bluetoothctl disconnect "$mac" >/dev/null 2>&1 && notify "Desconectado" "$name"
      else
        bluetoothctl connect "$mac" >/dev/null 2>&1 && notify "Conectado" "$name" \
          || notify "Error" "No se pudo conectar con $name"
      fi
    '')
  ];
}
