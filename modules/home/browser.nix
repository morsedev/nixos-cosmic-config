# =============================================================================
# modules/home/browser.nix  —  Zen Browser
# =============================================================================
#
# Zen es un navegador basado en Firefox, muy configurable y con temas.
# Se instala con el módulo de Home Manager que provee el flake `zen-browser`.
#
# `{ inputs }:` → recibe los inputs del flake (necesitamos inputs.zen-browser).
# =============================================================================

{ inputs }:
{ config, pkgs, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # MÓDULO DEL NAVEGADOR
  # ---------------------------------------------------------------------------
  # `inputs.zen-browser.homeModules.beta` es el módulo que define las opciones
  # `programs.zen-browser.*`. Hay que importarlo para poder usarlas.
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;

    # -------------------------------------------------------------------------
    # PERFIL
    # -------------------------------------------------------------------------
    # Un "perfil" es una configuración de navegador (marcadores, ajustes...).
    profiles.default = {
      isDefault = true;   # usar este perfil por defecto

      # Ajustes internos del navegador (los mismos de about:config).
      settings = {
        "browser.uidensity" = 1;                    # interfaz compacta
        "privacy.donottrackheader.enabled" = true;  # pide no ser rastreado
        "browser.contentblocking.category" = "strict"; # bloqueo estricto
      };
    };
  };

  # ---------------------------------------------------------------------------
  # NAVEGADOR POR DEFECTO
  # ---------------------------------------------------------------------------
  # Cuando pulses un enlace (http/https), se abrirá Zen.
  # Los nombres `*.desktop` son los "lanzadores" de las apps en Linux.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "zen-beta.desktop" ];
      "x-scheme-handler/http" = [ "zen-beta.desktop" ];
      "x-scheme-handler/https" = [ "zen-beta.desktop" ];
      "x-scheme-handler/about" = [ "zen-beta.desktop" ];
    };
  };
}
