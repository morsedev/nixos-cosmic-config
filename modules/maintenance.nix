# =============================================================================
# modules/maintenance.nix  —  Mantenimiento de NixOS (generaciones y basura)
# =============================================================================
#
# Objetivo:
#   1) Dejar la generación ACTUAL como "punto base": nunca se borra.
#   2) Mantener como mucho las 7 últimas generaciones del sistema.
#   3) Recoger la basura del store automáticamente.
#
# Así no se desborda el almacenamiento de /nix/store con decenas de
# generaciones acumuladas.
# =============================================================================

{ config, pkgs, lib, ... }:

let
  profile = "/nix/var/nix/profiles/system";

  # Script que marca la generación actual como "punto base" (no borrable).
  pinBase = pkgs.writeShellScript "nix-pin-base" ''
    set -euo pipefail
    gen="$(readlink ${profile} | sed -E 's/.*-([0-9]+)-link.*/\1/')"
    if [ -n "$gen" ]; then
      ${pkgs.nix}/bin/nix-env --profile ${profile} --set-flag keep true "$gen"
      echo "generación $gen marcada como punto base"
    fi
  '';

  # Script que borra las generaciones más viejas dejando las 7 últimas
  # (las marcadas con keep=true no se tocan: ahí vive el "punto base").
  cleanGenerations = pkgs.writeShellScript "nix-clean-generations" ''
    set -euo pipefail
    ${pkgs.nix}/bin/nix-env --profile ${profile} --delete-generations +7
  '';
in
{
  # ---------------------------------------------------------------------------
  # RECOGIDA DE BASURA AUTOMÁTICA DEL STORE
  # ---------------------------------------------------------------------------
  # Todos los días se borra del store lo que ya no referencia ninguna
  # generación y que lleva más de 30 días sin usarse.
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 30d";
  };

  # ---------------------------------------------------------------------------
  # PUNTO BASE (la generación actual, protegida)
  # ---------------------------------------------------------------------------
  # Se marca la generación vigente con el flag "keep" para que ningún borrado
  # la toque. Se ejecuta en cada arranque y en cada reconstrucción.
  systemd.services.nix-pin-base = {
    description = "Marcar la generacion actual de NixOS como punto base";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pinBase;
    };
    wantedBy = [ "multi-user.target" ];
  };

  # ---------------------------------------------------------------------------
  # LÍMITE DE GENERACIONES (máx. 7)
  # ---------------------------------------------------------------------------
  # Una vez al día (y en cada arranque) se borran las generaciones viejas,
  # dejando solo las 7 últimas + la "punto base".
  systemd.services.nix-generation-clean = {
    description = "Limpiar generaciones viejas de NixOS (max 7)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = cleanGenerations;
    };
    startAt = "daily";
    after = [ "nix-pin-base.service" ];
    requires = [ "nix-pin-base.service" ];
  };
}
