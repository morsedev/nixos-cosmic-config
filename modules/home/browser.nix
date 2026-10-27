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
        "browser.startup.homepage" = "about:newtab";
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;

        # --- Privacidad ---
        "privacy.donottrackheader.enabled" = true;
        "browser.contentblocking.category" = "strict";
        "privacy.trackingprotection.enabled" = true;

        # --- Saltar la bienvenida de Firefox (perfil nuevo) ---
        # Sin esto, la primera vez se abre la página de "bienvenida" y no
        # nuestra nueva pestaña Tokyo Night.
        "browser.aboutwelcome.enabled" = false;
        "browser.startup.firstrunSkipsHomepage" = true;
        "browser.startup.homepage_override.mstone" = "ignore";
        "browser.messaging-system.whatsNewPanel.enabled" = false;
        "browser.shell.checkDefaultBrowser" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;

        # --- Comodidad ---
        # Preguntar antes de cerrar con varias pestañas (evita cierres accidentales).
        "browser.tabs.warnOnClose" = true;
        # Al cerrar la última pestaña, cerrar la ventana.
        "browser.tabs.closeWindowWithLastTab" = true;
        # Zoom por sitio.
        "browser.zoom.siteSpecific" = true;
      };

      # -----------------------------------------------------------------------
      # USERCONTENT.CSS — página de nueva pestaña / inicio
      # -----------------------------------------------------------------------
      # Se aplica a about:newtab y about:home. Pinta un fondo Tokyo Night con
      # resplandores azul/morado, oculta el logo de Firefox y estiliza la caja
      # de búsqueda y los accesos directos.
      userContent = ''
        @-moz-document url("about:newtab"),
                       url("about:home"),
                       url("about:privatebrowsing") {

          :root {
            --tn-bg:     #1a1b26;
            --tn-bg2:    #16161e;
            --tn-fg:     #c0caf5;
            --tn-dim:    #565f89;
            --tn-blue:   #7aa2f7;
            --tn-purple: #bb9af7;
          }

          body {
            background-color: var(--tn-bg) !important;
            background-image:
              radial-gradient(900px 520px at 20% 80%, rgba(122, 162, 247, 0.22), transparent 60%),
              radial-gradient(820px 480px at 80% 74%, rgba(187, 154, 247, 0.18), transparent 62%),
              radial-gradient(620px 380px at 50% 6%,  rgba(125, 207, 255, 0.10), transparent 65%),
              linear-gradient(160deg, #16161e 0%, #1a1b26 55%, #12131c 100%) !important;
            background-attachment: fixed !important;
            color: var(--tn-fg) !important;
          }

          /* Marca de agua 東京 (muy sutil) */
          .outer-wrapper::after {
            content: "東京";
            position: fixed;
            right: 5vw;
            bottom: 3vh;
            font-size: 14vw;
            line-height: 1;
            color: rgba(187, 154, 247, 0.055);
            pointer-events: none;
          }

          /* Sin logo ni textos de bienvenida de Firefox */
          .logo-and-wordmark { display: none !important; }

          /* Caja de búsqueda */
          .search-wrapper .search-handoff-button,
          .search-wrapper input,
          .search-inner-wrapper,
          .search-handoff-button {
            background: rgba(31, 35, 53, 0.92) !important;
            border: 1px solid #292e42 !important;
            border-radius: 14px !important;
            color: var(--tn-fg) !important;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.45) !important;
          }
          .search-handoff-button:hover { border-color: var(--tn-blue) !important; }

          /* Accesos directos (webs frecuentes) */
          .top-site-outer .tile {
            background: rgba(31, 35, 53, 0.85) !important;
            border: 1px solid #292e42 !important;
            border-radius: 14px !important;
          }
          .top-site-outer:hover .tile {
            background: rgba(122, 162, 247, 0.18) !important;
            border-color: rgba(122, 162, 247, 0.5) !important;
          }
          .top-site-outer .title,
          .top-site-outer .title span { color: #a9b1d6 !important; }

          /* Texto de ayuda del buscador */
          .search-handoff-button .fake-textbox,
          .fake-textbox { color: var(--tn-dim) !important; }
        }
      '';

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

          /* Variables que Firefox usa de verdad para pintar la barra.
             Sin esto, #urlbar-background se queda con el color del tema. */
          --toolbar-bgcolor: #1a1b26 !important;
          --toolbar-color: #c0caf5 !important;
          --lwt-accent-color: #16161e !important;
          --lwt-text-color: #c0caf5 !important;
          --toolbar-field-background-color: #24283b !important;
          --toolbar-field-color: #c0caf5 !important;
          --toolbar-field-border-color: #3b4261 !important;
          --toolbar-field-focus-background-color: #24283b !important;
          --toolbar-field-focus-border-color: #7aa2f7 !important;
          --lwt-toolbar-field-background-color: #24283b !important;
          --lwt-toolbar-field-focus: #24283b !important;
        }

        /* --- 1. Sin pestañas visibles ------------------------------------ */
        #TabsToolbar { visibility: collapse !important; }

        /* --- 2. Sin marcadores ni barra de menús ------------------------- */
        #PersonalToolbar { visibility: collapse !important; }
        #toolbar-menubar { visibility: collapse !important; }

        /* --- 3. Barra superior ------------------------------------------- */
        #nav-bar {
          background: #1a1b26 !important;
          border-top: 0 !important;
          border-bottom: 1px solid var(--tn-border) !important;
          padding: 4px 8px !important;
          min-height: 40px !important;
        }

        /* --- 4. Barra de direcciones ------------------------------------- */
        #urlbar-background,
        #searchbar {
          background: #24283b !important;
          border: 1px solid #3b4261 !important;
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
        #star-button-box,
        #fxa-toolbar-menu-button,
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
