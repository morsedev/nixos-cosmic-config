# =============================================================================
# modules/swift.nix  —  Compilación de Swift en aarch64-linux
# =============================================================================
#
# `pkgs.swift` está roto en aarch64-linux, así que instalamos el toolchain
# oficial de swift.org empaquetado a medida (ver packages/swift-toolchain.nix).
#
# Aporta:
#   swift, swiftc, swift build/run/test, swift-format, sourcekit-lsp, lldb...
#   Listo para que Neovim use sourcekit-lsp (ver modules/home/nvim.nix).
#
# Nota: la primera `nixos-rebuild` descarga ~1 GB (el tarball de swift.org).
# =============================================================================

{ config, pkgs, lib, ... }:

let
  swift = import ../packages/swift-toolchain.nix { inherit pkgs; };
  gccLibDir = "${pkgs.gcc-unwrapped.out}/lib/gcc/aarch64-unknown-linux-gnu/${pkgs.gcc-unwrapped.version}";
in
{
  environment.systemPackages = [ swift ];

  # El frontend de Swift (swift-frontend) lo lanza swift build directamente y
  # usa el ClangImporter para módulos C (XCTest → CDispatch necesita
  # sys/param.h). Hay que darle los headers de glibc/gcc en el entorno, no solo
  # en el wrapper de swiftc.
  environment.sessionVariables = {
    # SDKROOT apunta al "sysroot/sdk" sintético del paquete: le da a swift (y al
    # ClangImporter) la libc + headers + runtime. Sin esto `import Glibc`,
    # `swift test` (XCTest) y módulos C fallan con "missing required module
    # SwiftGlibc" (el driver lee SDKROOT en Driver.swift).
    SDKROOT = "${swift}/usr/lib/swift/linux/nix-sysroot";
    C_INCLUDE_PATH = lib.concatStringsSep ":" [
      "${pkgs.glibc.dev}/include"
      "${gccLibDir}/include"
      "${pkgs.zlib.dev}/include"
      "${pkgs.libxml2.dev}/include"
    ];
    CPLUS_INCLUDE_PATH = lib.concatStringsSep ":" [
      "${pkgs.gcc-unwrapped.out}/include/c++/${pkgs.gcc-unwrapped.version}"
      "${pkgs.gcc-unwrapped.out}/include/c++/${pkgs.gcc-unwrapped.version}/aarch64-unknown-linux-gnu"
      "${pkgs.glibc.dev}/include"
    ];
  };
}
