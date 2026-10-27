# =============================================================================
# modules/home/nvim.nix  —  Neovim como IDE (NixVim, estilo kickstart)
# =============================================================================
#
# NixVim permite configurar Neovim con opciones de Nix (no con Lua suelto).
# Ventaja: Nix instala y compila todos los plugins, así que la CI puede
# comprobarlos y sabemos que funcionarán en tu máquina.
#
# Qué incluye:
#   - LSP (autocompletado/errores): Rust, Nix, Flutter/Dart, Python, TS, C/C++...
#   - DAP (depuración) con DAP UI y breakpoints
#   - Telescope (buscar archivos/texto), Neo-tree (árbol de archivos)
#   - cmp (menú de autocompletado), Treesitter (resaltado de sintaxis)
#   - Tema Tokyo Night
#
# `{ inputs }:` → recibe los inputs del flake (necesitamos inputs.nixvim).
# =============================================================================

{ inputs }:
{ config, pkgs, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # MÓDULO DE NIXVIM
  # ---------------------------------------------------------------------------
  # Importa el módulo que define las opciones `programs.nixvim.*`.
  imports = [ inputs.nixvim.homeModules.nixvim ];

  programs.nixvim = {
    enable = true;          # activa Neovim gestionado por NixVim
    defaultEditor = true;   # que sea el editor por defecto del sistema
    viAlias = true;         # el comando `vi` abre nvim
    vimAlias = true;        # el comando `vim` abre nvim

    # =========================================================================
    # OPCIONES DE EDITOR (equivalente a `set ...` en vim)
    # =========================================================================
    # Cada clave es una opción de Neovim y su valor.
    opts = {
      number = true;             # números de línea
      relativenumber = true;     # números relativos a la línea actual
      mouse = "a";               # ratón activado en todos los modos
      clipboard = "unnamedplus"; # usar el portapapeles del sistema
      breakindent = true;        # al hacer wrap, respeta la indentación
      undofile = true;           # guarda historial de deshacer en disco
      ignorecase = true;         # búsqueda sin distinguir mayúsculas...
      smartcase = true;          # ...salvo si escribes mayúsculas
      signcolumn = "yes";        # columna para iconos (errores, git)
      updatetime = 250;          # ms para mostrar diagnósticos
      timeoutlen = 300;          # ms de espera para atajos combinados
      splitright = true;         # splits nuevos a la derecha
      splitbelow = true;         # splits nuevos abajo
      list = true;               # mostrar caracteres invisibles
      listchars = { tab = "» "; trail = "·"; nbsp = "␣"; };
      inccommand = "split";      # previsualiza sustituciones (:s) en un split
      cursorline = true;         # resalta la línea actual
      scrolloff = 8;             # líneas de margen al hacer scroll
      termguicolors = true;      # colores de 24 bits
      tabstop = 4;               # tabulación = 4 espacios
      shiftwidth = 4;            # indentación = 4 espacios
      expandtab = true;          # usa espacios en vez de tabuladores
      smartindent = true;        # indentación automática
      wrap = false;              # no partir líneas largas
    };

    # =========================================================================
    # TEMA
    # =========================================================================
    colorschemes.tokyonight = {
      enable = true;
      settings.style = "night";  # variante "night" de Tokyo Night
    };

    # =========================================================================
    # ATAJOS GLOBALES (leader)
    # =========================================================================
    # `leader` es la tecla "líder" para atajos. Aquí es la barra espaciadora.
    globals.mapleader = " ";
    globals.maplocalleader = " ";

    # =========================================================================
    # KEYMAPS (lista de atajos)
    # =========================================================================
    # Cada elemento es un conjunto con:
    #   mode    → modo de vim ("n" = normal, "i" = insert, "v" = visual)
    #   key     → la combinación (<leader>ff = espacio+f+f)
    #   action  → qué ejecuta (un comando de vim entre <cmd>...</cmd>)
    #   options → extras, como la descripción que sale en el menú de ayuda
    keymaps = [
      # --- Telescope: buscar ---
      { mode = "n"; key = "<leader>ff"; action = "<cmd>Telescope find_files<CR>"; options.desc = "Buscar archivos"; }
      { mode = "n"; key = "<leader>fg"; action = "<cmd>Telescope live_grep<CR>"; options.desc = "Buscar texto"; }
      { mode = "n"; key = "<leader>fb"; action = "<cmd>Telescope buffers<CR>"; options.desc = "Buffers"; }
      { mode = "n"; key = "<leader>fh"; action = "<cmd>Telescope help_tags<CR>"; options.desc = "Ayuda"; }
      { mode = "n"; key = "<leader>fr"; action = "<cmd>Telescope oldfiles<CR>"; options.desc = "Recientes"; }
      { mode = "n"; key = "<leader>fs"; action = "<cmd>Telescope lsp_document_symbols<CR>"; options.desc = "Símbolos"; }
      { mode = "n"; key = "<leader>gc"; action = "<cmd>Telescope git_commits<CR>"; options.desc = "Commits"; }

      # --- Neo-tree: árbol de archivos ---
      { mode = "n"; key = "<leader>e"; action = "<cmd>Neotree toggle<CR>"; options.desc = "Explorador"; }

      # --- Moverte entre ventanas (Ctrl + h/j/k/l) ---
      { mode = "n"; key = "<C-h>"; action = "<C-w>h"; options.desc = "Izquierda"; }
      { mode = "n"; key = "<C-j>"; action = "<C-w>j"; options.desc = "Abajo"; }
      { mode = "n"; key = "<C-k>"; action = "<C-w>k"; options.desc = "Arriba"; }
      { mode = "n"; key = "<C-l>"; action = "<C-w>l"; options.desc = "Derecha"; }

      # --- LSP: navegar código ---
      { mode = "n"; key = "gd"; action = "<cmd>Telescope lsp_definitions<CR>"; options.desc = "Definición"; }
      { mode = "n"; key = "gr"; action = "<cmd>Telescope lsp_references<CR>"; options.desc = "Referencias"; }
      { mode = "n"; key = "K"; action = "<cmd>lua vim.lsp.buf.hover()<CR>"; options.desc = "Documentación"; }
      { mode = "n"; key = "<leader>rn"; action = "<cmd>lua vim.lsp.buf.rename()<CR>"; options.desc = "Renombrar"; }
      { mode = "n"; key = "<leader>ca"; action = "<cmd>lua vim.lsp.buf.code_action()<CR>"; options.desc = "Code action"; }
      { mode = "n"; key = "<leader>f"; action = "<cmd>lua vim.lsp.buf.format({ async = true })<CR>"; options.desc = "Formatear"; }
      { mode = "n"; key = "[d"; action = "<cmd>lua vim.diagnostic.goto_prev()<CR>"; options.desc = "Diag anterior"; }
      { mode = "n"; key = "]d"; action = "<cmd>lua vim.diagnostic.goto_next()<CR>"; options.desc = "Diag siguiente"; }

      # --- DAP: depuración con breakpoints ---
      { mode = "n"; key = "<F5>"; action = "<cmd>lua require('dap').continue()<CR>"; options.desc = "Debug continuar"; }
      { mode = "n"; key = "<F10>"; action = "<cmd>lua require('dap').step_over()<CR>"; options.desc = "Paso a paso"; }
      { mode = "n"; key = "<F11>"; action = "<cmd>lua require('dap').step_into()<CR>"; options.desc = "Entrar"; }
      { mode = "n"; key = "<F12>"; action = "<cmd>lua require('dap').step_out()<CR>"; options.desc = "Salir"; }
      { mode = "n"; key = "<leader>b"; action = "<cmd>lua require('dap').toggle_breakpoint()<CR>"; options.desc = "Breakpoint"; }
      { mode = "n"; key = "<leader>B"; action = "<cmd>lua require('dap').set_breakpoint(vim.fn.input('Condición: '))<CR>"; options.desc = "Breakpoint condicional"; }
      { mode = "n"; key = "<leader>du"; action = "<cmd>lua require('dapui').toggle()<CR>"; options.desc = "Toggle DAP UI"; }
      { mode = "n"; key = "<leader>dr"; action = "<cmd>lua require('dap').repl.toggle()<CR>"; options.desc = "DAP REPL"; }
      { mode = "n"; key = "<leader>db"; action = "<cmd>Telescope dap list_breakpoints<CR>"; options.desc = "Lista breakpoints"; }

      # --- Quitar el resaltado de búsqueda ---
      { mode = "n"; key = "<Esc>"; action = "<cmd>nohlsearch<CR>"; }
    ];

    # =========================================================================
    # PLUGINS
    # =========================================================================
    # `enable = true` instala y configura el plugin. Cada bloque es un plugin.
    plugins = {
      # --- Navegación / búsqueda ---
      telescope = {
        enable = true;
        extensions.fzf-native.enable = true;  # motor de búsqueda más rápido
      };
      neo-tree = {
        enable = true;
        settings = {
          close_if_last_window = true;  # cerrar si era la única ventana
          window.width = 34;            # ancho del panel del árbol
          filesystem = {
            follow_current_file = true;       # sigue el archivo que editas
            use_libuv_file_watcher = true;    # refresca al cambiar archivos
            filtered_items = {
              visible = true;         # ver archivos filtrados
              hide_dotfiles = false;  # mostrar archivos ocultos
              hide_gitignored = false;# mostrar los ignorados por git
            };
          };
        };
      };

      # --- Sintaxis (resaltado, indentación) ---
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
          auto_install = true;
          # Lenguajes a instalar de antemano:
          ensure_installed = [
            "lua" "vim" "vimdoc" "query"
            "rust" "c" "cpp" "python" "nix"
            "swift" "dart" "json" "yaml" "toml"
            "bash" "markdown" "markdown_inline" "html" "css" "javascript" "typescript"
          ];
        };
      };

      # --- LSP (servidores de lenguaje) ---
      # Cada servidor da autocompletado, errores, ir a definición, etc.
      lsp = {
        enable = true;
        servers = {
          rust_analyzer.enable = true;  # Rust
          nil_ls.enable = true;         # Nix
          pyright.enable = true;        # Python
          ts_ls.enable = true;          # TypeScript/JavaScript
          lua_ls.enable = true;         # Lua
          clangd.enable = true;         # C/C++
          bashls.enable = true;         # Bash
          yamlls.enable = true;         # YAML
          jsonls.enable = true;         # JSON
          # Swift: sourcekit LSP no disponible en aarch64 (swift roto en nixpkgs).
          # Se configura aparte si instalas el toolchain oficial de swift.org.

          # Flutter/Dart: le decimos qué paquete provee el servidor.
          dartls = {
            enable = true;
            package = pkgs.dart;
          };
        };
        # Atajos específicos de LSP (se activan cuando hay un servidor activo).
        keymaps = {
          silent = true;
          lspBuf = {
            "gd" = "definition";
            "K" = "hover";
            "<leader>rn" = "rename";
            "<leader>ca" = "code_action";
          };
        };
      };

      # --- Autocompletado (nvim-cmp) ---
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          # De dónde saca las sugerencias:
          sources = [
            { name = "nvim_lsp"; }   # del LSP
            { name = "buffer"; }     # del texto del propio archivo
            { name = "path"; }       # rutas de archivos
            { name = "luasnip"; }    # snippets
          ];
          # Teclas del menú de autocompletado.
          mapping = {
            "<C-Space>" = "cmp.mapping.complete()";              # abrir menú
            "<CR>" = "cmp.mapping.confirm({ select = true })";   # aceptar
            "<Tab>" = "cmp.mapping.select_next_item()";          # siguiente
            "<S-Tab>" = "cmp.mapping.select_prev_item()";        # anterior
          };
        };
      };
      luasnip.enable = true;  # motor de snippets

      # --- Depuración (DAP = Debug Adapter Protocol) ---
      dap.enable = true;              # motor de depuración
      dap-ui.enable = true;           # paneles (variables, breakpoints...)
      dap-virtual-text.enable = true; # muestra valores junto al código

      # --- Git ---
      gitsigns.enable = true;  # marcas en el margen (añadido/modificado...)

      # --- Calidad de vida ---
      which-key.enable = true;      # menú que muestra atajos disponibles
      comment.enable = true;        # comentar con gc
      nvim-autopairs.enable = true; # cerrar paréntesis/comillas solo
      nvim-surround.enable = true;  # rodear texto con comillas/paréntesis
      leap.enable = true;           # saltar a cualquier sitio (s + 2 letras)
      todo-comments.enable = true;  # resalta TODO/FIXME
      lualine.enable = true;        # barra de estado inferior
      web-devicons.enable = true;   # iconos de archivos
    };

    # =========================================================================
    # CONFIGURACIÓN LUA EXTRA (para DAP: adaptadores y configuraciones)
    # =========================================================================
    # `extraConfigLua = ''...''` es una cadena de VARIAS LÍNEAS con código Lua,
    # que NixVim añade tal cual a la config de Neovim.
    #
    # ⚠️ OJO con `${...}`: dentro de `''...''`, Nix interpreta `${...}` como
    # inserción de un valor de Nix. Por eso:
    #   - `${pkgs.lldb}`  → SÍ queremos que Nix inserte la ruta del paquete.
    #   - `''${workspaceFolder}` → queremos el TEXTO literal `${workspaceFolder}`
    #     (una variable de DAP), así que se escapa con `''${`.
    extraConfigLua = ''
      local dap = require("dap")
      local dapui = require("dapui")

      -- Abrir/cerrar los paneles de DAP con cada sesión de depuración.
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      -- Adaptador lldb-dap (viene con pkgs.lldb). Sirve para Rust, C/C++ y Swift.
      -- Aquí ${pkgs.lldb} lo sustituye Nix por la ruta real en /nix/store.
      dap.adapters.lldb = {
        type = "executable",
        command = "${pkgs.lldb}/bin/lldb-dap",
        name = "lldb",
      }

      -- Configuración para Rust (binario en target/debug/).
      dap.configurations.rust = {
        {
          name = "Launch",
          type = "lldb",
          request = "launch",
          program = function()
            return vim.fn.input("Binario: ", vim.fn.getcwd() .. "/target/debug/", "file")
          end,
          cwd = "''${workspaceFolder}",
          stopOnEntry = false,
        },
      }
      -- C y C++ reutilizan la misma configuración que Rust.
      dap.configurations.c = dap.configurations.rust
      dap.configurations.cpp = dap.configurations.rust

      -- Configuración para Swift (binario en .build/debug/).
      dap.configurations.swift = {
        {
          name = "Launch",
          type = "lldb",
          request = "launch",
          program = function()
            return vim.fn.input("Binario Swift: ", vim.fn.getcwd() .. "/.build/debug/", "file")
          end,
          cwd = "''${workspaceFolder}",
        },
      }
    '';

    # =========================================================================
    # PAQUETES EXTERNOS QUE USA NEOVIM
    # =========================================================================
    extraPackages = with pkgs; [
      lldb            # depurador (incluye lldb-dap)
      nixpkgs-fmt     # formatear Nix
      stylua          # formatear Lua
      prettier        # formatear JS/TS/HTML/CSS/JSON
      ripgrep         # búsqueda de texto (Telescope live_grep)
      fd              # búsqueda de archivos (Telescope find_files)
    ];
  };
}
