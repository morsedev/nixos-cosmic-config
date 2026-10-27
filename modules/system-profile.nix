# Perfil de sistema seguro para importar en una config existente.
# Usa mkDefault en todo lo que el usuario podría haber definido ya.
{ config, pkgs, lib, ... }:

{
  # --- Audio ---
  services.pipewire = {
    enable = lib.mkDefault true;
    alsa.enable = lib.mkDefault true;
    alsa.support32Bit = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
    jack.enable = lib.mkDefault true;
  };

  # --- Bluetooth (chip Broadcom de los Mac) ---
  hardware.bluetooth.enable = lib.mkDefault true;

  # --- Integración de escritorio ---
  services.dbus.enable = lib.mkDefault true;
  services.udisks2.enable = lib.mkDefault true;
  services.gvfs.enable = lib.mkDefault true;
  services.tumbler.enable = lib.mkDefault true;
  programs.dconf.enable = lib.mkDefault true;

  # --- Portales XDG ---
  xdg.portal = {
    enable = lib.mkDefault true;
    xdgOpenUsePortal = lib.mkDefault true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  };

  # --- Fuentes ---
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    noto-fonts
    noto-fonts-color-emoji
    inter
    liberation_ttf
  ];
}
