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
  environment.systemPackages = [ pkgs.sddm-astronaut ];
  environment.pathsToLink = [ "/share/sddm/themes" ];
  services.displayManager.defaultSession = "hyprland";

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
