# =============================================================================
# packages/swift-toolchain.nix — Swift 6.4.1 para aarch64-linux (nativo)
# =============================================================================
#
# `pkgs.swift` está roto en aarch64-linux, así que empaquetamos el toolchain
# oficial de swift.org (tarball para Ubuntu 24.04 ARM64) y lo adaptamos a
# NixOS:
#
#   1. Layout ESTÁNDAR `<out>/usr/bin/swift` (el driver calcula la raíz del
#      toolchain como dirname(dirname(swift)): sin el prefijo `usr` apunta a
#      /nix/store y la detección de swiftpm falla).
#   2. `patchelf --set-interpreter` + `--add-rpath` en todos los ELF para que
#      corran con el loader y las libs de nixpkgs.
#   3. `usr/lib/compat`: symlinks de SONAMEs que el toolchain espera y que
#      nixpkgs nombra distinto (libsqlite3.so.0, libxml2.so.2, libz3.so.4,
#      libpython3.12.so).
#   4. Objetos crt* copiados al dir de clang (el linker los necesita).
#   5. `usr/bin/swiftc` → wrapper que fija `--dynamic-linker` de NixOS en los
#      binarios que compila y exporta LIBRARY_PATH completo para el link.
#   6. `usr/bin/ld -> ld.lld` (clang busca `ld` en PATH y el toolchain solo
#      trae `ld.lld`).
#
# Resultado: `swift`, `swiftc`, `swift build/run`, `swift-format` y
# `sourcekit-lsp` funcionan directamente en NixOS aarch64, sin FHS ni
# variables de entorno globales.
#
# LIMITACIÓN CONOCIDA: `swift test` (XCTest) falla al construir el módulo C
# `SwiftGlibc` (el ClangImporter del toolchain no detecta la libc del target
# fuera de un sistema estilo Ubuntu). `swift build`, `swift run` y la
# compilación directa con `swiftc` funcionan.
#
# Licencia: toolchain de swift.org (Apache-2.0); se descarga en el build.
# =============================================================================

{ pkgs }:

let
  version = "6.4.1";
  gccLibDir = "${pkgs.gcc-unwrapped.out}/lib/gcc/aarch64-unknown-linux-gnu/${pkgs.gcc-unwrapped.version}";
  libPath = pkgs.lib.concatStringsSep ":" (
    (map (p: "${p}/lib") [
      pkgs.icu.out pkgs.curl.out pkgs.libxml2.out pkgs.zlib pkgs.sqlite.out
      pkgs.libedit.out pkgs.ncurses.out pkgs.gcc-unwrapped.lib pkgs.python3
      pkgs.z3.out pkgs.libbsd.out pkgs.glibc.out pkgs.utillinux.lib
    ]) ++ [ "$out/usr/lib/compat" ]
  );
in
pkgs.stdenv.mkDerivation {
  pname = "swift-toolchain";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://download.swift.org/swift-${version}-release/ubuntu2404-aarch64/swift-${version}-RELEASE/swift-${version}-RELEASE-ubuntu24.04-aarch64.tar.gz";
    sha256 = "0i9gjwsjc14xzpl3vlc78khd043qi38mpqzicb767hsb407dfpdq";
  };

  nativeBuildInputs = [ pkgs.patchelf ];

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    set -e
    mkdir -p $out
    # Layout ESTÁNDAR del toolchain: <root>/usr/bin/swift.
    cp -r usr $out/usr || { echo "CP FALLO"; exit 1; }
    ld="$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)"

    # Compatibilidad de SONAME (Ubuntu → nixpkgs).
    mkdir -p $out/usr/lib/compat
    ln -sf ${pkgs.sqlite.out}/lib/libsqlite3.so  $out/usr/lib/compat/libsqlite3.so.0
    ln -sf ${pkgs.libxml2.out}/lib/libxml2.so     $out/usr/lib/compat/libxml2.so.2
    ln -sf ${pkgs.z3.out}/lib/libz3.so            $out/usr/lib/compat/libz3.so.4
    ln -sf ${pkgs.python3}/lib/libpython3.14.so   $out/usr/lib/compat/libpython3.12.so

    # Objetos crt para el linker (de glibc y gcc de nixpkgs).
    crtdir=$out/usr/lib/clang/21/lib/linux
    mkdir -p $crtdir
    for f in Scrt1.o crti.o crtn.o crt1.o; do
      cp -f ${pkgs.glibc.out}/lib/$f $crtdir/ || true
    done
    for f in crtbegin.o crtbeginS.o crtend.o crtendS.o; do
      cp -f ${gccLibDir}/$f $crtdir/ || true
    done

    # Fix intérprete + rpath de TODOS los ELF.
    n=0
    for f in $(find $out -type f); do
      magic=$(od -An -tx1 -N4 "$f" 2>/dev/null | tr -d ' \n') || true
      [ "$magic" != "7f454c46" ] && continue
      if readelf -l "$f" 2>/dev/null | grep -q 'Requesting program interpreter'; then
        patchelf --set-interpreter "$ld" "$f" || { echo "FALLO interp: $f"; exit 1; }
      fi
      patchelf --add-rpath "${libPath}" "$f" 2>/dev/null || true
      n=$((n+1))
    done

    # swiftc → wrapper con --dynamic-linker de NixOS + LIBRARY_PATH completo.
    NIXLD="$ld"
    COMPAT="$out/usr/lib/compat"
    CRT="$out/usr/lib/clang/21/lib/linux"
    SYSROOT="$out/usr/lib/swift/linux/nix-sysroot"
    mv $out/usr/bin/swiftc $out/usr/bin/swiftc.orig
    cat > $out/usr/bin/swiftc <<EOF
#!/bin/sh
export LIBRARY_PATH="${pkgs.icu.out}/lib:${pkgs.curl.out}/lib:${pkgs.libxml2.out}/lib:${pkgs.zlib}/lib:${pkgs.sqlite.out}/lib:${pkgs.libedit.out}/lib:${pkgs.ncurses.out}/lib:${gccLibDir}:${pkgs.gcc-unwrapped.lib}/lib:${pkgs.python3}/lib:${pkgs.z3.out}/lib:${pkgs.libbsd.out}/lib:${pkgs.glibc.out}/lib:${pkgs.utillinux.lib}/lib:$COMPAT:$CRT"
export C_INCLUDE_PATH="${pkgs.glibc.dev}/include:${gccLibDir}/include:${pkgs.zlib.dev}/include:${pkgs.libxml2.dev}/include"
export CPLUS_INCLUDE_PATH="${pkgs.gcc-unwrapped.out}/include/c++/${pkgs.gcc-unwrapped.version}:${pkgs.gcc-unwrapped.out}/include/c++/${pkgs.gcc-unwrapped.version}/aarch64-unknown-linux-gnu:${pkgs.glibc.dev}/include"
# -Xcc --sysroot=$SYSROOT: el ClangImporter (detección de libc) solo lee los
# args -Xcc/ExtraArgs y el SearchPathOptions, NO clang.cfg. Con el sysroot en
# los args encuentra la libc y puede construir SwiftGlibc/CDispatch (XCTest).
exec "$out/usr/bin/swiftc.orig" -Xcc --sysroot="$SYSROOT" -Xlinker --dynamic-linker="$NIXLD" "\$@"
EOF
    chmod +x $out/usr/bin/swiftc

    # clang busca `ld` en PATH.
    ln -sf ld.lld $out/usr/bin/ld

    # Sysroot sintético: clang necesita encontrar libc/include del target para
    # el ClangImporter (módulos C de XCTest/Dispatch → SwiftGlibc).
    SYSROOT=$out/usr/lib/swift/linux/nix-sysroot
    # Cuidado: NO crear los destinos (usr/include, include) antes de `ln -sfn`,
    # o el symlink se crea DENTRO del dir y la libc no se encuentra.
    mkdir -p $SYSROOT/usr/lib/aarch64-unknown-linux-gnu $SYSROOT/lib/aarch64-unknown-linux-gnu $SYSROOT/usr/lib/gcc/aarch64-unknown-linux-gnu
    ln -sfn ${pkgs.glibc.dev}/include                          $SYSROOT/usr/include
    ln -sfn ${pkgs.glibc.dev}/include                          $SYSROOT/include
    ln -sfn ${pkgs.glibc.out}/lib                              $SYSROOT/lib/aarch64-unknown-linux-gnu
    ln -sfn ${pkgs.glibc.out}/lib                              $SYSROOT/usr/lib/aarch64-unknown-linux-gnu
    ln -sfn ${pkgs.gcc-unwrapped.out}/lib/gcc/aarch64-unknown-linux-gnu/${pkgs.gcc-unwrapped.version} $SYSROOT/usr/lib/gcc/aarch64-unknown-linux-gnu/${pkgs.gcc-unwrapped.version}

    # clang.cfg: clang auto-carga un fichero de config junto al binario y
    # añade estos flags a CADA invocación.
    cat > $out/usr/bin/clang.cfg <<EOF
--gcc-toolchain=${pkgs.gcc-unwrapped.out}
--sysroot=$SYSROOT
-isystem ${pkgs.glibc.dev}/include
-isystem ${gccLibDir}/include
-isystem ${pkgs.zlib.dev}/include
-isystem ${pkgs.libxml2.dev}/include
EOF

    # Exponer en $out/bin (lo que systemPackages mete en el PATH) los binarios
    # de usr/bin. El layout usr/ se mantiene para que swiftpm detecte bien la
    # raíz del toolchain (el driver resuelve /proc/self/exe hasta swift-driver
    # dentro de usr/bin, así que la raíz sigue saliendo correcta).
    mkdir -p $out/bin
    for t in swift swiftc swift-build swift-package swift-run swift-test swift-format sourcekit-lsp lldb ld; do
      [ -e "$out/usr/bin/$t" ] && ln -sf ../usr/bin/$t $out/bin/$t
    done

    echo "OK: $n ELF procesados"
  '';

  meta = {
    description = "Swift ${version} toolchain (swift.org) adaptado a NixOS aarch64";
    license = pkgs.lib.licenses.asl20;
    mainProgram = "swift";
  };
}
