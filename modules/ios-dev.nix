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
#   - Deps de runtime: pymobiledevice3 (venv), cryptography, rcodesign
#     (firmado), git, llvm/rsync (build Flutter), usbmuxd (parsing del iPhone).
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
    python3Packages.pymobiledevice3   # pairing/instalación de apps en el iPhone
    python3Packages.cryptography
    rcodesign                          # firmado de .app/.ipa
    git
    llvm                               # build de Flutter (ibtool etc.)
    rsync
    cargo                             # para compilar xtool desde fuente
    rustc
    python3
  ];

  # Servicio de usbmuxd: el demonio que comunica Linux con el iPhone por USB
  # (lo usa device-run.sh para el pairing). Activa la detección del iPhone.
  services.usbmuxd.enable = true;
}
