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
        # Zen: una sola barra de herramientas (sin segunda fila) y barra
        # lateral PLEGADA por defecto: las pestañas quedan ocultas y solo se
        # ven al pasar el ratón por el borde izquierdo.
        # OJO: `use-single-toolbar = true` mueve la barra de direcciones DENTRO
        # de la barra lateral; si además se pliega la lateral, desaparece la
        # barra de direcciones. Por eso aquí va en FALSE: la barra de
        # direcciones se queda arriba, siempre visible.
        "zen.view.use-single-toolbar" = false;
        "zen.view.sidebar-expanded" = true;
        "zen.view.show-newtab-button-top" = false;
        "zen.view.hide-window-controls" = false;
        # Zen: modo compacto activado desde el arranque.
        # Zen: sin pestañas verticales ni botón de "nueva pestaña" visible.

        # --- Página de inicio limpia ---
        "browser.startup.homepage" = "about:blank";
        # 1 = página en blanco. (3 = restaurar sesión, pero si una pestaña
        # crasheó, se queda crasheando en cada arranque.)
        "browser.startup.page" = 1;

        # --- Estabilidad en Apple Silicon / Asahi ---
        # La aceleración por GPU hace crashear el proceso de contenido de Zen
        # en este equipo ("Gah. Your tab just crashed"). Con WebRender por
        # software va fino; el navegador se nota algo menos fluido pero estable.
        "gfx.webrender.software" = true;
        "gfx.webrender.all" = false;
        "layers.acceleration.disabled" = true;
        "media.ffmpeg.vaapi.enabled" = false;
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
        /*  ZEN MINIMAL — cosmética Tokyo Night + sin pestañas visibles       */
        /* ================================================================= */
        /*  IMPORTANTE: la barra de direcciones de Zen vive en                 */
        /*  #zen-appcontent-navbar-wrapper. NO ocultar #titlebar, #nav-bar ni  */
        /*  #navigator-toolbox: si se ocultan, desaparece toda la barra.       */

        :root {
          --tn-bg:     #16161e;
          --tn-bg2:    #1f2335;
          --tn-border: #292e42;
          --tn-fg:     #c0caf5;
          --tn-dim:    #565f89;
          --tn-blue:   #7aa2f7;
        }

        /* --- Marcadores: fuera ------------------------------------------- */
        /* OJO: NO ocultar #TabsToolbar. En Zen la barra de direcciones está
           dentro de esa barra; si se oculta, desaparece el campo de URL. */
        #PersonalToolbar { display: none !important; }

        /* --- Barra superior ---------------------------------------------- */
        #navigator-toolbox,
        #zen-appcontent-navbar-wrapper,
        #zen-appcontent-navbar-container {
          background: var(--tn-bg) !important;
          border-bottom: 1px solid var(--tn-border) !important;
        }

        /* --- Barra de direcciones ---------------------------------------- */
        /* Zen colapsa el campo a 0px cuando la barra lateral está plegada.
           Forzamos su ancho para que siempre sea visible. */
        #nav-bar {
          display: flex !important;
          min-height: 38px !important;
        }
        #nav-bar-customization-target {
          display: flex !important;
          flex: 1 1 auto !important;
        }
        #urlbar-container {
          flex: 1 1 auto !important;
          min-width: 320px !important;
          width: auto !important;
        }
        #urlbar { min-width: 320px !important; }

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

        /* --- Sugerencias -------------------------------------------------- */
        .urlbarView {
          background: var(--tn-bg) !important;
          border: 1px solid var(--tn-border) !important;
          border-radius: 12px !important;
        }
        .urlbarView-row[selected] { background: rgba(122, 162, 247, 0.18) !important; }

        /* --- Botones ------------------------------------------------------ */
        #back-button,
        #forward-button { border-radius: 8px !important; }
        #back-button:hover,
        #forward-button:hover { background: var(--tn-border) !important; }
        #back-button[disabled="true"],
        #forward-button[disabled="true"] { opacity: 0.3 !important; }

        #reload-button,
        #stop-button,
        #home-button,
        #downloads-button,
        #unified-extensions-button { display: none !important; }

        #PanelUI-menu-button { opacity: 0.35 !important; border-radius: 8px !important; }
        #PanelUI-menu-button:hover { opacity: 1 !important; background: var(--tn-border) !important; }

        /* --- Separador de la barra lateral ------------------------------- */
        #zen-sidebar-splitter { display: none !important; }
      '';
    };
  };

  # ---------------------------------------------------------------------------
  # ARREGLO DEL PERFIL
  # ---------------------------------------------------------------------------
  # El módulo de Zen genera ~/.config/zen/profiles.ini SIN la sección
  # [Profile0], así que el navegador no reconoce el perfil y muestra
  # "Your Zen profile cannot be loaded". Además es un enlace de solo lectura.
  # Este script (se ejecuta tras cada activación de Home Manager) lo sustituye
  # por un archivo válido y escribible.
  home.activation.fixZenProfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.config/zen/profiles.ini"
    if [ -L "$target" ] || [ ! -f "$target" ]; then
      rm -f "$target"
      cat > "$target" <<'INI'
[Profile0]
Name=default
IsRelative=1
Path=default
Default=1

[General]
StartWithLastProfile=1
Version=2
INI
    fi
  '';

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
