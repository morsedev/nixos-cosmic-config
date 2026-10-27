{ config, pkgs, lib, ... }:

{
  # ============ COSMIC DESKTOP ============
  # Escritorio de System76 (Rust/Wayland) con ventanas TILING integradas.
  # Pulsa Super+T para alternar tiling ↔ floating.
  services.desktopManager.cosmic = {
    enable = true;
    # XWayland para apps que aún no son Wayland nativas
    xwayland.enable = true;
  };

  # COSMIC trae su propio greeter (pantalla de login)
  services.displayManager.cosmic-greeter.enable = true;

  # ============ FONT (para terminales, editor, etc.) ============
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" ]; })
    noto-fonts
    noto-fonts-emoji
    inter
    liberation_ttf
  ];

  # ============ APPS GRÁFICAS EXTRA ============
  environment.systemPackages = with pkgs; [
    # COSMIC Files ya viene con el escritorio, pero añadimos extras
    nautilus            # navegador de archivos GNOME (elegido)
    file-roller         # compresor de archivos
    loupe               # visor de imágenes
    pavucontrol         # control de volumen
    networkmanagerapplet
  ];

  # ============ PORTALES XDG ============
  xdg.portal = {
    enable = true;
    # COSMIC usa su propio portal por defecto; dejamos el extra GTK para compat.
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  };

  # ============ GESTIÓN DE USUARIOS GRÁFICA ============
  programs.dconf.enable = true;
}
