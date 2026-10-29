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

{
  environment.systemPackages = [
    (import ../packages/swift-toolchain.nix { inherit pkgs; })
  ];
}
