# =============================================================================
# modules/hyprland.nix  —  ESCRITORIO HYPRLAND (NixOS)
# =============================================================================
# Hyprland es un compositor Wayland con tiling dinámico, muy usado para ricing.
# Aquí se activa a nivel de SISTEMA: sesión Wayland, XWayland, login manager
# y los paquetes que forman el escritorio (barra, lanzador, notificaciones...).
#
# (La configuración visual/atajos de Hyprland va en modules/home/hyprland.nix)
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # HORA Y ZONA HORARIA
  # ---------------------------------------------------------------------------
  # NTP: mantiene el reloj en hora automáticamente. Sin esto, el interruptor
  # "Hora automática" de Ajustes sale bloqueado.
  services.timesyncd.enable = true;

  # ---------------------------------------------------------------------------
  # SHELL DEL SISTEMA
  # ---------------------------------------------------------------------------
  # El usuario usa zsh como shell de login (Home Manager lo configura con
  # starship, aliases, etc.). NixOS exige tener zsh habilitado en el sistema
  # para que el PATH de login sea correcto.
  programs.zsh.enable = true;

  # ---------------------------------------------------------------------------
  # HYPRLAND
  # ---------------------------------------------------------------------------
  programs.hyprland = {
    enable = true;            # activa el compositor + registra la sesión
    xwayland.enable = true;   # permite apps X11 antiguas
    withUWSM = true;          # gestor de sesión systemd (arranca targets/servicios)
  };

  # Necesario para que Hyprland y las apps usen la GPU (Mesa/Asahi).
  hardware.graphics.enable = true;

  # ---------------------------------------------------------------------------
  # LOGIN GRÁFICO (SDDM + tema Astronaut)
  # ---------------------------------------------------------------------------
  # SDDM es un gestor de sesión gráfico; con `wayland.enable` funciona en Wayland
  # y ofrece la sesión de Hyprland. El tema Astronaut es el más vistoso.
  services.displayManager.sddm = {
    enable = true;
    # Weston (greeter Wayland) debe usar la pantalla PRINCIPAL (eDP-1), no la
    # Touch Bar (DSI-1). Le pasamos un weston.ini que fuerce eDP-1.
    wayland = {
      enable = true;
      compositorCommand =
        let
          westonIni = pkgs.writeText "weston-sddm-main.ini" ''
            [libinput]
            enable-tap=true

            [keyboard]
            keymap_layout=us

            [output]
            name=eDP-1
            mode=2560x1600
          '';
        in
        "${pkgs.weston}/bin/weston --shell=kiosk -c ${westonIni}";
    };
    theme = "sddm-astronaut-theme";
    extraPackages = [ pkgs.sddm-astronaut ];
  };

  # Enlazar en el perfil del sistema las cosas que las apps buscan por ruta:
  #  - /share/sddm/themes  -> temas de SDDM (si no, no aparecen)
  #  - /share/glib-2.0/schemas -> esquemas de GNOME (modo oscuro en GTK4)
  environment.pathsToLink = [
    "/share/sddm/themes"
    # GLib busca los esquemas compilados en
    # $XDG_DATA_DIRS/gsettings-schemas/<paquete>/glib-2.0/schemas.
    # Enlazando esta carpeta, gsettings encuentra org.gnome.desktop.interface
    # y el portal puede responder "el escritorio es oscuro".
    "/share/gsettings-schemas"
  ];

  # dconf a nivel de SISTEMA (además del de Home Manager). Es lo que permite
  # que las apps GTK4 lean "prefer-dark" y se pinten en oscuro.
  programs.dconf.enable = true;
  # Sesión de Hyprland "simple" (sin UWSM). UWSM añade systemd, pero en este
  # equipo su estado se corrompe entre sesiones y a veces impide arrancar el
  # compositor ("A compositor is already active"). Los programas de la sesión
  # (barra, notificaciones, lanzador...) se lanzan con `exec-once`, así que no
  # necesitamos UWSM.
  services.displayManager.defaultSession = "hyprland";

  # ---------------------------------------------------------------------------
  # FONDOS DE PANTALLA
  # ---------------------------------------------------------------------------
  # Las imágenes viven en la carpeta `wallpapers/` del repo, ya recortadas a
  # 2560x1600 (la resolución exacta de la pantalla del Mac) y con el color
  # ajustado a Tokyo Night. Aquí solo se copian a /etc/wallpapers/.
  #
  # Se cambian con:  Super + W  (siguiente)   ·   Super + Shift + W  (menú)
  environment.etc = {
    "wallpapers/01-shinjuku.jpg".source = ../wallpapers/01-shinjuku.jpg;
    "wallpapers/02-aurora.jpg".source = ../wallpapers/02-aurora.jpg;
    "wallpapers/03-manhattan.jpg".source = ../wallpapers/03-manhattan.jpg;
    "wallpapers/04-tokyo-street.jpg".source = ../wallpapers/04-tokyo-street.jpg;
  };

  # ---------------------------------------------------------------------------
  # TOUCH BAR (tiny-dfr)
  # ---------------------------------------------------------------------------
  # En los MacBook Pro 13" M2 la Touch Bar es una pantalla DSI aparte. tiny-dfr
  # la controla (fila de teclas de función, etc.) en vez de usarse como monitor.
  hardware.apple.touchBar = {
    enable = true;

    # -------------------------------------------------------------------------
    # QUÉ SE VE EN LA TOUCH BAR
    # -------------------------------------------------------------------------
    # tiny-dfr (versión 0.3.7) permite elegir los botones, y además soporta
    # widgets EN VIVO: reloj (Time) y batería (Battery).
    #
    # El panel mide 2170x60 px: caben ~12 "huecos" de botón. `Stretch` hace que
    # un botón ocupe varios huecos.
    #
    # Aquí: brillo, volumen, play/pausa, RELOJ (2 huecos), BATERÍA (2 huecos) y
    # tres accesos directos que envían atajos a Hyprland:
    #   Term -> Super+Enter  (Ghostty)
    #   Apps -> Super+D      (Walker)
    #   Shot -> Super+S      (captura de pantalla)
    settings = {
      # Arrancar en la capa multimedia (sin tener que pulsar Fn).
      MediaLayerDefault = true;
      # Sin recuadros alrededor de cada botón: queda más limpio.
      ShowButtonOutlines = false;
      # Mueve el contenido unos píxeles cada cierto tiempo (longevidad del panel).
      EnablePixelShift = true;
      # Fuente en negrita para que se lea bien a 60 px de alto.
      FontTemplate = ":bold";
      # El brillo sigue al de la pantalla, con un máximo más alto para que se vea.
      AdaptiveBrightness = true;
      ActiveBrightness = 200;
      # 0 = desactivar el cambio de capa con doble pulsación de Fn.
      # (Con esto la capa multimedia es siempre la que se ve; antes se quedaba
      #  en la de F1–F12 tras una pulsación accidental de Fn.)
      DoublePressSwitchLayers = 0;

      # Capa multimedia = la que se ve por defecto.
      MediaLayerKeys = [
        { Icon = "brightness_low";  Action = "BrightnessDown"; }
        { Icon = "brightness_high"; Action = "BrightnessUp"; }
        { Icon = "volume_down";     Action = "VolumeDown"; }
        { Icon = "volume_up";       Action = "VolumeUp"; }
        { Icon = "play_pause";      Action = "PlayPause"; }

        # Widgets en vivo
        { Time = "%H:%M";           Action = "Time";    Stretch = 2; }
        { Battery = "both";         Action = "Battery"; Stretch = 2; }

        # Atajos de Hyprland
        { Text = "Term"; Action = [ "LeftMeta" "Return" ]; }
        { Text = "Apps"; Action = [ "LeftMeta" "D" ]; }
        { Text = "Shot"; Action = [ "LeftMeta" "S" ]; }
      ];
      # La capa de teclas F1–F12 se deja la de fábrica (se accede con Fn).
    };
  };

  # PAM para poder desbloquear con hyprlock.
  security.pam.services.hyprlock = { };

  # ---------------------------------------------------------------------------
  # PORTALES XDG (necesarios para capturas, selector de archivos, etc.)
  # ---------------------------------------------------------------------------
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];

    # -------------------------------------------------------------------------
    # IMPORTANTE: sin esto, las apps GTK4/libadwaita (Nautilus, File Roller,
    # pwvucontrol...) NO saben que el escritorio es oscuro y se quedan en
    # blanco. El motivo es que falta la interfaz org.freedesktop.portal.Settings,
    # que es la que consulta libadwaita. Aquí decimos qué backend la implementa.
    # -------------------------------------------------------------------------
    config.hyprland = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
    };
  };

  # ---------------------------------------------------------------------------
  # PAQUETES DEL ESCRITORIO
  # ---------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    # --- Componentes del ricing ---
    sddm-astronaut      # tema gráfico del login
    fastfetch           # resumen del sistema con logo (para la terminal)
    opencode            # asistente de IA en la terminal (el que usamos para configurar)
    waybar              # barra superior
    wofi                # lanzador de aplicaciones
    mako                # notificaciones
    hyprlock            # pantalla de bloqueo
    hypridle            # apagar pantalla / suspender por inactividad
    hyprpaper           # fondo de pantalla
    swaybg              # fondo alternativo (color sólido)

    # --- Utilidades Wayland ---
    grim                # capturas de pantalla
    slurp               # seleccionar región para capturas
    satty               # editor de capturas (anotar)
    wl-clipboard        # portapapeles Wayland
    cliphist            # historial del portapapeles
    brightnessctl       # brillo de pantalla
    playerctl           # control de música

    # --- Escritorio ---
    pavucontrol         # control de volumen (GTK3, clásico)
    pwvucontrol         # control de volumen moderno (GTK4/libadwaita)
    networkmanagerapplet # icono de red
    polkit_gnome        # diálogos de permisos (polkit)
    libnotify           # notificaciones (notify-send)
    nautilus            # gestor de archivos GUI
    file-roller         # comprimir/descomprimir
    loupe               # visor de imágenes

    # --- Tema / fuentes ---
    papirus-icon-theme
    bibata-cursors

    # Esquemas de GNOME. Los necesita xdg-desktop-portal-gtk para responder a
    # "¿el escritorio es oscuro?" (org.gnome.desktop.interface color-scheme).
    # SIN ESTO, las apps GTK4/libadwaita (Nautilus, File Roller, pwvucontrol)
    # se quedan en BLANCO aunque todo lo demás sea oscuro.
    gsettings-desktop-schemas
    glib
  ];

  # Polkit (diálogos de autenticación) y keyring.
  security.polkit.enable = true;

  # ---------------------------------------------------------------------------
  # PERMISOS PARA AJUSTES DEL SISTEMA
  # ---------------------------------------------------------------------------
  # Para cambiar fecha, hora y zona horaria desde "Ajustes" hace falta
  # autenticarse por polkit. En este equipo no hay agente pkexec funcionando,
  # así que gnome-control-center mostraba el aviso
  #   "Error — some settings cannot be unlocked"
  # y los interruptores salían bloqueados. Esta regla permite a los usuarios
  # del grupo "wheel" (tú) cambiar la hora sin contraseña.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel") &&
          (action.id.indexOf("org.freedesktop.timedate1.") === 0 ||
           action.id.indexOf("org.freedesktop.hostname1.") === 0)) {
        return polkit.Result.YES;
      }
    });
  '';
  services.gnome.gnome-keyring.enable = true;
}
