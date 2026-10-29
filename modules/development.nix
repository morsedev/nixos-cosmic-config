# =============================================================================
# modules/development.nix  —  HERRAMIENTAS DE DESARROLLO
# =============================================================================
#
# Instala los lenguajes y utilidades que necesitas para programar.
# Todos los paquetes de `environment.systemPackages` quedan en el PATH
# (disponibles desde la terminal) para todos los usuarios.
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # PAQUETES
  # ---------------------------------------------------------------------------
  # `with pkgs; [ ... ]` = "los nombres de dentro están en pkgs".
  environment.systemPackages = with pkgs; [

    # --- Rust ---
    rustup              # gestor de versiones de Rust (luego: rustup default stable)
    rust-analyzer       # servidor de lenguaje (LSP) de Rust → autocompletado
    cargo               # gestor de proyectos/dependencias de Rust
    clippy              # linter de Rust
    rustfmt             # formateador de Rust

    # --- Swift ---
    # IMPORTANTE: `swift` está marcado como "broken" en aarch64-linux dentro de
    # nixpkgs, así que NO se puede instalar aquí. Ver README > Swift para
    # instalar el toolchain oficial de swift.org.

    # --- Flutter / Dart ---
    flutter             # SDK de Flutter (incluye Dart). Requiere setup inicial:
                        #   flutter config --enable-linux-desktop
                        #   flutter doctor

    # --- Nix (para editar ESTA configuración) ---
    nil                 # LSP de Nix: autocompletado de opciones de NixOS
    nixpkgs-fmt         # formateador de archivos .nix
    statix              # linter de Nix

    # --- Python ---
    python3             # intérprete de Python
    pyright             # LSP de Python

    # --- Node.js / TypeScript ---
    nodejs_22                        # Node.js (versión 22)
    typescript-language-server       # LSP de TypeScript/JavaScript

    # --- Compiladores base ---
    gcc                 # compilador C
    gnumake             # `make`
    cmake               # sistema de build C/C++
    pkg-config          # ayuda a encontrar librerías al compilar
    clang-tools         # incluye clangd (LSP de C/C++)
    lldb                # depurador (también provee lldb-dap para Neovim)

    # --- Utilidades de desarrollo ---
    opencode            # asistente de IA en la terminal (el que usamos para configurar)
    docker              # contenedores
    docker-compose      # orquestación de contenedores
    gh                  # GitHub CLI (gh pr, gh repo...)
    cachix              # subir/descargar de una caché binaria (Cachix)
    lazygit             # interfaz TUI para git
    jujutsu             # sistema de control de versiones alternativo a git
    direnv              # carga variables/entornos por carpeta (.envrc)
    just                # "make" moderno (recetas en un justfile)
    bat                 # `cat` con colores
    eza                 # `ls` moderno con iconos
    zoxide              # `cd` inteligente (recuerda carpetas)
    duf                 # `df` bonito (uso de disco)
    ncdu                # análisis de uso de disco interactivo
    httpie              # cliente HTTP para probar APIs
    yq                  # procesa YAML (como jq pero para YAML)
    sqlite              # base de datos SQLite
    postgresql          # incluye el cliente `psql`
  ];

  # ---------------------------------------------------------------------------
  # DOCKER
  # ---------------------------------------------------------------------------
  # Activa el servicio de Docker (el "motor").
  virtualisation.docker.enable = true;

  # Añade el usuario `macnix` al grupo `docker` para poder usar docker sin sudo.
  # `extraGroups` es una LISTA y se SUMA a la que ya tenga el usuario.
  users.users.macnix.extraGroups = [ "docker" ];

  # ---------------------------------------------------------------------------
  # BASE DE DATOS LOCAL (opcional)
  # ---------------------------------------------------------------------------
  # Descomenta si quieres un PostgreSQL local. Está preparado para confiar en
  # conexiones locales (sin contraseña, para desarrollo).
  #
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
