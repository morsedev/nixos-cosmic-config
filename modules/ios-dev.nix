# =============================================================================
# modules/ios-dev.nix  —  Desarrollo iOS desde Linux (xtool / omarchy-apple-dev)
# =============================================================================
#
# Instala el tooling para compilar e instalar apps iOS (SwiftUI/Flutter) en un
# iPhone físico SIN macOS ni Xcode, sobre este Linux:
#
#   - omarchy-apple-dev (joshuaswarren/omarchy-apple-dev): install-toolchain.sh,
#     device-run.sh, ship.sh, tools/...  → expuestos como comandos.
#   - xtool (nuestro fork: github.com/morsedev/xtool) se compila desde el
#     instalador (necesita cargo/rustc, incluidos aquí).
#   - Swift: lo aporta modules/swift.nix (ya en el sistema).
#   - Deps de runtime: rcodesign (firmado), git, llvm/rsync (build Flutter),
#     usbmuxd (parsing del iPhone). pymobiledevice3 + cryptography los instala
#     el propio instalador en un venv (en nixpkgs su dep pyimg4 está rota).
#
# FLUJO (interactivo, una vez por máquina):
#   1. `install-toolchain.sh --user-only`  (usa NUESTRO swift de modules/swift.nix)
#   2. Al llegar al paso del SDK te indica qué Xcode descargar
#      (https://developer.apple.com/download/all/?q=Xcode) y:
#      `XCODE_XIP=/ruta/Xcode.xip install-toolchain.sh`
#   3. `xtool new Hola; cd Hola; xtool dev run`
#   4. Con el iPhone por USB y "Trust": `device-run.sh`
#   Ver GETTING-STARTED.md del repo omarchy-apple-dev para más.
#
# NOTA: el SDK de iOS solo existe dentro de Xcode, así que ese único download
# no se puede automatizar (requiere Apple ID).
# =============================================================================

{ config, pkgs, lib, ... }:

let
  # Pin de omarchy-apple-dev (2026-10-29). Actualizar con:
  #   nix-prefetch-url --unpack https://github.com/joshuaswarren/omarchy-apple-dev/archive/<rev>.tar.gz
  omarchyAppleDev = pkgs.stdenv.mkDerivation {
    pname = "omarchy-apple-dev";
    version = "2026-10-29";

    src = pkgs.fetchFromGitHub {
      owner = "joshuaswarren";
      repo = "omarchy-apple-dev";
      rev = "79bda716bf207924efc25bce923bda261dc67837";
      sha256 = "1panb4xml83d8m9azw15pvla2mn10v48b3r76sa1981avc2cc190";
    };

    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;
    nativeBuildInputs = [ pkgs.perl ];

    patchPhase = ''
      # Con `set -e` + `set -o pipefail`, la comprobación de lldb
      # (`lldb_missing=$(ldd ... | awk | sort -u)`) muere en NixOS cuando
      # `ldd` devuelve no-cero (libs "not found"). Es solo un WARNING: le
      # añadimos `|| true` para que no aborte el instalador.
      perl -0pi -e "s/awk '\/not found\/ \{print \\\$1\}' \| sort -u\)/awk '\/not found\/ {print \\\$1}' | sort -u || true)/" install-toolchain.sh
    '';

    installPhase = ''
      mkdir -p $out/libexec/omarchy-apple-dev
      cp -r . $out/libexec/omarchy-apple-dev/
      # Wrappers de los scripts principales.
      mkdir -p $out/bin
      for s in install-toolchain.sh device-run.sh ship.sh ship-mac.sh; do
        cat > $out/bin/$s <<EOF
#!/bin/sh
exec $out/libexec/omarchy-apple-dev/$s "\$@"
EOF
        chmod +x $out/bin/$s
      done
    '';
  };
in
{
  environment.systemPackages = with pkgs; [
    omarchyAppleDev
    rcodesign                          # firmado de .app/.ipa
    git
    llvm                               # build de Flutter (ibtool etc.)
    rsync
    cargo                             # para compilar xtool desde fuente
    rustc
    python3
    # Deps que pide install-toolchain.sh / el build de xtool:
    zip unzip                          # empaquetado .ipa
    poppler-utils                     # pdftocairo (iconos/PDF)
    libheif                            # heif-convert
    libimobiledevice                   # comunicación con el iPhone
    openssl                            # headers openssl para xtool build
  ];

  # Servicio de usbmuxd: el demonio que comunica Linux con el iPhone por USB
  # (lo usa device-run.sh para el pairing). Activa la detección del iPhone.
  services.usbmuxd.enable = true;

  # Headers para los módulos C de xtool/zsign (openssl, libimobiledevice) y de
  # glibc/gcc. El build de xtool compila C/C++ vía clang del toolchain de swift
  # y necesita estos include dirs en el entorno.
  environment.sessionVariables = {
    C_INCLUDE_PATH = lib.concatStringsSep ":" [
      "${pkgs.openssl.dev}/include"
      "${pkgs.libimobiledevice.dev}/include"
      "${pkgs.glibc.dev}/include"
      "${pkgs.gcc-unwrapped.out}/lib/gcc/aarch64-unknown-linux-gnu/${pkgs.gcc-unwrapped.version}/include"
      "${pkgs.zlib.dev}/include"
      "${pkgs.libxml2.dev}/include"
    ];
    CPLUS_INCLUDE_PATH = lib.concatStringsSep ":" [
      "${pkgs.openssl.dev}/include"
      "${pkgs.libimobiledevice.dev}/include"
      "${pkgs.gcc-unwrapped.out}/include/c++/${pkgs.gcc-unwrapped.version}"
      "${pkgs.gcc-unwrapped.out}/include/c++/${pkgs.gcc-unwrapped.version}/aarch64-unknown-linux-gnu"
      "${pkgs.gcc-unwrapped.out}/include/c++/${pkgs.gcc-unwrapped.version}/backward"
      "${pkgs.glibc.dev}/include"
    ];
    # xtool-core usa pkg-config para encontrar openssl y libimobiledevice.
    PKG_CONFIG_PATH = lib.concatStringsSep ":" [
      "${pkgs.openssl.dev}/lib/pkgconfig"
      "${pkgs.libimobiledevice.dev}/lib/pkgconfig"
    ];
  };
}
