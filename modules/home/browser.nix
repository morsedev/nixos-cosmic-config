{ config, pkgs, lib, inputs, ... }:

{
  # ============ ZEN BROWSER ============
  # Navegador basado en Firefox, extremadamente configurable.
  # Usa el módulo de Home Manager del flake (rama beta).
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;

    # Perfil por defecto
    profiles.default = {
      isDefault = true;
      # Ajustes del navegador
      settings = {
        # UI compacta (menos barras, más espacio)
        "browser.uidensity" = 1;
        # Privacidad estricta
        "privacy.donottrackheader.enabled" = true;
        "browser.contentblocking.category" = "strict";
      };
    };
  };

  # Zen como navegador por defecto
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
