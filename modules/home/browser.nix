# =============================================================================
# modules/home/browser.nix  —  Zen Browser (interfaz minimalista)
# =============================================================================
#
# Zen es un navegador basado en Firefox, muy configurable y con temas.
# Se instala con el módulo de Home Manager que provee el flake `zen-browser`.
#
# INTERFAZ QUE BUSCAMOS:
#   solo barra de direcciones + botones atrás/adelante. Sin pestañas, sin
#   barra lateral, sin marcadores. Las pestañas siguen existiendo (se manejan
#   con Ctrl+Tab, Ctrl+T, Ctrl+W...), pero no se dibujan.
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

      # -----------------------------------------------------------------------
      # AJUSTES INTERNOS (equivalente a about:config)
      # -----------------------------------------------------------------------
      settings = {
        "browser.uidensity" = 1;                    # interfaz compacta
        "privacy.donottrackheader.enabled" = true;  # pide no ser rastreado
        "browser.contentblocking.category" = "strict"; # bloqueo estricto

        # --- Interfaz minimalista ---
        # Permite que userChrome.css se aplique (imprescindible).
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        # La barra de direcciones se funde con el borde de la ventana.
        "browser.tabs.inTitlebar" = 1;
        # Zen: una sola barra de herramientas (sin segunda fila).
        "zen.view.use-single-toolbar" = true;
        # Zen: modo compacto activado desde el arranque.
        "zen.view.compact.enable-at-startup" = false;
        "zen.view.compact.hide-tabbar" = false;
        "zen.view.compact.hide-toolbar" = false;
        # Zen: sin pestañas verticales ni botón de "nueva pestaña" visible.
        "zen.tabs.vertical" = false;
        "zen.tabs.show-newtab-vertical" = false;

        # --- Página de inicio limpia ---
        "browser.startup.homepage" = "about:blank";
        "browser.startup.page" = 3;                 # restaurar sesión anterior
        # Sin contenido patrocinado en la página nueva.
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        # Las búsquedas desde la barra no se envían como sugerencias pagadas.
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
      };

      # -----------------------------------------------------------------------
      # USERCHROME.CSS — el aspecto de verdad
      # -----------------------------------------------------------------------
      # Aquí "escondemos" todo lo que no sea barra de direcciones + atrás/
      # adelante, y pintamos lo que queda con la paleta Tokyo Night.
      userChrome = ''
        /* ================================================================= */
        /*  ZEN MINIMAL — solo barra de direcciones + atrás/adelante          */
        /* ================================================================= */
        /*  Regla de oro: NO tocar #titlebar ni la altura de #nav-bar,       */
        /*  porque en Zen la barra de direcciones vive ahí y desaparece.     */

        :root {
          --tn-bg:     #16161e;
          --tn-bg2:    #1f2335;
          --tn-border: #292e42;
          --tn-fg:     #c0caf5;
          --tn-dim:    #565f89;
          --tn-blue:   #7aa2f7;
        }

        /* --- Ocultar pestañas horizontales y barra de marcadores --------- */
        #TabsToolbar,
        #PersonalToolbar { display: none !important; }

        /* --- Ocultar la barra lateral de Zen (pestañas verticales) ------- */
        #zen-sidebar,
        #zen-sidebar-splitter { display: none !important; }

        /* --- Colores de la barra ----------------------------------------- */
        #navigator-toolbox {
          background: var(--tn-bg) !important;
          border-bottom: 1px solid var(--tn-border) !important;
        }
        #nav-bar { background: transparent !important; }
        toolbar { background: transparent !important; }

        /* --- Barra de direcciones ---------------------------------------- */
        #urlbar-background {
          background: var(--tn-bg2) !important;
          border: 1px solid var(--tn-border) !important;
          border-radius: 10px !important;
        }
        #urlbar[focused] > #urlbar-background {
          border-color: var(--tn-blue) !important;
          box-shadow: 0 0 0 2px rgba(122, 162, 247, 0.20) !important;
        }
        #urlbar-input { color: var(--tn-fg) !important; }
        #urlbar-input::placeholder { color: var(--tn-dim) !important; }

        /* --- Menú de sugerencias ----------------------------------------- */
        .urlbarView {
          background: var(--tn-bg) !important;
          border: 1px solid var(--tn-border) !important;
          border-radius: 12px !important;
        }
        .urlbarView-row[selected] { background: rgba(122, 162, 247, 0.18) !important; }

        /* --- Botones: atrás / adelante ----------------------------------- */
        #back-button,
        #forward-button { border-radius: 8px !important; }
        #back-button:hover,
        #forward-button:hover { background: var(--tn-border) !important; }
        #back-button[disabled="true"],
        #forward-button[disabled="true"] { opacity: 0.3 !important; }

        /* Lo demás, fuera. Sigue disponible por teclado (Ctrl+R, Ctrl+J...) */
        #reload-button,
        #stop-button,
        #home-button,
        #downloads-button,
        #unified-extensions-button { display: none !important; }

        /* El menú (hamburguesa) discreto, visible al pasar el ratón */
        #PanelUI-menu-button { opacity: 0.35 !important; border-radius: 8px !important; }
        #PanelUI-menu-button:hover {
          opacity: 1 !important;
          background: var(--tn-border) !important;
        }
      '';
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
