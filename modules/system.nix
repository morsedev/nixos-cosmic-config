{ config, pkgs, lib, ... }:

{
  # ============ RED WIFI (declarativa) ============
  # Configura aquí tus redes WiFi (la de casa con @, etc.)
  networking.networkmanager.ensureProfiles.profiles = {
    # wifi-casa = {
    #   connection = { id = "wifi-casa"; type = "wifi"; };
    #   wifi = { ssid = "TU_SSID"; };
    #   wifi-security = { key-mgmt = "wpa-psk"; psk = "TU_CONTRASEÑA"; };
    #   ipv4 = { method = "auto"; };
    #   ipv6 = { addr-gen-mode = "stable-privacy"; method = "auto"; };
    # };
  };

  # ============ AUDIO (PipeWire) ============
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # ============ IMPRESIÓN / ESCÁNER (opcional) ============
  # services.printing.enable = true;

  # ============ SERVICIOS ÚTILES ============
  services.dbus.enable = true;
  services.udisks2.enable = true;   # montaje automático de USBs/dispositivos
  services.gvfs.enable = true;      # integración GNOME Files (Nautilus)
  services.tumbler.enable = true;   # miniaturas de archivos (Nautilus)

  # Bluetooth (chip Broadcom del Mac)
  hardware.bluetooth.enable = true;

  # ============ FIRMWARE / HARDWARE EXTRA ============
  hardware.enableAllFirmware = true;

  # ============ LOCALE ============
  # Cambia el idioma si lo prefieres en español
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  time.timeZone = "Europe/Madrid"; # ← cámbialo a tu zona

  # ============ USUARIOS DEL SISTEMA ============
  users.users.macnix = {
    isNormalUser = true;
    description = "macnix";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
  };

  # sudo para el grupo wheel
  security.sudo.wheelNeedsPassword = false;
}
