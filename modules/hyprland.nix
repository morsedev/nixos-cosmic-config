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

  # Enlazar los temas de SDDM en el perfil del sistema (si no, no aparecen).
  environment.pathsToLink = [ "/share/sddm/themes" ];
  services.displayManager.defaultSession = "hyprland-uwsm";

  # ---------------------------------------------------------------------------
  # FONDO DE PANTALLA (generado, no descargado)
  # ---------------------------------------------------------------------------
  # Lo creamos con ImageMagick en vez de bajar una foto: no hay que versionar un
  # binario en el repo y siempre encaja con la paleta Tokyo Night.
  #
  # Cómo funciona el comando:
  #   - `gradient:`   degradado vertical (azul noche -> casi negro).
  #   - `-draw ellipse` tres manchas de luz azul, morada y turquesa.
  #   - `-blur 0x70`  las difumina (efecto "aurora").
  #   - `-resize`     lo escala al tamaño exacto del panel (2560x1600).
  #   - `+noise`      grano sutil, evita el aspecto de plástico.
  #
  # `runCommand` es una "receta" de Nix: al construirla produce un PNG en /nix/store.
  # El resultado se expone como /etc/tokyo-night-wallpaper.png.
  environment.etc."tokyo-night-wallpaper.png".source =
    pkgs.runCommand "tokyo-night-wallpaper.png" {
      nativeBuildInputs = [ pkgs.imagemagick ];
    } ''
      # 1) Base: degradado vertical oscuro (arriba MÁS oscuro, para que la
      #    barra siempre tenga contraste; abajo se aclara un poco).
      # 2) Tres manchas de luz (azul, morado, turquesa), difuminadas.
      # 3) Rejilla fina de 64px (estructura, estilo "técnico").
      # 4) Grano sutil para que no se vea como un degradado de plástico.
      magick -size 1280x800 gradient:'#131722'-'#1b1c2a' \
        -fill 'rgba(122,162,247,0.34)' -draw 'ellipse 250,700 640,540 0,360' \
        -fill 'rgba(187,154,247,0.30)' -draw 'ellipse 1060,760 660,540 0,360' \
        -fill 'rgba(115,218,202,0.12)' -draw 'ellipse 900,120 380,300 0,360' \
        -blur 0x80 \
        -resize 2560x1600! \
        "$TMPDIR/base.png"

      grid=""
      for x in $(seq 0 64 2560); do grid="$grid line $x,0 $x,1600"; done
      for y in $(seq 0 64 1600); do grid="$grid line 0,$y 2560,$y"; done

      magick "$TMPDIR/base.png" \
        -stroke 'rgba(122,162,247,0.07)' -strokewidth 1 -draw "$grid" \
        -attenuate 0.02 +noise Gaussian \
        "$out"
    '';

  # ---------------------------------------------------------------------------
  # TOUCH BAR (tiny-dfr)
  # ---------------------------------------------------------------------------
  # En los MacBook Pro 13" M2 la Touch Bar es una pantalla DSI aparte. tiny-dfr
  # la controla (fila de teclas de función, etc.) en vez de usarse como monitor.
  hardware.apple.touchBar = {
    enable = true;
    settings = {
      MediaLayerDefault = true;
      ShowButtonOutlines = false;
      EnablePixelShift = true;
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
    ];
  };

  # ---------------------------------------------------------------------------
  # PAQUETES DEL ESCRITORIO
  # ---------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    # --- Componentes del ricing ---
    sddm-astronaut      # tema gráfico del login
    fastfetch           # resumen del sistema con logo (para la terminal)
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
    pavucontrol         # control de volumen
    networkmanagerapplet # icono de red
    polkit_gnome        # diálogos de permisos (polkit)
    libnotify           # notificaciones (notify-send)
    nautilus            # gestor de archivos GUI
    file-roller         # comprimir/descomprimir
    loupe               # visor de imágenes

    # --- Tema / fuentes ---
    papirus-icon-theme
    bibata-cursors
  ];

  # Polkit (diálogos de autenticación) y keyring.
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
}
