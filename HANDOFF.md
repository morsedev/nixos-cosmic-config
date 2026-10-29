# HANDOFF — Contexto de la configuración (NixOS + Hyprland + Touch Bar)

> Este archivo es la **fuente de verdad** para continuar el trabajo con OpenCode
> desde esta máquina. Si abres una sesión nueva de OpenCode, dile que lea este
> archivo (`HANDOFF.md`) y que siga a partir de aquí.

## Qué es esto

Repositorio consumido como **módulo** estilo nixarchy por la configuración del
Mac (MacBook Pro 13" M2, Apple Silicon / Asahi).

- En el Mac: `/etc/nixos/flake.nix` → `nixarchy.url = github:morsedev/nixos-cosmic-config`
  + `nixosModules.nixarchy` + `homeManagerModules.nixarchy`.
- Clon de trabajo en el Mac: `~/nixos-cosmic-config`.
- Flujo: editar repo → `git push` → en el Mac:
  `cd /etc/nixos && sudo nix flake update nixarchy && sudo nixos-rebuild switch --flake /etc/nixos#macnix`.

**IMPORTANTE — pin de nixpkgs:** `flake.nix` fija `nixpkgs` al rev
`e2587ca…` (26.11.20260723, el mismo que la release de Asahi). NO subas nixpkgs
ni los otros inputs a ramas "master"/"main" sin mover todos a la vez: el kernel
Asahi y `uboot-asahi` dejan de compilar (dtc 1.8.1 rompe con
`unrecognized check name node_name_not_empty`).

## Estado actual de la máquina

- **Hyprland 0.56** (config `hyprlang`, sin UWSM), `hyprctl configerrors` vacío.
- **SDDM** con tema `sddm-astronaut`, **autologin** como `macnix` activado.
- **Shell de login = zsh** (Starship Tokyo Night + aliases), bash de respaldo.
- **Tokyo Night** en todo: Stylix (autoEnable=false, solo GTK/Qt), GTK con
  `adw-gtk3-dark` + Papirus-Dark + dconf `prefer-dark` + `ADW_DISABLE_PORTAL=1`
  (sin esto las apps GTK4/libadwaita se ven en BLANCO), Qt sigue GTK.
- **Wallpapers**: 4 fondos en `wallpapers/` (2560x1600, grade Tokyo Night).
  Cambio con `Super+W` (siguiente) / `Super+Shift+W` (menú) o `wallpaper next`.
- **Navegador**: Firefox (Zen no renderiza en Asahi → páginas en blanco).
  Barra minimalista (sin pestañas, solo dirección + atrás/adelante) con
  `userChrome.css`, y página de nueva pestaña Tokyo Night con marca de agua
  `東京` (`userContent.css`).
- **Neovim** (NixVim), **Ghostty** (paleta Tokyo Night), **Yazi**, **eza/bat/fd/rg**.
- **Ajustes del sistema**: menú wofi `Super+I` o engranaje de la barra →
  `gnome-control-center` con `XDG_CURRENT_DESKTOP=GNOME ADW_DISABLE_PORTAL=1`.
- **polkit**: regla para que `wheel` cambie fecha/hora/zona sin contraseña.
  Zona horaria: `Europe/Madrid`, NTP activo (`timesyncd`).

## Touch Bar (daemon propio `touchbar-pet`)

`touchbar-pet` es un daemon en C (`touchbar-pet/pet.c`) que toma el panel por
DRM (dumb buffer + **atomic commit**, único que acepta `appletbdrm`) y:
- enciende el backlight del panel al arrancar,
- dibuja modos: **CAT** (gato animado del GIF del usuario + reloj 7-seg +
  copo de nieve + batería + botones ▶ y FN), **MEDIA** (brillo/volumen/
  play/prev/next vía `brightnessctl`/`wpctl`/`playerctl`), **FKEYS** (F1–F12
  por uinput),
- lee el **táctil** del panel por evdev (`ABS_MT_POSITION_X`, rango 0..23044),
- anima el gato por tiempo (fotogramas en `/etc/touchbar-pet/frames/*.ppm`),
- tormenta al teclear (rayos finos morados con fade, cerca del gato; rediseñada
  para ser sutil en vez de los antiguos rayos naranjas gruesos).
- los comandos media se lanzan con `XDG_RUNTIME_DIR` + `DBUS_SESSION_BUS_ADDRESS`
  del usuario (`run_user_cmd`), porque el daemon corre como root y sin eso
  `wpctl`/`playerctl` no encuentran la sesión.

Comandos (en `/run/current-system/sw/bin`):
- `touchbar-pet on|off|status` — alterna entre el gato y tiny-dfr (botones Fn).
- `touchbar` — cambia layouts de tiny-dfr (media/minimal/dev/fkeys). `Super+Shift+T`.
- `touchbar-sprite <imagen>` — convierte una imagen/GIF en fotogramas del gato.
- `touchbar-shot [--storm]` — guarda una captura del framebuffer en
  `/tmp/touchbar-shot-local.ppm` (se revisa con el modelo de visión).

Notas: `appletbdrm` es **solo atómico** (el legacy SetCrtc no pinta); sin
`drmModeDirtyFB` no se ve nada; sin backlight (0/255) el panel queda negro.
El gato real es de un GIF de gifdb.com (uso personal, marca de agua recortada).

## Atajos (también en la chuleta con `Super+/`)

```
Super+Enter terminal · Super+D walker · Super+E nautilus · Super+Q cerrar
Super+F fullscreen (respeta barra) · Super+Shift+F fullscreen real · Super+V flotar
(con Super+F activo, cambiar de ventana con Super+arrows hace que el maximizado
"siga" al foco: necesita `misc:on_focus_under_fullscreen = 1` Y
`binds:movefocus_cycles_fullscreen = true` en modules/home/hyprland.nix) · Super+M salir · Super+L bloquear
Super+S / Shift+S captura · Super+C portapapeles · Super+/ chuleta
Super+W / Shift+W wallpaper · Super+N wifi · Super+B bluetooth · Super+A audio
Super+I ajustes · Super+Shift+T touchbar · Super+1..9 workspaces
```

## Problemas conocidos / pendientes

1. **hyprlock crashea** en este equipo (mostró "lockscreen died" varias veces).
   Por eso el **auto-lock está desactivado** (hypridle solo apaga el panel) y el
   fondo de hyprlock es un color sólido. Arreglar hyprlock si se retoma.
2. **gnome-control-center** muestra el banner "Error — some settings cannot be
   unlocked" y deshabilita "Automatic Date & Time" fuera de GNOME. La hora/zona
   ya están bien vía config.
3. **Touch Bar**: gato pegado a la izquierda, botones MEDIA/FKEYS rediseñados
   (más grandes, sin solapes, centinela del array arreglado), comandos media con
   entorno del usuario y tormenta sutil con fade. Revisar con `touchbar-shot`
   tras el siguiente `nixos-rebuild` en el Mac.
4. **Módulo "0" en la barra** (entre wifi y batería): DIAGNOSTICADO — es el
   icono de Bluetooth de waybar (glifo FA5 `U+F293`, un rombo que a 13px parece
   un "0"). La config cubre todos los estados (no hay bug). Si molesta, quitar
   el módulo `bluetooth` de `modules/home/bar.nix`.
5. **Zen Browser** no renderiza en Asahi (páginas en blanco); se usa Firefox.
6. **Icono verde de File Roller** y pestañas de pwvucontrol: cosmética, sin arreglo simple.
7. ~~opencode en hyprland.nix~~ → movido a `modules/development.nix`. Las
   herramientas de desarrollo nuevas van ahí.

## Mantenimiento (ya configurado en `modules/maintenance.nix`)

- Generación actual = **punto base** (GC root `/nix/var/nix/gcroots/system-base`).
- **Máx. 7 generaciones** (servicio `nix-generation-clean`, diario).
- **GC del store** automático diario (`--delete-older-than 30d`).

## Cómo seguir aquí con OpenCode

```bash
cd ~/nixos-cosmic-config
opencode        # y di: "lee HANDOFF.md y sigue"
```

Cualquier cambio que hagas desde aquí, recuerda que el Mac aplica el estado
real: `sudo nix flake update nixarchy && sudo nixos-rebuild switch --flake /etc/nixos#macnix`.
