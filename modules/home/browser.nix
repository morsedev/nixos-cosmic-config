# =============================================================================
# modules/home/browser.nix  —  Navegador minimalista (Firefox)
# =============================================================================
#
# HISTORIA (para que no se repita):
#   Se probó Zen Browser, pero en este equipo (Apple Silicon / Asahi) su
#   interfaz no se dibuja bien: desaparece la barra de direcciones, las páginas
#   salen en blanco y el proceso de contenido crashea. Firefox, que usa el
#   mismo motor, funciona perfectamente, así que el navegador pasa a ser
#   Firefox con una interfaz a medida.
#
# INTERFAZ QUE BUSCAMOS:
#   solo barra de direcciones + botones atrás/adelante.
#   Sin pestañas visibles, sin marcadores, sin barra de menús.
#   Las pestañas siguen existiendo y se manejan con el teclado:
#   Ctrl+T (nueva), Ctrl+W (cerrar), Ctrl+Tab (siguiente), Ctrl+1..9, etc.
#   (La lista completa está en la chuleta: Super + /)
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # FIREFOX
  # ---------------------------------------------------------------------------
  programs.firefox = {
    enable = true;

    profiles.default = {
      isDefault = true;
      # Ruta fija del perfil: así sabemos dónde vive userChrome.css.
      path = "default";

      # -----------------------------------------------------------------------
      # AJUSTES (equivalente a about:config)
      # -----------------------------------------------------------------------
      settings = {
        # --- Interfaz compacta ---
        "browser.uidensity" = 1;
        "browser.compactmode.show" = true;
        # La barra de direcciones hace de "tirador" de la ventana.
        "browser.tabs.inTitlebar" = 1;

        # --- Arranque ---
        "browser.startup.page" = 1;          # 1 = página en blanco
        "browser.startup.homepage" = "about:blank";
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;

        # --- Privacidad ---
        "privacy.donottrackheader.enabled" = true;
        "browser.contentblocking.category" = "strict";
        "privacy.trackingprotection.enabled" = true;

        # --- Comodidad ---
        # Preguntar antes de cerrar con varias pestañas (evita cierres accidentales).
        "browser.tabs.warnOnClose" = true;
        # Al cerrar la última pestaña, cerrar la ventana.
        "browser.tabs.closeWindowWithLastTab" = true;
        # Zoom por sitio.
        "browser.zoom.siteSpecific" = true;
      };

      # -----------------------------------------------------------------------
      # USERCHROME.CSS — el aspecto
      # -----------------------------------------------------------------------
      userChrome = ''
        /* ================================================================= */
        /*  FIREFOX MINIMAL — Tokyo Night                                     */
        /* ================================================================= */
        /*  Receta clásica y estable: se oculta la barra de pestañas con      */
        /*  `visibility: collapse` (NO `display:none`), que es lo que evita   */
        /*  que Firefox se quede sin barra de direcciones.                    */

        :root {
          --tn-bg:     #16161e;
          --tn-bg2:    #1f2335;
          --tn-border: #292e42;
          --tn-fg:     #c0caf5;
          --tn-dim:    #565f89;
          --tn-blue:   #7aa2f7;
        }

        /* --- 1. Sin pestañas visibles ------------------------------------ */
        #TabsToolbar { visibility: collapse !important; }

        /* --- 2. Sin marcadores ni barra de menús ------------------------- */
        #PersonalToolbar { visibility: collapse !important; }
        #toolbar-menubar { visibility: collapse !important; }

        /* --- 3. Barra superior ------------------------------------------- */
        #nav-bar {
          background: var(--tn-bg) !important;
          border-top: 0 !important;
          border-bottom: 1px solid var(--tn-border) !important;
          padding: 4px 8px !important;
          min-height: 40px !important;
        }

        /* --- 4. Barra de direcciones ------------------------------------- */
        #urlbar-background,
        #searchbar {
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

        /* --- 5. Menú de sugerencias -------------------------------------- */
        .urlbarView {
          background: var(--tn-bg) !important;
          border: 1px solid var(--tn-border) !important;
          border-radius: 12px !important;
        }
        .urlbarView-row[selected] { background: rgba(122, 162, 247, 0.18) !important; }

        /* --- 6. Botones: solo atrás / adelante --------------------------- */
        #back-button,
        #forward-button {
          border-radius: 8px !important;
        }
        #back-button:hover,
        #forward-button:hover { background: var(--tn-border) !important; }
        #back-button[disabled="true"],
        #forward-button[disabled="true"] { opacity: 0.3 !important; }

        /* El resto, fuera. Siguen accesibles por teclado:
           Ctrl+R recargar · Ctrl+J descargas · Ctrl+L dirección · Alt+Inicio */
        #reload-button,
        #stop-button,
        #home-button,
        #library-button,
        #downloads-button,
        #firefox-view-button,
        #unified-extensions-button { display: none !important; }

        /* El menú (hamburguesa) discreto: aparece al pasar el ratón. */
        #PanelUI-menu-button { opacity: 0.35 !important; border-radius: 8px !important; }
        #PanelUI-menu-button:hover {
          opacity: 1 !important;
          background: var(--tn-border) !important;
        }

        /* --- 7. Detalles -------------------------------------------------- */
        :root { scrollbar-color: var(--tn-border) transparent; }
      '';
    };
  };

  # ---------------------------------------------------------------------------
  # NAVEGADOR POR DEFECTO
  # ---------------------------------------------------------------------------
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
    };
  };
}
