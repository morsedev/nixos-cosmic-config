# =============================================================================
# modules/cosmic.nix  —  ESCRITORIO COSMIC (con tiling)
# =============================================================================
#
# COSMIC es el escritorio de System76, escrito en Rust y para Wayland.
# Trae "tiling" integrado: las ventanas se colocan solas en mosaico, como
# Hyprland, pero desde el propio escritorio.
#
#   Super+T  → alternar tiling ↔ ventanas flotantes
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # ACTIVAR EL ESCRITORIO
  # ---------------------------------------------------------------------------
  # Esta opción es la que instala y configura COSMIC. Al activarla, NixOS
  # trae todos sus componentes (panel, ajustes, sesión, etc.).
  services.desktopManager.cosmic = {
    enable = true;

    # XWayland permite ejecutar apps antiguas que aún no son Wayland nativas.
    xwayland.enable = true;
  };

  # Pantalla de login propia de COSMIC.
  services.displayManager.cosmic-greeter.enable = true;

  # ---------------------------------------------------------------------------
  # APPS GRÁFICAS EXTRA
  # ---------------------------------------------------------------------------
  # `environment.systemPackages` es una LISTA de paquetes disponibles para
  # todos los usuarios. Se suman los que pongas en cualquier módulo.
  environment.systemPackages = with pkgs; [
    nautilus                 # navegador de archivos GNOME (GUI)
    file-roller              # comprimir/descomprimir (zip, tar...)
    loupe                    # visor de imágenes
    pavucontrol              # control de volumen avanzado
    networkmanagerapplet     # icono/gestor de red en la bandeja
  ];
}
