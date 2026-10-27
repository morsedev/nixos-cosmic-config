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
  # LOGIN MANAGER (greetd + tuigreet)
  # ---------------------------------------------------------------------------
  # greetd es el gestor de sesión; tuigreet es un login sencillo en texto.
  services.greetd = {
    enable = true;
    settings.default_session = {
      # `tuigreet` pide usuario/contraseña y lanza Hyprland al entrar.
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd start-hyprland";
      user = "greeter";
    };
  };

  # Usuario/grupo que ejecuta el greeter (requerido por greetd).
  users.groups.greeter = { };
  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
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
