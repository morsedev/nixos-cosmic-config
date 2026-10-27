{ config, pkgs, lib, ... }:

{
  # ============ COSMIC DESKTOP ============
  # Escritorio de System76 (Rust/Wayland) con ventanas TILING integradas.
  # Pulsa Super+T para alternar tiling ↔ floating.
  services.desktopManager.cosmic = {
    enable = true;
    xwayland.enable = true;
  };

  # Greeter propio de COSMIC
  services.displayManager.cosmic-greeter.enable = true;

  # ============ APPS GRÁFICAS EXTRA ============
  environment.systemPackages = with pkgs; [
    nautilus            # navegador de archivos GNOME
    file-roller         # compresor de archivos
    loupe               # visor de imágenes
    pavucontrol         # control de volumen
    networkmanagerapplet
  ];
}
