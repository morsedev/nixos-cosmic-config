{ config, pkgs, lib, inputs, ... }:

{
  # ============ NIXVIM (IDE completo, estilo kickstart) ============
  # Todo declarativo: los plugins los provee Nix, así que la CI los compila
  # y garantiza que funcionan en tu Mac.
  imports = [ inputs.nixvim.homeModules.nixvim ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # ============ OPCIONES (kickstart-like) ============
    opts = {
      number = true;
      relativenumber = true;
      mouse = "a";
      clipboard = "unnamedplus";
      breakindent = true;
      undofile = true;
      ignorecase = true;
      smartcase = true;
      signcolumn = "yes";
      updatetime = 250;
      timeoutlen = 300;
      splitright = true;
      splitbelow = true;
      list = true;
      listchars = { tab = "» "; trail = "·"; nbsp = "␣"; };
      inccommand = "split";
      cursorline = true;
      scrolloff = 8;
      termguicolors = true;
      tabstop = 4;
      shiftwidth = 4;
      expandtab = true;
      smartindent = true;
      wrap = false;
    };

    # ============ TEMA (Tokyo Night) ============
    colorschemes.tokyonight = {
      enable = true;
      settings.style = "night";
    };

    # ============ KEYMAPS (leader = espacio) ============
    globals.mapleader = " ";
    globals.maplocalleader = " ";

    keymaps = [
      # Telescope
      { mode = "n"; key = "<leader>ff"; action = "<cmd>Telescope find_files<CR>"; options.desc = "Buscar archivos"; }
      { mode = "n"; key = "<leader>fg"; action = "<cmd>Telescope live_grep<CR>"; options.desc = "Buscar texto"; }
      { mode = "n"; key = "<leader>fb"; action = "<cmd>Telescope buffers<CR>"; options.desc = "Buffers"; }
      { mode = "n"; key = "<leader>fh"; action = "<cmd>Telescope help_tags<CR>"; options.desc = "Ayuda"; }
      { mode = "n"; key = "<leader>fr"; action = "<cmd>Telescope oldfiles<CR>"; options.desc = "Recientes"; }
      { mode = "n"; key = "<leader>fs"; action = "<cmd>Telescope lsp_document_symbols<CR>"; options.desc = "Símbolos"; }
      { mode = "n"; key = "<leader>gc"; action = "<cmd>Telescope git_commits<CR>"; options.desc = "Commits"; }
      # Neo-tree
      { mode = "n"; key = "<leader>e"; action = "<cmd>Neotree toggle<CR>"; options.desc = "Explorador"; }
      # Ventanas
      { mode = "n"; key = "<C-h>"; action = "<C-w>h"; options.desc = "Izquierda"; }
      { mode = "n"; key = "<C-j>"; action = "<C-w>j"; options.desc = "Abajo"; }
      { mode = "n"; key = "<C-k>"; action = "<C-w>k"; options.desc = "Arriba"; }
      { mode = "n"; key = "<C-l>"; action = "<C-w>l"; options.desc = "Derecha"; }
      # LSP
      { mode = "n"; key = "gd"; action = "<cmd>Telescope lsp_definitions<CR>"; options.desc = "Definición"; }
      { mode = "n"; key = "gr"; action = "<cmd>Telescope lsp_references<CR>"; options.desc = "Referencias"; }
      { mode = "n"; key = "K"; action = "<cmd>lua vim.lsp.buf.hover()<CR>"; options.desc = "Documentación"; }
      { mode = "n"; key = "<leader>rn"; action = "<cmd>lua vim.lsp.buf.rename()<CR>"; options.desc = "Renombrar"; }
      { mode = "n"; key = "<leader>ca"; action = "<cmd>lua vim.lsp.buf.code_action()<CR>"; options.desc = "Code action"; }
      { mode = "n"; key = "<leader>f"; action = "<cmd>lua vim.lsp.buf.format({ async = true })<CR>"; options.desc = "Formatear"; }
      { mode = "n"; key = "[d"; action = "<cmd>lua vim.diagnostic.goto_prev()<CR>"; options.desc = "Diag anterior"; }
      { mode = "n"; key = "]d"; action = "<cmd>lua vim.diagnostic.goto_next()<CR>"; options.desc = "Diag siguiente"; }
      # DAP (debugging)
      { mode = "n"; key = "<F5>"; action = "<cmd>lua require('dap').continue()<CR>"; options.desc = "Debug continuar"; }
      { mode = "n"; key = "<F10>"; action = "<cmd>lua require('dap').step_over()<CR>"; options.desc = "Paso a paso"; }
      { mode = "n"; key = "<F11>"; action = "<cmd>lua require('dap').step_into()<CR>"; options.desc = "Entrar"; }
      { mode = "n"; key = "<F12>"; action = "<cmd>lua require('dap').step_out()<CR>"; options.desc = "Salir"; }
      { mode = "n"; key = "<leader>b"; action = "<cmd>lua require('dap').toggle_breakpoint()<CR>"; options.desc = "Breakpoint"; }
      { mode = "n"; key = "<leader>B"; action = "<cmd>lua require('dap').set_breakpoint(vim.fn.input('Condición: '))<CR>"; options.desc = "Breakpoint condicional"; }
      { mode = "n"; key = "<leader>du"; action = "<cmd>lua require('dapui').toggle()<CR>"; options.desc = "Toggle DAP UI"; }
      { mode = "n"; key = "<leader>dr"; action = "<cmd>lua require('dap').repl.toggle()<CR>"; options.desc = "DAP REPL"; }
      { mode = "n"; key = "<leader>db"; action = "<cmd>Telescope dap list_breakpoints<CR>"; options.desc = "Lista breakpoints"; }
      # Quitar resaltado
      { mode = "n"; key = "<Esc>"; action = "<cmd>nohlsearch<CR>"; }
    ];

    # ============ PLUGINS (estilo kickstart) ============
    plugins = {
      # --- Navegación / búsqueda ---
      telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
      };
      neo-tree = {
        enable = true;
        settings = {
          close_if_last_window = true;
          window.width = 34;
          filesystem = {
            follow_current_file = true;
            use_libuv_file_watcher = true;
            filtered_items = { visible = true; hide_dotfiles = false; hide_gitignored = false; };
          };
        };
      };

      # --- Sintaxis ---
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
          auto_install = true;
          ensure_installed = [
            "lua" "vim" "vimdoc" "query"
            "rust" "c" "cpp" "python" "nix"
            "swift" "dart" "json" "yaml" "toml"
            "bash" "markdown" "markdown_inline" "html" "css" "javascript" "typescript"
          ];
        };
      };

      # --- LSP ---
      lsp = {
        enable = true;
        servers = {
          rust_analyzer.enable = true;
          nil_ls.enable = true;         # Nix
          pyright.enable = true;
          ts_ls.enable = true;
          lua_ls.enable = true;
          clangd.enable = true;
          bashls.enable = true;
          yamlls.enable = true;
          jsonls.enable = true;
          # Swift: sourcekit LSP no disponible en aarch64 (swift roto en nixpkgs).
          # Se configura aparte si instalas el toolchain oficial de swift.org.
          # Flutter / Dart
          dartls = {
            enable = true;
            package = pkgs.dart;
          };
        };
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

      # --- Autocompletado ---
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          sources = [
            { name = "nvim_lsp"; }
            { name = "buffer"; }
            { name = "path"; }
            { name = "luasnip"; }
          ];
          mapping = {
            "<C-Space>" = "cmp.mapping.complete()";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Tab>" = "cmp.mapping.select_next_item()";
            "<S-Tab>" = "cmp.mapping.select_prev_item()";
          };
        };
      };
      luasnip.enable = true;

      # --- Debugging (DAP UI + breakpoints) ---
      dap.enable = true;
      dap-ui.enable = true;
      dap-virtual-text.enable = true;

      # --- Git ---
      gitsigns.enable = true;

      # --- Calidad de vida ---
      which-key.enable = true;
      comment.enable = true;
      nvim-autopairs.enable = true;
      nvim-surround.enable = true;
      leap.enable = true;
      todo-comments.enable = true;
      lualine.enable = true;
      web-devicons.enable = true;
    };

    # ============ DAP: adapters y configuraciones (Rust/Swift/C/C++) ============
    extraConfigLua = ''
      local dap = require("dap")
      local dapui = require("dapui")

      -- UI se abre/cierra con la sesión
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      -- lldb-dap (viene con pkgs.lldb): Rust, C/C++ y Swift
      dap.adapters.lldb = {
        type = "executable",
        command = "${pkgs.lldb}/bin/lldb-dap",
        name = "lldb",
      }

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
      dap.configurations.c = dap.configurations.rust
      dap.configurations.cpp = dap.configurations.rust

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

    # ============ Paquetes externos (LSP/DAP/formaters) ============
    extraPackages = with pkgs; [
      lldb              # incluye lldb-dap (debugger para Rust/Swift/C/C++)
      nixpkgs-fmt
      stylua
      prettier
      ripgrep
      fd
    ];
  };
}
