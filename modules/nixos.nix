# =============================================================================
# modules/nixos.nix  —  MÓDULO DE SISTEMA (nixosModules.nixarchy)
# =============================================================================
#
# Esto es lo que se importa desde el flake del usuario igual que nixarchy:
#
#   nixarchy.url = "github:morsedev/nixos-cosmic-config";
#   modules = [
#     ./configuration.nix
#     nixarchy.nixosModules.nixarchy
#     ...
#   ];
#
# -----------------------------------------------------------------------------
# ¿Qué significa `{ inputs }:` seguido de `{ config, lib, pkgs, ... }:`?
# -----------------------------------------------------------------------------
# Es una función que se llama en DOS pasos ("currying"):
#
#   Paso 1: `import ./modules/nixos.nix { inherit inputs; }`
#           → le pasamos un CONJUNTO `{ inputs = ...; }` para que el módulo
#             conozca los inputs del flake (stylix, etc.).
#
#   Paso 2: el resultado es otra función `{ config, lib, pkgs, ... }: ...`
#           que es el MÓDULO de verdad, y que NixOS ejecutará.
#
# ¿Por qué hacerlo así? Porque un módulo normal no tiene acceso a los `inputs`
# del flake. Pasándolos en el paso 1, el módulo puede usar `inputs.stylix`.
# =============================================================================

{ inputs }:
{ config, lib, pkgs, ... }:

{
  # ---------------------------------------------------------------------------
  # IMPORTS: piezas que componen este módulo
  # ---------------------------------------------------------------------------
  # Se suman todas. Las de `./` son archivos de este mismo repo.
  imports = [
    # Módulo oficial de Stylix (theming). Se integra solo con Home Manager.
    inputs.stylix.nixosModules.stylix

    # Perfil "seguro" del sistema: audio, bluetooth, fuentes, portales.
    ./system-profile.nix

    # Escritorio Hyprland (tiling) + login + paquetes del ricing.
    ./hyprland.nix

    # Layouts de la Touch Bar + comando `touchbar`.
    ./touchbar.nix

    # Mantenimiento: punto base + máximo 7 generaciones + limpieza del store.
    ./maintenance.nix

    # Herramientas de desarrollo (Rust, Flutter/Dart, Python, Docker...).
    ./development.nix

    # Swift (toolchain oficial de swift.org para aarch64-linux).
    ./swift.nix

    # Configuración del tema Tokyo Night.
    ./stylix.nix
  ];

  # ---------------------------------------------------------------------------
  # OPCIONES PROPIAS (para que el flake del usuario las pueda ajustar)
  # ---------------------------------------------------------------------------
  # `options.programs.nixarchy` crea un "namespace" de opciones.
  # Son de COMPATIBILIDAD con nixarchy: tu flake puede seguir escribiendo
  #   programs.nixarchy.enable = true;
  #   programs.nixarchy.flake  = "/etc/nixos";
  # El módulo se aplica al importarse; `enable` existe para no romper flakes
  # que ya lo definían.
  options.programs.nixarchy = {
    # Opción booleana (true/false). La crea `mkEnableOption`.
    enable = lib.mkEnableOption "COSMIC + entorno de desarrollo (perfil Apple Silicon)";

    # Opción de tipo texto: ruta del flake del usuario.
    # `lib.mkOption` define una opción nueva; `type` es obligatorio.
    flake = lib.mkOption {
      type = lib.types.str;        # es un texto
      default = "/etc/nixos";      # valor si nadie lo cambia
      description = "Ruta del flake del usuario (p. ej. para nixd).";
    };
  };
}
