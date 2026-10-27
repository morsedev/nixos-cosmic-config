{
  description = "NixOS custom config para MacBook Air M2 (Apple Silicon) — COSMIC + Neovim IDE";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Theming homogéneo (Tokyo Night en todas las apps)
    stylix = {
      url = "github:danth/stylix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Navegador Zen Browser (configurable al máximo, temas integrados)
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    # ============ APPLE SILICON ============
    # Soporte Asahi (kernel, U-Boot, GPU, firmware) importado como input,
    # en vez del directorio local ./apple-silicon-support.
    apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon/release-2026-07-30";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, stylix, zen-browser, apple-silicon, ... }@inputs: {
    nixosConfigurations.macnix = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = { inherit inputs zen-browser apple-silicon; };

      modules = [
        # ============ APPLE SILICON ============
        # Importa el módulo de soporte Apple Silicon desde el input
        apple-silicon.nixosModules.apple-silicon-support

        # ============ CONFIG PRINCIPAL ============
        ./configuration.nix

        # ============ THEMING ============
        stylix.nixosModules.stylix

        # ============ HOME MANAGER ============
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # Pasar los inputs a los módulos de usuario (para Stylix HM, Zen, etc.)
          home-manager.extraSpecialArgs = { inherit inputs; };
        }
      ];
    };
  };
}
