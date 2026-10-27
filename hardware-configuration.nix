# Stub SOLO para la CI (GitHub Actions).
# En tu Mac, este archivo NO se usa: el instalador genera el suyo con el
# sistema de archivos real y lo dejas en /etc/nixos/hardware-configuration.nix.
# Si clonas este repo, NO sobrescribas tu hardware-configuration.nix real.
{ config, lib, pkgs, ... }:
{
  fileSystems."/" = {
    device = "/dev/null";
    fsType = "ext4";
  };
}
