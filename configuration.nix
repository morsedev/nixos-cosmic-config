# =============================================================================
# configuration.nix  —  Configuración base de ESTA máquina concreta
# =============================================================================
#
# Aquí van las cosas específicas del MacBook Air M2:
#   - soporte Apple Silicon (kernel Asahi, firmware)
#   - gestor de arranque
#   - red, usuario, zona horaria
#   - ajustes de Nix y memoria
#
# El escritorio (COSMIC), las herramientas de desarrollo y el theming NO están
# aquí: viven en modules/nixos.nix (nuestro "módulo de sistema"), para poder
# reutilizarlos en otra máquina sin copiar este archivo.
# =============================================================================

# Un módulo recibe `config` (estado actual), `pkgs` (paquetes) y `lib`
# (utilidades). El `...` permite recibir más argumentos sin usarlos.
{ config, pkgs, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # IMPORTS: otros archivos/módulos que se suman a la configuración
  # ---------------------------------------------------------------------------
  # `imports` es una LISTA. Aquí:
  #   - La parte fija va entre corchetes.
  #   - `++ lib.optional condicion archivo` AÑADE hardware-configuration.nix
  #     SOLO si el archivo existe.
  #
  # ¿Por qué condicional? Porque en la CI no existe (no hay disco real) y
  # queremos que la configuración evalúe igualmente.
  #
  # `builtins.pathExists RUTA` → true/false según si la ruta existe.
  imports = [
    # (vacío aquí: los módulos propios ya se importan desde el flake)
  ] ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  # ---------------------------------------------------------------------------
  # APPLE SILICON
  # ---------------------------------------------------------------------------
  # Activa el soporte de Asahi: kernel linux-asahi, drivers de GPU, teclado,
  # trackpad, U-Boot, etc. Es LO imprescindible para que un Mac ARM arranque.
  hardware.asahi.enable = true;

  # Firmware de periféricos (WiFi, webcam, sensor de luz). El instalador de
  # Asahi lo deja en la partición EFI dentro de `vendorfw/firmware.cpio`.
  #
  # Esta expresión es un `if ... then ... else ...`:
  #   - si existe la carpeta ./vendorfw → úsala
  #   - si no (por ejemplo, en la CI)   → null (nada)
  hardware.asahi.peripheralFirmwareDirectory =
    if builtins.pathExists ./vendorfw then ./vendorfw else null;

  # Igual: solo extrae el firmware si realmente existe el archivo.
  hardware.asahi.extractPeripheralFirmware = builtins.pathExists ./vendorfw;

  # ---------------------------------------------------------------------------
  # ARRANQUE (bootloader)
  # ---------------------------------------------------------------------------
  # systemd-boot es el gestor de arranque. `canTouchEfiVariables = false`
  # porque en Apple Silicon NO se pueden modificar las variables EFI (lo
  # gestiona U-Boot/Asahi).
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # ---------------------------------------------------------------------------
  # RED
  # ---------------------------------------------------------------------------
  # Nombre de la máquina (aparece en la terminal y en la red).
  networking.hostName = "macnix";

  # NetworkManager gestiona las conexiones (WiFi, cable, VPN...).
  networking.networkmanager.enable = true;

  # En los Mac el chip WiFi es Broadcom y el backend `iwd` funciona mejor
  # (sobre todo con WPA3) que el clásico wpa_supplicant.
  networking.networkmanager.wifi.backend = "iwd";

  # ---------------------------------------------------------------------------
  # NIX (el gestor de paquetes)
  # ---------------------------------------------------------------------------
  # `nix.settings` ajusta el comportamiento de Nix.
  nix.settings = {
    # Habilita el comando `nix` moderno y los flakes.
    experimental-features = [ "nix-command" "flakes" ];

    # Compila UN paquete a la vez (evita quedarse sin RAM en un Mac de 8 GB).
    max-jobs = 1;

    # Cada compilación puede usar hasta 4 núcleos.
    cores = 4;
  };

  # Permite instalar programas con licencias "no libres" (navegadores,
  # herramientas propietarias...).
  nixpkgs.config.allowUnfree = true;

  # ---------------------------------------------------------------------------
  # MEMORIA (anti-OOM)
  # ---------------------------------------------------------------------------
  # Zram: "swap comprimido" en RAM. Da memoria extra comprimiéndola.
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;   # usa hasta el 50% de la RAM para zram

  # Swap en disco (archivo /swapfile) como respaldo adicional.
  # OJO: el archivo debe existir (ver README: se crea una vez a mano).
  swapDevices = [ { device = "/swapfile"; } ];

  # ---------------------------------------------------------------------------
  # USUARIO
  # ---------------------------------------------------------------------------
  # Define el usuario `macnix`.
  users.users.macnix = {
    isNormalUser = true;          # usuario normal (con home, login, etc.)
    description = "macnix";       # descripción (visible en el login)
    # Grupos a los que pertenece:
    #   wheel          → puede usar sudo
    #   networkmanager → puede gestionar la red
    #   video/audio/input → acceso a cámara, sonido, teclado/trackpad
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
  };

  # Permite usar sudo SIN pedir contraseña (cómodo en un equipo personal).
  # Si prefieres seguridad, ponlo en `true` o borra esta línea.
  security.sudo.wheelNeedsPassword = false;

  # ---------------------------------------------------------------------------
  # IDIOMA / ZONA HORARIA / TECLADO
  # ---------------------------------------------------------------------------
  i18n.defaultLocale = "en_US.UTF-8";  # idioma del sistema
  console.keyMap = "us";               # distribución del teclado en consola
  time.timeZone = "Europe/Madrid";     # ← cámbialo a tu zona horaria

  # ---------------------------------------------------------------------------
  # VERSIÓN DE ESTADO
  # ---------------------------------------------------------------------------
  # NO cambiar salvo reinstalación. Indica en qué versión de NixOS se creó la
  # configuración; sirve para mantener compatibilidad de rutas/servicios.
  system.stateVersion = "26.11";
}
