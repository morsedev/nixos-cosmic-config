# =============================================================================
# hardware-configuration.nix  —  Declaración del disco y particiones
# =============================================================================
#
# ⚠️ ESTE ES UN ARCHIVO "STUB" SOLO PARA LA CI (GitHub Actions).
#
# En tu Mac, el instalador de NixOS genera SU PROPIO hardware-configuration.nix
# dentro de /etc/nixos, con las particiones reales. NO lo sobrescribas con
# este: si clonas el repo, conserva el tuyo.
#
# Qué hace un archivo así en un sistema real:
#   - declara el sistema de archivos raíz (fileSystems."/")
#   - indica qué dispositivo es cada partición y su tipo (ext4, vfat...)
#   - suele incluir módulos de kernel detectados por el instalador
#
# Aquí, para que la CI pueda evaluar/construir sin un disco real, declaramos
# un sistema de archivos "falso" apuntando a /dev/null.
# =============================================================================

{ config, lib, pkgs, ... }:

{
  # `fileSystems."/"` = el sistema de archivos raíz.
  fileSystems."/" = {
    # En la CI no importa el dispositivo; /dev/null basta para evaluar.
    device = "/dev/null";

    # Tipo de sistema de archivos (en el Mac real sería ext4 sobre la partición
    # de NixOS, por ejemplo /dev/nvme0n1p5).
    fsType = "ext4";
  };
}
