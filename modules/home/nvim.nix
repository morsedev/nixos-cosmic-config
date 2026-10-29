# =============================================================================
# modules/home/nvim.nix  —  Neovim como IDE (NixVim) estilo Omarchy/LazyVim
# =============================================================================
#
# NixVim permite configurar Neovim con opciones de Nix (no con Lua suelto).
# Ventaja: Nix instala y compila todos los plugins, así que la CI puede
# comprobarlos y sabemos que funcionarán.
#
# Qué incluye (orientado a dev: Nix, Swift, Flutter, Rust, embedded, PCB):
#   - LSP: Rust, Nix, Flutter/Dart, Python, TS, C/C++, Swift (si toolchain), YAML, JSON...
#   - DAP con UI en paneles DERECHA/ABAJO (no pisa el árbol de archivos) y
#     configuración para embedded (gdb + OpenOCD, STM32/nRF52)
#   - Terminal FLOTANTE (toggleterm) + lazygit FLOTANTE  (`<leader>ft`, `<leader>gg`)
#   - flutter-tools (IDE Flutter: hot reload, dispositivo, widgets)
#   - conform-nvim (formateo al guardar), bufferline (pestañas), trouble
#     (diagnósticos), noice (UI moderna), mini.ai (text objects)
#   - Telescope (archivos/texto/proyectos), Neo-tree (árbol), cmp
#   - Transparencia estilo Omarchy: los paneles flotantes se funden con Ghostty
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
  imports = [ inputs.nixvim.homeModules.nixvim ];

  programs.nixvim = {
    enable = true;          # activa Neovim gestionado por NixVim
    defaultEditor = true;   # que sea el editor por defecto del sistema
    viAlias = true;         # el comando `vi` abre nvim
    vimAlias = true;        # el comando `vim` abre nvim

    # =========================================================================
    # OPCIONES DE EDITOR (equivalente a `set ...` en vim)
    # =========================================================================
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
    globals.mapleader = " ";
    globals.maplocalleader = " ";

    # =========================================================================
    # KEYMAPS (lista de atajos)
    # =========================================================================
    keymaps = [
      # --- Telescope: buscar ---
      { mode = "n"; key = "<leader>ff"; action = "<cmd>Telescope find_files<CR>"; options.desc = "Buscar archivos"; }
      { mode = "n"; key = "<leader>fg"; action = "<cmd>Telescope live_grep<CR>"; options.desc = "Buscar texto"; }
      { mode = "n"; key = "<leader>fb"; action = "<cmd>Telescope buffers<CR>"; options.desc = "Buffers"; }
      { mode = "n"; key = "<leader>fh"; action = "<cmd>Telescope help_tags<CR>"; options.desc = "Ayuda"; }
      { mode = "n"; key = "<leader>fr"; action = "<cmd>Telescope oldfiles<CR>"; options.desc = "Recientes"; }
      { mode = "n"; key = "<leader>fp"; action = "<cmd>Telescope project<CR>"; options.desc = "Proyectos"; }
      { mode = "n"; key = "<leader>fs"; action = "<cmd>Telescope lsp_document_symbols<CR>"; options.desc = "Símbolos"; }
      { mode = "n"; key = "<leader>gc"; action = "<cmd>Telescope git_commits<CR>"; options.desc = "Commits"; }

      # --- Neo-tree: árbol de archivos ---
      { mode = "n"; key = "<leader>e"; action = "<cmd>Neotree toggle<CR>"; options.desc = "Explorador"; }

      # --- Terminal flotante y lazygit flotante (definidos en extraConfigLua) ---
      { mode = "n"; key = "<leader>gg"; action = "<cmd>lua __lazygit_toggle()<CR>"; options.desc = "Lazygit (flotante)"; }

      # --- Trouble: panel de diagnósticos ---
      { mode = "n"; key = "<leader>xx"; action = "<cmd>Trouble toggle<CR>"; options.desc = "Toggle Trouble"; }
      { mode = "n"; key = "<leader>xw"; action = "<cmd>Trouble diagnostics toggle<CR>"; options.desc = "Diagnósticos del workspace"; }

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

      # --- Flutter (flutter-tools) ---
      { mode = "n"; key = "<leader>frr"; action = "<cmd>lua require('flutter-tools.commands').run()<CR>"; options.desc = "Flutter run"; }
      { mode = "n"; key = "<leader>fh"; action = "<cmd>lua require('flutter-tools.commands').hot_reload()<CR>"; options.desc = "Hot reload"; }
      { mode = "n"; key = "<leader>fH"; action = "<cmd>lua require('flutter-tools.commands').hot_restart()<CR>"; options.desc = "Hot restart"; }

      # --- Quitar el resaltado de búsqueda ---
      { mode = "n"; key = "<Esc>"; action = "<cmd>nohlsearch<CR>"; }
    ];

    # =========================================================================
    # PLUGINS
    # =========================================================================
    plugins = {
      # --- Navegación / búsqueda ---
      telescope = {
        enable = true;
        extensions = {
          fzf-native.enable = true;  # motor de búsqueda más rápido
          project.enable = true;     # selector de proyectos (`<leader>fp`)
        };
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

      # --- Pestañas (estilo LazyVim/Omarchy) ---
      bufferline.enable = true;

      # --- Terminal flotante (Omarchy usa esto para terminal y lazygit) ---
      toggleterm = {
        enable = true;
        settings = {
          direction = "float";            # terminal flotante
          open_mapping = "[[<leader>ft]]"; # `<leader>ft` abre/cierra la terminal
          size = 12;
          float_opts.border = "curved";
        };
      };

      # --- UI moderna (cmdline, notificaciones, message popups) ---
      noice.enable = true;

      # --- Text objects estilo mini (ai/ii) ---
      mini-ai.enable = true;

      # --- Formateo al guardar (conform) ---
      conform-nvim = {
        enable = true;
        autoInstall = {
          enable = true;   # instala los formatters automáticamente
          # Los que NO vienen en la caché de conform los damos nosotros:
          overrides = {
            alejandra = pkgs.alejandra;     # Nix
          };
        };
        settings = {
          format_on_save = {
            lsp_format = "fallback";   # si no hay formatter, usa el del LSP
            timeout_ms = 2000;
          };
          formatters_by_ft = {
            nix = [ "alejandra" ];
            lua = [ "stylua" ];
            rust = [ "rustfmt" ];
            python = [ "black" "isort" ];
            javascript = [ "prettier" ];
            javascriptreact = [ "prettier" ];
            typescript = [ "prettier" ];
            typescriptreact = [ "prettier" ];
            json = [ "prettier" ];
            jsonc = [ "prettier" ];
            yaml = [ "prettier" ];
            sh = [ "shfmt" ];
            markdown = [ "prettier" ];
            c = [ "clang-format" ];
            cpp = [ "clang-format" ];
            dart = [ "dart_format" ];
            swift = [ "swift-format" ];
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
      lsp = {
        enable = true;
        servers = {
          rust_analyzer.enable = true;  # Rust
          nil_ls.enable = true;         # Nix
          pyright.enable = true;        # Python
          ts_ls.enable = true;          # TypeScript/JavaScript
          lua_ls.enable = true;         # Lua
          clangd.enable = true;         # C/C++ (incluye embedded)
          bashls.enable = true;         # Bash
          yamlls.enable = true;         # YAML
          jsonls.enable = true;         # JSON
          # Flutter/Dart: le decimos qué paquete provee el servidor.
          dartls = {
            enable = true;
            package = pkgs.dart;
          };
          # Swift: NixVim no trae sourcekit-lsp; se configura en extraConfigLua
          # usando el toolchain de swift.org si está instalado (ver README).
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
          sources = [
            { name = "nvim_lsp"; }   # del LSP
            { name = "buffer"; }     # del texto del propio archivo
            { name = "path"; }       # rutas de archivos
            { name = "luasnip"; }    # snippets
          ];
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
      dap.enable = true;
      dap-virtual-text.enable = true; # muestra valores junto al código

      # dap-ui: paneles a la DERECHA y ABAJO para que el árbol de archivos
      # (izquierda) no se pise. Los adaptadores y configuraciones van en
      # extraConfigLua.
      dap-ui = {
        enable = true;
        settings.layouts = [
          {
            elements = [
              { id = "scopes";      size = 0.30; }
              { id = "watches";     size = 0.20; }
              { id = "stacks";      size = 0.25; }
              { id = "breakpoints"; size = 0.25; }
            ];
            size = 38;
            position = "right";
          }
          {
            elements = [
              { id = "repl";    size = 0.50; }
              { id = "console"; size = 0.50; }
            ];
            size = 28;
            position = "bottom";
          }
        ];
      };

      # --- Git ---
      gitsigns.enable = true;  # marcas en el margen (añadido/modificado...)

      # --- Flutter: IDE dentro de Neovim (hot reload, widgets, devices) ---
      flutter-tools = {
        enable = true;
        settings = {
          decorations.statusline.app_version = true;
          devices.auto_select = true;
          dev_tools.autostart = true;
        };
      };

      # --- Panel de diagnósticos / problemas (estilo IDE) ---
      trouble.enable = true;

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
    # CONFIGURACIÓN LUA EXTRA
    # =========================================================================
    extraConfigLua = ''
      -- ---------------------------------------------------------------------
      -- Swift LSP (sourcekit-lsp): lo provee el paquete swift-toolchain del
      -- sistema (modules/swift.nix). Si no está instalado, el LSP falla al
      -- abrir .swift sin romper nada.
      -- ---------------------------------------------------------------------
      vim.lsp.config("sourcekit-lsp", {
        cmd = { "sourcekit-lsp" },
        filetypes = { "swift" },
      })
      vim.lsp.enable("sourcekit-lsp")

      -- ---------------------------------------------------------------------
      -- Terminal flotante + lazygit flotante (toggleterm)
      -- ---------------------------------------------------------------------
      local Terminal = require("toggleterm.terminal").Terminal
      local lazygit = Terminal:new({ cmd = "lazygit", direction = "float", hidden = true })
      function _G.__lazygit_toggle()
        lazygit:toggle()
      end

      -- ---------------------------------------------------------------------
      -- Transparencia estilo Omarchy: los paneles flotantes se funden con
      -- Ghostty (que ya es translúcido + blur de Hyprland).
      -- ---------------------------------------------------------------------
      local transparent = {
        "Normal", "NormalFloat", "FloatBorder", "Pmenu", "PmenuSel",
        "Terminal", "StatusLine", "StatusLineNC", "WhichKeyFloat",
        "TelescopeNormal", "TelescopeBorder", "TelescopePromptNormal",
        "NeoTreeNormal", "NeoTreeNormalNC", "NeoTreeFloatTitle",
        "NotifyBackground", "MsgArea", "NoiceCmdlinePopup", "NoiceCmdlinePopupBorder",
      }
      for _, hl in ipairs(transparent) do
        vim.api.nvim_set_hl(0, hl, { bg = "NONE" })
      end

      -- ---------------------------------------------------------------------
      -- DAP: adaptadores y configuraciones
      -- ---------------------------------------------------------------------
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

      -- Embedded (STM32/nRF52): gdb + OpenOCD en el puerto 3333.
      -- Uso: arranca openocd (config de tu placa), luego F5 con el ELF.
      dap.adapters.gdb = {
        type = "executable",
        command = "arm-none-eabi-gdb",
        args = { "--interpreter=dap", "--eval-command=set pagination off" },
        name = "gdb",
      }
      dap.configurations.embedded = {
        {
          name = "OpenOCD (STM32/nRF52)",
          type = "gdb",
          request = "attach",
          target = "remote :3333",
          program = function()
            return vim.fn.input("ELF: ", vim.fn.getcwd() .. "/build/", "file")
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
      lazygit         # interfaz TUI para git (la usa el terminal flotante)
      # Formatters que usa conform (los del autoInstall los pone él mismo):
      alejandra       # formatear Nix
      # gcc-arm-embedded lo instala el módulo de sistema (development.nix); lo
      # dejamos también aquí para que nvim tenga `arm-none-eabi-gdb` en PATH.
      gcc-arm-embedded
    ];
  };
}
