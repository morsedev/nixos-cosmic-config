# =============================================================================
# modules/system-profile.nix  —  Ajustes "seguros" del sistema
# =============================================================================
#
# Este módulo se importa DENTRO de la configuración del usuario (a través de
# modules/nixos.nix). Por eso usa `lib.mkDefault` en casi todo: así, si tu
# configuration.nix ya define lo mismo, gana TU definición y no hay conflicto.
#
# Regla mental:
#   `= true;`              → "esto TIENE que ser true" (puede chocar)
#   `= lib.mkDefault true;`→ "ponlo a true SALVO que otro diga otra cosa"
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # SONIDO (PipeWire)
  # ---------------------------------------------------------------------------
  # PipeWire es el servidor de audio moderno (sustituye a PulseAudio y JACK).
  services.pipewire = {
    enable = lib.mkDefault true;          # enciende PipeWire
    alsa.enable = lib.mkDefault true;     # soporte para apps que usan ALSA
    alsa.support32Bit = lib.mkDefault true; # audio de apps de 32 bits
    pulse.enable = lib.mkDefault true;    # compatibilidad con PulseAudio
    jack.enable = lib.mkDefault true;     # compatibilidad con JACK (audio pro)
  };

  # ---------------------------------------------------------------------------
  # BLUETOOTH
  # ---------------------------------------------------------------------------
  # En los Mac el chip Bluetooth es Broadcom; el soporte viene por Asahi.
  hardware.bluetooth.enable = lib.mkDefault true;

  # ---------------------------------------------------------------------------
  # INTEGRACIÓN CON EL ESCRITORIO
  # ---------------------------------------------------------------------------
  # D-Bus: "autobús" de comunicación entre programas del sistema.
  services.dbus.enable = lib.mkDefault true;

  # udisks2: monta automáticamente USBs y discos externos.
  services.udisks2.enable = lib.mkDefault true;

  # gvfs: permite a Nautilus ver la papelera, redes, MTP (móviles), etc.
  services.gvfs.enable = lib.mkDefault true;

  # tumbler: genera miniaturas de imágenes/PDF en Nautilus.
  services.tumbler.enable = lib.mkDefault true;

  # dconf: base de datos de ajustes de apps GTK/GNOME.
  programs.dconf.enable = lib.mkDefault true;

  # ---------------------------------------------------------------------------
  # PORTALES XDG
  # ---------------------------------------------------------------------------
  # Los "portales" son la forma estándar (Wayland) en que las apps piden cosas
  # al escritorio: abrir archivos, capturas de pantalla, etc.
  xdg.portal = {
    enable = lib.mkDefault true;
    xdgOpenUsePortal = lib.mkDefault true;
    # Lista de portales extra (se SUMAN a los que ya haya).
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  };

  # ---------------------------------------------------------------------------
  # FUENTES
  # ---------------------------------------------------------------------------
  # `fonts.packages` es una LISTA: se suman todas las fuentes que declares en
  # cualquier módulo (no se sobrescriben).
  #
  # `with pkgs; [ ... ]` = "busca estos nombres dentro de pkgs".
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono     # fuente de código con iconos (Nerd Font)
    nerd-fonts.fira-code         # otra fuente de código
    noto-fonts                   # fuentes generales
    noto-fonts-color-emoji       # emojis a color
    inter                        # fuente de interfaz
    liberation_ttf               # equivalentes a Arial/Times
  ];
}
