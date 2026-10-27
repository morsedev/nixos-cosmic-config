# =============================================================================
# flake.nix  —  Punto de entrada de TODA la configuración
# =============================================================================
#
# ¿Qué es un flake?
#   Es un archivo que declara:
#     1) `inputs`  → de dónde se descargan las dependencias (nixpkgs, etc.)
#     2) `outputs` → qué ofrece este repositorio (módulos, configuraciones...)
#
# La gracia: las versiones quedan FIJADAS en `flake.lock`, así que cualquiera
# que use este repo obtiene exactamente lo mismo. Reproducible.
#
# Sintaxis que verás aquí:
#   - `{ clave = valor; }`  → conjunto de atributos (cada línea acaba en `;`)
#   - `[ a b c ]`           → lista (sin comas)
#   - `"texto"`             → cadena
#   - `# ...`               → comentario
#   - `...@inputs`          → recoge TODOS los inputs en una variable `inputs`
# =============================================================================

{
  # Descripción legible del flake (no afecta al funcionamiento).
  description = "NixOS custom para MacBook Air M2 (Apple Silicon) — COSMIC + NixVim (módulos tipo nixarchy)";

  # ---------------------------------------------------------------------------
  # INPUTS: dependencias externas
  # ---------------------------------------------------------------------------
  # Cada input es un repositorio (normalmente de GitHub) con su propia versión.
  # `url`       → de dónde descargarlo.
  # `follows`   → reutiliza la versión de nixpkgs de este flake, en vez de que
  #               cada input descargue su propia copia (más rápido y coherente).
  inputs = {
    # El "sistema operativo entero": miles de paquetes y módulos de NixOS.
    # ¿Por qué NO usamos `nixos-unstable`?
    #   El soporte Apple Silicon (input `apple-silicon`) está probado contra un
    #   nixpkgs CONCRETO. Su release-2026-07-30 fija el rev `e2587ca`, que es
    #   el MISMO que trae tu ISO (`nixos-26.11.20260723.e2587ca`). Con un
    #   nixpkgs más nuevo, `linux-asahi-7.1.5` NO compila (cambian APIs internas
    #   del kernel). Por eso fijamos ese rev exacto.
    #
    # Para actualizar en el futuro: espera una release nueva de nixos-apple-silicon,
    # cambia aquí el rev y ejecuta `nix flake update`.
    nixpkgs.url = "github:nixos/nixpkgs/e2587caef70cea85dd97d7daab492899902dbf5d";

    # Home Manager: configura tu USUARIO (programas, dotfiles, shell...).
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";   # usa NUESTRO nixpkgs
    };

    # Stylix: aplica un ÚNICO tema de colores a todas las apps (Tokyo Night).
    stylix = {
      url = "github:danth/stylix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen Browser: el navegador (basado en Firefox, muy configurable).
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    # NixVim: configura Neovim de forma 100% declarativa (plugin por plugin).
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Soporte de Apple Silicon (kernel Asahi, U-Boot, GPU, firmware).
    # Se importa como módulo más abajo. Fijado a la release que probamos.
    apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon/release-2026-07-30";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # ---------------------------------------------------------------------------
  # OUTPUTS: lo que este flake ofrece
  # ---------------------------------------------------------------------------
  # `{ self, nixpkgs, home-manager, ... }@inputs:` significa:
  #   - recibe `self` (este mismo flake), `nixpkgs`, `home-manager`...
  #   - `...@inputs` guarda TODOS los inputs (incluidos stylix, nixvim...)
  #     en la variable `inputs`.
  outputs = { self, nixpkgs, home-manager, ... }@inputs: {

    # =========================================================================
    # MÓDULOS (lo que hace que se pueda usar "como nixarchy")
    # =========================================================================
    # Estos son los módulos que OTRA configuración importa. Es lo que permite
    # que en tu Mac solo cambies `nixarchy.url` y listo.
    #
    # `import ./modules/nixos.nix { inherit inputs; }`:
    #   - carga el archivo modules/nixos.nix
    #   - `{ inherit inputs; }` le pasa nuestros inputs (stylix, ...)
    #     "inherit x" es atajo de "x = x;"
    #   - el archivo devuelve un MÓDULO (una función), que es lo que se exporta
    nixosModules = {
      # Nombre estándar: nixarchy.nixosModules.default
      default = import ./modules/nixos.nix { inherit inputs; };
      # Alias: nixarchy.nixosModules.nixarchy (lo que ya usabas)
      nixarchy = self.nixosModules.default;
    };

    # Módulo de Home Manager (config del usuario: Neovim, Ghostty, Zen...).
    homeModules = {
      default = import ./modules/home.nix { inherit inputs; };
      nixarchy = self.homeModules.default;
    };

    # Alias con el nombre histórico que usaba nixarchy en Home Manager.
    homeManagerModules = {
      default = self.homeModules.default;
      nixarchy = self.homeModules.default;
    };

    # =========================================================================
    # CONFIGURACIÓN COMPLETA (para la CI y para usar el repo tal cual)
    # =========================================================================
    # `nixosConfigurations.<nombre>` = una máquina construible.
    # La CI compila esto para verificar que TODO funciona en aarch64.
    #
    # `nixpkgs.lib.nixosSystem { ... }` crea un "sistema NixOS" a partir de una
    # lista de módulos.
    nixosConfigurations.macnix = nixpkgs.lib.nixosSystem {
      # Arquitectura: los Mac M1/M2/M3 son ARM de 64 bits.
      system = "aarch64-linux";

      # Variables extra que estarán disponibles en los módulos (aquí, `inputs`).
      specialArgs = { inherit inputs; };

      # Lista de módulos que componen el sistema. Se suman todos.
      modules = [
        # 1) Cosas propias de la máquina: boot, red, usuario, Apple Silicon...
        ./configuration.nix

        # 2) Soporte Apple Silicon (kernel Asahi, U-Boot, drivers...).
        inputs.apple-silicon.nixosModules.apple-silicon-support

        # 3) NUESTRO módulo de sistema (COSMIC + dev + Stylix).
        self.nixosModules.default

        # 4) Home Manager como módulo de NixOS.
        home-manager.nixosModules.home-manager
        {
          # Home Manager reutiliza los paquetes del sistema (más eficiente).
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          # Pasa `inputs` también al lado de Home Manager.
          home-manager.extraSpecialArgs = { inherit inputs; };

          # Para el usuario `macnix`, importa NUESTRO módulo de usuario.
          home-manager.users.macnix.imports = [ self.homeModules.default ];
        }
      ];
    };
  };
}
