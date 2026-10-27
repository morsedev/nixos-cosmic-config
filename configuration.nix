{ config, pkgs, lib, ... }:

{
  imports = [
    # Apple Silicon ya lo importa el flake (o tu config) — no se toca aquí.
    # hardware-configuration.nix lo genera el instalador en el Mac.
  ] ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  # ============ APPLE SILICON ============
  hardware.asahi.enable = true;
  hardware.asahi.peripheralFirmwareDirectory =
    if builtins.pathExists ./vendorfw then ./vendorfw else null;
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
    max-jobs = 1;
    cores = 4;
  };
  nixpkgs.config.allowUnfree = true;

  # ============ MEMORIA (anti-OOM) ============
  swapDevices = [ { device = "/swapfile"; } ];
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;

  # ============ USUARIO ============
  users.users.macnix = {
    isNormalUser = true;
    description = "macnix";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
  };
  security.sudo.wheelNeedsPassword = false;

  # ============ LOCALE ============
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  time.timeZone = "Europe/Madrid";

  system.stateVersion = "26.11";
}
