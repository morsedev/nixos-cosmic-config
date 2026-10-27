{ config, pkgs, lib, inputs, apple-silicon, ... }:

{
  imports = [
    # NOTA: el módulo de Apple Silicon ya se importa desde el flake (flake.nix),
    # NO hace falta ./apple-silicon-support aquí.

    # hardware-configuration.nix lo genera el instalador en el Mac
    # (sistema de archivos, particiones). Condicional para que la CI funcione.
  ] ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix
  ++ [
    # Módulos de esta config
    ./modules/system.nix
    ./modules/cosmic.nix
    ./modules/development.nix
    ./modules/users.nix
    ./modules/stylix.nix
  ];

  # ============ APPLE SILICON ============
  hardware.asahi.enable = true;

  # Firmware periférico (WiFi, webcam, sensor de luz).
  # En CI no existe; en el Mac apunta a la carpeta vendorfw copiada del ESP.
  # Si no encuentras el archivo, regenera el paquete con el instalador de Asahi.
  hardware.asahi.peripheralFirmwareDirectory =
    if builtins.pathExists ./vendorfw
    then ./vendorfw
    else null;
  # Si no hay firmware (CI), desactivar la extracción para que no falle la aserción
  hardware.asahi.extractPeripheralFirmware = builtins.pathExists ./vendorfw;

  # ============ BOOTLOADER ============
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # ============ RED ============
  networking.hostName = "macnix";
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  # ============ NIX ============
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Evita OOM en compilaciones pesadas (Mac M2 de 8 GB)
    max-jobs = 1;
    cores = 4;
    # Cachés útiles
    substituters = [
      "https://cache.nixos.org"
      "https://cosmic.cachix.org"
    ];
    trusted-public-keys = [
      "cosmic.cachix.org-1:Dya9IyXD4xd0hV8x1JsDd3CgE6GP5gDdhI5rAeBMKfs="
    ];
  };

  # ============ MEMORIA (anti-OOM) ============
  swapDevices = [ { device = "/swapfile"; } ];
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;

  # ============ SYSTEM PACKAGES BÁSICOS ============
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    htop
    btop
    ripgrep
    fd
    fzf
    jq
    unzip
    zip
    tree
    file
    pciutils
    usbutils
  ];

  # Permitir paquetes no libres (Zen Browser, herramientas de Swift, etc.)
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.11";
}
