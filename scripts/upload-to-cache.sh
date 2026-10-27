#!/bin/sh
# =============================================================================
# scripts/upload-to-cache.sh
# =============================================================================
# Hook que Nix ejecuta DESPUÉS de compilar algo: sube lo compilado a tu caché
# de Cachix, para no volver a compilarlo nunca (ni tú ni otra máquina).
#
# ¿Cómo se usa?
#   1) Crea una caché en https://app.cachix.org (por ejemplo "macnix").
#   2) Autentica el token EN ROOT (el hook corre como root):
#        sudo cachix authtoken <TU_TOKEN>
#   3) Cambia CACHE por el nombre de tu caché aquí abajo.
#   4) En configuration.nix, activa:
#        nix.settings.post-build-hook = "/etc/nix/upload-to-cache.sh";
#        environment.etc."nix/upload-to-cache.sh".source = ./scripts/upload-to-cache.sh;
#   5) Rebuild. A partir de ahí, cada compilación se sube sola.
#
# Nota: Nix pasa la variable OUT_PATHS con las rutas del store recién creadas.
# =============================================================================

set -eu
set -f
IFS=' '

# 👇 CAMBIA esto por el nombre de tu caché en cachix.org
CACHE="TU_CACHE"

if [ -n "${OUT_PATHS:-}" ]; then
  echo "Subiendo a la caché '$CACHE': $OUT_PATHS"
  # `cachix push` sube las rutas indicadas. --skip-complete evita re-subir
  # lo que ya está en la caché (más rápido).
  exec /run/current-system/sw/bin/cachix push --skip-complete "$CACHE" $OUT_PATHS
fi
