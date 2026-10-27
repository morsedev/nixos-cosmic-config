# =====================================================================
# MÓDULO NixOS (nixosModules.nixarchy) — como nixarchy
# Se importa en un flake con:
#   nixarchy.url = "github:morsedev/nixos-cosmic-config";
#   modules = [ ./configuration.nix nixarchy.nixosModules.nixarchy ... ];
# =====================================================================
{ inputs }:
{ config, lib, pkgs, ... }:

{
  imports = [
    # Theming (Stylix) — se integra con Home Manager automáticamente
    inputs.stylix.nixosModules.stylix

    ./system-profile.nix
    ./cosmic.nix
    ./development.nix
    ./stylix.nix
  ];

  # Opciones compatibles con la forma en que nixarchy se configura.
  options.programs.nixarchy = {
    enable = lib.mkEnableOption "COSMIC + entorno de desarrollo (perfil Apple Silicon)";
    flake = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos";
      description = "Ruta del flake del usuario (p. ej. para nixd).";
    };
  };
}
