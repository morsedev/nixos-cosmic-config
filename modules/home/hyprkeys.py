"""hyprkeys — chuleta de atajos de Hyprland.

Lee los atajos REALES del compositor con `hyprctl -j binds` y los pinta
agrupados y en español. Si añades un atajo nuevo a modules/home/hyprland.nix y
no aparece abajo, saldrá automáticamente en el grupo "OTROS", así que nunca se
queda desactualizado.

Se abre con:  Super + /
"""

import subprocess

# ---------------------------------------------------------------------------
# COLORES (24 bits, paleta Tokyo Night)
# ---------------------------------------------------------------------------

RESET = "\033[0m"
BOLD = "\033[1m"


def rgb(h):
    """Convierte "7aa2f7" en una secuencia ANSI de color de 24 bits."""
    return "\033[38;2;%d;%d;%dm" % (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


BLUE = rgb("7aa2f7")
PURPLE = rgb("bb9af7")
CYAN = rgb("7dcfff")
FG = rgb("c0caf5")
DIM = rgb("565f89")
GREEN = rgb("9ece6a")
YELLOW = rgb("e0af68")
RED = rgb("f7768e")

# Bits del modificador (los mismos valores que usa Hyprland).
MOD_BITS = [(64, "Super"), (8, "Alt"), (4, "Ctrl"), (1, "Shift")]

MOUSE = {
    "mouse:272": "Click izq.",
    "mouse:273": "Click der.",
    "mouse_down": "Scroll abajo",
    "mouse_up": "Scroll arriba",
}

KEYNAMES = {
    "RETURN": "Enter",
    "slash": "/",
    "left": "←",
    "right": "→",
    "up": "↑",
    "down": "↓",
}

# Teclas de función del Mac -> (etiqueta corta, qué hace)
MEDIA = {
    "XF86AudioRaiseVolume": ("Volumen +", "Subir el volumen"),
    "XF86AudioLowerVolume": ("Volumen −", "Bajar el volumen"),
    "XF86AudioMute": ("Silencio", "Silenciar / reactivar"),
    "XF86MonBrightnessUp": ("Brillo +", "Subir el brillo"),
    "XF86MonBrightnessDown": ("Brillo −", "Bajar el brillo"),
    "XF86AudioPlay": ("Play/Pausa", "Reproducir o pausar"),
    "XF86AudioNext": ("Siguiente", "Siguiente canción"),
    "XF86AudioPrev": ("Anterior", "Canción anterior"),
}


def key_label(bind):
    """Devuelve 'Super + Shift + Q' a partir de un bind de hyprctl."""
    parts = [name for bit, name in MOD_BITS if bind["modmask"] & bit]
    raw = bind["key"] or ""
    if bind["mouse"]:
        raw = "mouse:" + raw
    key = MOUSE.get(raw, KEYNAMES.get(raw, raw))
    if len(key) == 1:
        key = key.upper()
    parts.append(key)
    return " + ".join(parts)


# ---------------------------------------------------------------------------
# AGRUPACIÓN Y DESCRIPCIONES
# ---------------------------------------------------------------------------
# Cada fila: (dispatcher, arg exacto, descripción). Si el atajo no existe en la
# config actual, la fila simplemente no se muestra.

SECTIONS = [
    ("LANZAR", [
        ("exec", "ghostty", "Terminal (Ghostty)"),
        ("exec", "walker", "Lanzador de aplicaciones"),
        ("exec", "nautilus", "Archivos (Nautilus)"),
    ]),
    ("VENTANAS", [
        ("killactive", "", "Cerrar la ventana activa"),
        ("fullscreen", "", "Pantalla completa"),
        ("togglefloating", "", "Flotante / mosaico"),
        ("pseudo", "", "Pseudo-mosaico (tiling)"),
        ("exit", "", "Cerrar sesión de Hyprland"),
    ]),
    ("MOVERSE", [
        ("movefocus", "l", "Foco a la izquierda"),
        ("movefocus", "r", "Foco a la derecha"),
        ("movefocus", "u", "Foco arriba"),
        ("movefocus", "d", "Foco abajo"),
        ("workspace", "e+1", "Workspace siguiente"),
        ("workspace", "e-1", "Workspace anterior"),
    ]),
    ("CAPTURAS Y BLOQUEO", [
        ("exec", "hyprlock", "Bloquear la pantalla"),
        ("exec", 'grim -g "$(slurp)" - | satty --filename -', "Captura de una región"),
        ("exec", "grim - | satty --filename -", "Captura de toda la pantalla"),
    ]),
    ("ESCRITORIO", [
        ("exec", "wallpaper next", "Siguiente fondo de pantalla"),
        ("exec", "wallpaper menu", "Elegir fondo de pantalla"),
    ]),
    ("AYUDA", [
        ("exec", "hyprkeys-open", "Esta chuleta de atajos"),
    ]),
    ("PORTAPAPELES", [
        ("exec", "cliphist list | wofi --dmenu | cliphist decode | wl-copy", "Historial de copiado"),
    ]),
]

# Workspaces: se muestran como rango "Super + 1 … 9".
WORKSPACE_ROWS = [
    ("workspace", "Ir al workspace {}"),
    ("movetoworkspace", "Mover ventana al workspace {}"),
]


def load_binds():
    """Lee `hyprctl binds` (texto) y devuelve una lista de diccionarios.

    Nota: en Hyprland 0.56 la salida `-j` (JSON) está rota (campos
    desalineados), así que parseamos el formato de texto, que sí es fiable:

        bind
            modmask: 64
            key: RETURN
            dispatcher: exec
            arg: ghostty
    """
    out = subprocess.run(["hyprctl", "binds"], capture_output=True, text=True)
    if out.returncode != 0:
        return []

    binds = []
    current = None
    for line in out.stdout.splitlines():
        stripped = line.strip()
        if stripped in ("bind", "bindm"):
            current = {
                "modmask": 0,
                "key": "",
                "dispatcher": "",
                "arg": "",
                "mouse": False,
            }
            binds.append(current)
            continue
        if current is None or ":" not in stripped:
            continue
        name, value = stripped.split(":", 1)
        name, value = name.strip(), value.strip()
        if name == "modmask":
            current["modmask"] = int(value or "0")
        elif name == "mouse":
            current["mouse"] = value == "true"
        elif name in ("key", "dispatcher", "arg"):
            current[name] = value
    return binds


def index(binds):
    """(dispatcher, arg) -> bind"""
    return {(b["dispatcher"], (b["arg"] or "").strip()): b for b in binds}


def find_bind(table, dispatcher, arg):
    """Busca un atajo por dispatcher+arg, tolerando rutas absolutas.

    El atajo de esta chuleta se ejecuta con la ruta completa de
    /nix/store/.../hyprkeys-open, así que comparamos también por sufijo para
    no mostrar rutas internas en pantalla.
    """
    exact = table.get((dispatcher, arg))
    if exact is not None:
        return exact, (dispatcher, arg)
    if arg:
        for key, bind in table.items():
            if key[0] == dispatcher and key[1].endswith(arg):
                return bind, key
    return None, None


def main():
    binds = load_binds()
    if not binds:
        print("No se pudieron leer los atajos (¿está Hyprland corriendo?).")
        return

    table = index(binds)
    used = set()
    rows = []  # (sección, etiqueta_tecla, descripción)

    for section, items in SECTIONS:
        for dispatcher, arg, desc in items:
            bind, key = find_bind(table, dispatcher, arg)
            if bind is None:
                continue
            used.add(key)
            rows.append((section, key_label(bind), desc))

    # Workspaces 1..9 (dos columnas de descripción)
    for dispatcher, template in WORKSPACE_ROWS:
        found = [(d, a) for (d, a) in table if d == dispatcher]
        keys = [key_label(table[k]) for k in found if k not in used]
        if not keys:
            continue
        used.update(found)
        # "Super + 1" .. "Super + 9"  ->  "Super + 1 … 9"
        first = keys[0]
        last = keys[-1]
        if " + " in first and first.split(" + ")[0] == last.split(" + ")[0]:
            prefix = first.rsplit(" + ", 1)[0]
            label = "%s + 1 … 9" % prefix
        else:
            label = first
        rows.append(("WORKSPACES", label, template.format("N")))

    # Multimedia (teclas del Mac) y resto sin clasificar
    media = []
    others = []
    for (dispatcher, arg), bind in table.items():
        if (dispatcher, arg) in used:
            continue
        # Los binds de ratón ya tienen su propia sección.
        if dispatcher == "mouse":
            continue
        raw = bind["key"] or ""
        if raw.startswith("XF86"):
            media.append((bind, arg))
        else:
            others.append((bind, arg))

    for bind, arg in media:
        short, desc = MEDIA.get(bind["key"], (bind["key"], arg or ""))
        rows.append(("TECLAS DEL MAC", short, desc))

    for bind, arg in others:
        rows.append(("OTROS", key_label(bind), arg or bind["dispatcher"]))

    # --- pintar ---------------------------------------------------------
    width = max((len(r[1]) for r in rows), default=10) + 2
    line = "  " + DIM + "─" * 58 + RESET

    print()
    print("  " + BOLD + BLUE + "ATAJOS DE HYPRLAND" + RESET + DIM + "  ·  Super + /" + RESET)
    print(line)

    current = None
    for section, label, desc in rows:
        if section != current:
            print()
            print("  " + BOLD + PURPLE + section + RESET)
            current = section
        print("    " + GREEN + label.ljust(width) + RESET + FG + desc + RESET)

    # Ratón (bindm): dispatcher "mouse", arg "movewindow" / "resizewindow".
    mouse = [b for b in binds if b["dispatcher"] == "mouse"]
    if mouse:
        print()
        print("  " + BOLD + PURPLE + "RATÓN" + RESET)
        for bind in mouse:
            text = (
                "Arrastrar la ventana"
                if bind["arg"] == "movewindow"
                else "Redimensionar la ventana"
            )
            label = key_label(bind)
            print("    " + GREEN + label.ljust(width) + RESET + FG + text + RESET)

    print()
    print("  " + DIM + "Cierra esta ventana o pulsa Enter para salir." + RESET)
    print()

    try:
        input()
    except (EOFError, KeyboardInterrupt):
        pass


if __name__ == "__main__":
    main()
