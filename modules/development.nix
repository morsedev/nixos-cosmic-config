{ config, pkgs, lib, ... }:

{
  # ============ HERRAMIENTAS DE DESARROLLO ============
  # Herramientas que van en PATH para todos los usuarios
  environment.systemPackages = with pkgs; [

    # --- Rust ---
    rustup                 # gestor de toolchains (instala con: rustup default stable)
    rust-analyzer          # LSP para Rust (el más importante para el IDE)
    cargo
    clippy
    rustfmt

    # --- Swift ---
    swift                  # toolchain de Swift para Linux (aarch64)
    sourcekit-lsp          # LSP oficial de Swift

    # --- Flutter / Dart ---
    flutter                # SDK de Flutter (incluye Dart)
    # Nota: flutter necesita setup inicial:
    #   flutter config --enable-linux-desktop
    #   flutter doctor

    # --- Nix (editar config NixOS como IDE) ---
    nil                    # LSP de Nix (el mejor para autocompletar options de NixOS)
    nixpkgs-fmt            # formateador de Nix
    statix                 # linter de Nix

    # --- Python (común para scripting) ---
    python3
    pyright                # LSP de Python

    # --- Node / TypeScript ---
    nodejs_22
    typescript-language-server

    # --- Compiladores base ---
    gcc
    gnumake
    cmake
    pkg-config
    clang-tools            # clangd LSP (C/C++)
    lldb

    # --- Utilidades dev ---
    docker
    docker-compose
    gh                     # GitHub CLI
    lazygit                # TUI de git
    jujutsu                # git alternativo (opcional)
    direnv
    just                   # make moderno
    bat
    eza
    zoxide
    duf
    ncdu
    httpie
    yq
    sqlite
    postgresql             # cliente psql
  ];

  # ============ DOCKER ============
  virtualisation.docker.enable = true;
  # Permite usar docker sin sudo
  users.users.macnix.extraGroups = [ "docker" ];

  # ============ SERVICIOS DE DESARROLLO ============
  # PostgreSQL local (opcional — comenta si no lo necesitas)
  # services.postgresql = {
  #   enable = true;
  #   package = pkgs.postgresql_16;
  #   authentication = pkgs.lib.mkForce ''
  #     local all all trust
  #     host  all all 127.0.0.1/32 trust
  #   '';
  #   initialScript = pkgs.writeText "init" ''
  #     CREATE USER macnix WITH SUPERUSER;
  #   '';
  # };
}
