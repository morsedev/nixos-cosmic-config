# =============================================================================
# modules/development.nix  —  HERRAMIENTAS DE DESARROLLO
# =============================================================================
#
# Instala los lenguajes y utilidades que necesitas para programar.
# Todos los paquetes de `environment.systemPackages` quedan en el PATH
# (disponibles desde la terminal) para todos los usuarios.
#
# Incluye toolchains para:
#   - Rust, Nix, Python, Node/TS, C/C++
#   - Swift (toolchain oficial de swift.org, ver README; aquí solo la base)
#   - Flutter/Dart
#   - EMBEDDED: ARM Cortex-M (nRF52, STM32) — compilador cruzado, OpenOCD,
#     ST-Link, flash, serial, PlatformIO, nRF tools, Arduino CLI
#   - PCB: KiCad (esquemáticos + layout + 3D + kicad-cli), LibrePCB, gerbv
#   - IA agentica en CLI (opencode, aichat, codex, goose, gemini)
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
    cargo-nextest       # correr tests de Rust en paralelo (más rápido)

    # --- Swift ---
    # IMPORTANTE: `swift` está marcado como "broken" en aarch64-linux dentro de
    # nixpkgs, así que NO se puede instalar aquí. Ver README > Swift para
    # instalar el toolchain oficial de swift.org.
    # (El LSP de nvim y swift-format ya están preparados para ese toolchain.)

    # --- Flutter / Dart ---
    flutter             # SDK de Flutter (incluye Dart). Requiere setup inicial:
                        #   flutter config --enable-linux-desktop
                        #   flutter doctor

    # --- Nix (para editar ESTA configuración) ---
    nil                 # LSP de Nix: autocompletado de opciones de NixOS
    nixd                # LSP de Nix alternativo (más completo con flakes)
    nixpkgs-fmt         # formateador de archivos .nix
    alejandra           # formateador de Nix (estilo)
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

    # ---------------------------------------------------------------------------
    # EMBEDDED (ARM Cortex-M: nRF52, STM32 y similares)
    # ---------------------------------------------------------------------------
    # Cadena de herramientas cruzada ARM + programación + depuración + serie.
    gcc-arm-embedded     # compilador cruzado ARM (arm-none-eabi-gcc/gdb)
    openocd              # debug/programador por JTAG/SWD (ST-Link, J-Link...)
    stlink               # herramientas de ST-Link (STM32: flash, conecta)
    dfu-util             # flashear por USB DFU (nRF52 bootloader, etc.)
    picocom              # terminal serie para consolas UART (minicom también vale)
    platformio           # ecosistema embedded (Board Manager, frameworks, agentic)
    nrf-command-line-tools # herramientas oficiales de Nordic (nrfjprog, mergehex...)
    arduino-cli          # arduino desde CLI (agentico, sin IDE)

    # ---------------------------------------------------------------------------
    # PCB / ELECTRÓNICA (diseño de placas)
    # ---------------------------------------------------------------------------
    kicad                # EDA completo: esquemático + PCB + 3D + kicad-cli
    librepcb             # EDA open source (alternativa moderna a EAGLE)
    gerbv                # visor de archivos Gerber (para ver el resultado)

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

    # ---------------------------------------------------------------------------
    # IA AGÉNTICA EN CLI (desarrollo autónomo de apps)
    # ---------------------------------------------------------------------------
    aichat              # chat/agente CLI con muchos proveedores (muy ligero)
    codex               # agente de OpenAI en terminal (programa autónomo)
    goose-cli           # agente de código de Block (MCP, autónomo)
    gemini-cli          # agente de Google en terminal
    ddgr                # DuckDuckGo desde CLI (búsqueda rápida)
  ];

  # ---------------------------------------------------------------------------
  # DOCKER
  # ---------------------------------------------------------------------------
  # Activa el servicio de Docker (el "motor").
  virtualisation.docker.enable = true;

  # Añade el usuario `macnix` a los grupos necesarios:
  #   docker   → usar docker sin sudo
  #   dialout  → acceso a puertos serie (UART/USB de placas: STM32, nRF52...)
  #   plugdev  → reglas udev de flasheo (PlatformIO, Arduino, nRF, ST-Link)
  users.users.macnix.extraGroups = [ "docker" "dialout" "plugdev" ];

  # ---------------------------------------------------------------------------
  # UDEV para desarrollo embedded
  # ---------------------------------------------------------------------------
  # Reglas de udev comunes para no necesitar sudo al flashear placas
  # (ST-Link, DFU de nRF/STM32, USB-serial y Arduinos).
  services.udev.packages = [
    pkgs.openocd
    pkgs.stlink
    pkgs.dfu-util
    (pkgs.writeTextFile {
      name = "embed-udev-rules";
      destination = "/lib/udev/rules.d/99-embed.rules";
      text = ''
        # ST-Link (ST-LINK/V2, /V3)
        ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3748|374a|374b|374d|374e|374f", MODE="664", GROUP="plugdev"
        # Bluefruit / Adafruit nRF52 (DFU)
        ATTRS{idVendor}=="239a", ATTRS{idProduct}=="0029|002b", MODE="664", GROUP="plugdev"
        # Nordic nRF52840-DK / nRF52-DK (JLink por USB)
        ATTRS{idVendor}=="1366", MODE="664", GROUP="plugdev"
        # USB-serial genéricos (CP210x, FTDI, CH340)
        ATTRS{idVendor}=="10c4", MODE="664", GROUP="dialout"
        ATTRS{idVendor}=="0403", MODE="664", GROUP="dialout"
        ATTRS{idVendor}=="1a86", MODE="664", GROUP="dialout"
      '';
    })
  ];

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
