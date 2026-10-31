#!/usr/bin/env bash
# =============================================================================
# scripts/power-times.sh  —  Menú wofi para cambiar los tiempos de hypridle
# =============================================================================
# Uso: power-times
#
# Cambia EN CALIENTE (sin recompilar) cuándo se apaga la pantalla y cuándo se
# suspende, escribiendo ~/.config/hypridle/custom.conf y reiniciando hypridle.
#
# El servicio hypridle (modules/home/bar.nix) usa custom.conf si existe; si no,
# usa la config por defecto de Nix.
# =============================================================================
set -euo pipefail

CONF="$HOME/.config/hypridle/custom.conf"

# ------------------------------------------------------------------- selección
screen_choice="$(
  printf '%s\n' \
    "Apagar pantalla: 2 min" \
    "Apagar pantalla: 5 min" \
    "Apagar pantalla: 10 min" \
    "Apagar pantalla: 15 min" \
    "Apagar pantalla: nunca" \
    | wofi --dmenu --prompt 'Tiempos de inactividad' --width 420 --height 320
)"
[ -n "$screen_choice" ] || exit 0
screen_min=$(printf '%s' "$screen_choice" | sed -n 's/.*: \([0-9]*\) min/\1/p')

suspend_choice="$(
  printf '%s\n' \
    "Suspender: 15 min" \
    "Suspender: 30 min" \
    "Suspender: 60 min" \
    "Suspender: nunca" \
    | wofi --dmenu --prompt 'Tiempos de inactividad' --width 420 --height 320
)"
[ -n "$suspend_choice" ] || exit 0
suspend_min=$(printf '%s' "$suspend_choice" | sed -n 's/.*: \([0-9]*\) min/\1/p')

# --------------------------------------------------------- construir la config
mk_listener() { # $1=timeout-seg  $2=on-timeout  $3=on-resume(opcional)
  {
    echo 'listener {'
    echo "    timeout = $1"
    echo "    on-timeout = $2"
    [ -n "${3:-}" ] && echo "    on-resume = $3"
    echo '}'
  } >> "$CONF"
}

mkdir -p "$(dirname "$CONF")"
cat > "$CONF" <<'EOF'
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}
EOF

# Apagar pantalla (bloqueo a 5 min fijo + pantalla off al tiempo elegido)
mk_listener 300 "loginctl lock-session"
if [ -n "$screen_min" ]; then
  mk_listener $((screen_min * 60)) "hyprctl dispatch dpms off" "hyprctl dispatch dpms on"
fi
if [ -n "$suspend_min" ]; then
  mk_listener $((suspend_min * 60)) "systemctl suspend"
fi

# ------------------------------------------------------------------ reiniciar
systemctl --user restart hypridle 2>/dev/null || {
  setsid "${HYPRIDLE:-hypridle}" -c "$CONF" >/dev/null 2>&1 &
  disown
}
notify-send -a "Energía" "Tiempos actualizados" \
  "Pantalla: ${screen_min:-nunca} min · Suspender: ${suspend_min:-nunca} min" 2>/dev/null || true
