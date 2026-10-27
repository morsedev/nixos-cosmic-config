{
  description = "NixOS custom para MacBook Air M2 (Apple Silicon) — COSMIC + NixVim (módulos tipo nixarchy)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon/release-2026-07-30";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {

    # ============================================================
    # MÓDULOS (como nixarchy) — esto es lo que se importa desde
    # el flake del usuario. Basta con cambiar `nixarchy.url`.
    # ============================================================
    nixosModules = {
      default = import ./modules/nixos.nix { inherit inputs; };
      nixarchy = self.nixosModules.default;
    };

    homeModules = {
      default = import ./modules/home.nix { inherit inputs; };
      nixarchy = self.homeModules.default;
    };

    # Alias con el nombre que usa nixarchy
    homeManagerModules = {
      default = self.homeModules.default;
      nixarchy = self.homeModules.default;
    };

    # ============================================================
    # CONFIGURACIÓN COMPLETA (para CI y para usar el repo tal cual)
    # ============================================================
    nixosConfigurations.macnix = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = { inherit inputs; };

      modules = [
        ./configuration.nix
        inputs.apple-silicon.nixosModules.apple-silicon-support
        self.nixosModules.default

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.macnix.imports = [ self.homeModules.default ];
        }
      ];
    };
  };
}
