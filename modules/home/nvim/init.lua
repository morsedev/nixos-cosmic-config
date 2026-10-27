-- ============================================================================
-- Neovim IDE (estilo kickstart.nvim) — Mac M2 · Tokyo Night
-- Bases: nvim-lua/kickstart.nvim + añadidos: DAP UI, Nix LSP, Swift, Flutter
-- Los LSP servers se instalan con NixOS (ver modules/development.nix),
-- así que no hace falta Mason.
-- ============================================================================

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ============ OPCIONES ============
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.showmode = false
vim.opt.clipboard = "unnamedplus"
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "split"
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.termguicolors = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false

-- Fold
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

-- ============ BOOTSTRAP LAZY.NVIM ============
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Fallo clonando lazy.nvim: " .. out, "ErrorMsg" } }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

-- ============ PLUGINS ============
require("lazy").setup({
  -- ============ TEMAS ============
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = { style = "night" },
  },

  -- ============ EDICIÓN ============
  "numToStr/Comment.nvim",                -- comentar con gc
  "windwp/nvim-autopairs",                -- pares automáticos
  "kylechui/nvim-surround",               -- rodear con ys
  "folke/which-key.nvim",                 -- ayuda de atajos
  "folke/todo-comments.nvim",             -- resaltar TODO/FIXME
  "echasnovski/mini.align",               -- alinear
  "ggandor/leap.nvim",                    -- moverte volando (s + 2 letras)
  "tpope/vim-sleuth",                     -- detectar indent del proyecto

  -- ============ TREE-SITTER (sintaxis) ============
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "vim", "vimdoc", "query",
          "rust", "c", "cpp", "python", "nix",
          "swift", "dart", "json", "yaml", "toml",
          "bash", "markdown", "markdown_inline", "html", "css", "javascript", "typescript",
        },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = false,
            node_decremental = "<bs>",
          },
        },
        textobjects = { -- select words/functions con 'af' 'if' etc.
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
            },
          },
        },
      })
    end,
  },

  -- ============ ARCHIVOS / BÚSQUEDA ============
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          sorting_strategy = "ascending",
          layout_config = { prompt_position = "top" },
        },
        pickers = {
          find_files = { hidden = true, file_ignore_patterns = { "node_modules", ".git", "build", "target" } },
        },
      })
      telescope.load_extension("fzf")
      -- Atajos
      local map = vim.keymap.set
      map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Buscar archivos" })
      map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "Buscar texto" })
      map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Buffers abiertos" })
      map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Ayuda" })
      map("n", "<leader>fp", "<cmd>Telescope projects<CR>", { desc = "Proyectos" })
      map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", { desc = "Recientes" })
      map("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "Símbolos del archivo" })
      map("n", "<leader>gc", "<cmd>Telescope git_commits<CR>", { desc = "Commits git" })
    end,
  },
  "nvim-telescope/telescope-fzf-native.nvim",
  {
    "nvim-neo-tree/neo-tree.nvim",       -- árbol de archivos lateral
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        filesystem = {
          follow_current_file = true,
          use_libuv_file_watcher = true,
          filtered_items = { visible = true, hide_dotfiles = false, hide_gitignored = false },
        },
        window = { width = 34 },
      })
      vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "Explorador de archivos" })
      vim.keymap.set("n", "<leader>E", "<cmd>Neotree reveal<CR>", { desc = "Revelar archivo" })
    end,
  },

  -- ============ LSP (IDE) ============
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Helper: capacidades con fallback a snippet (nvim-cmp)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.textDocument.completion.completionItem = {
        documentationFormat = { "markdown", "plaintext" },
        snippetSupport = true,
        insertReplaceSupport = true,
      }

      -- Diagnósticos flotantes
      vim.diagnostic.config({
        virtual_text = { prefix = "●" },
        float = { source = true },
        signs = true,
        update_in_insert = false,
      })

      -- Keymaps LSP (cuando un servidor se conecta)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
        callback = function(event)
          local map = function(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
          end
          map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
          map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
          map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
          map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
          map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
          map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
          map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
          map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
          map("K", vim.lsp.buf.hover, "Hover documentation")
          map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
          -- Diagnósticos
          map("[d", vim.diagnostic.goto_prev, "Previous diagnostic")
          map("]d", vim.diagnostic.goto_next, "Next diagnostic")
          map("<leader>d", vim.diagnostic.open_float, "Diagnóstico flotante")
          map("<leader>q", vim.diagnostic.setloclist, "Diagnósticos en lista")

          -- Formatear con <leader>f
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.supports_method("textDocument/formatting") then
            map("<leader>f", function()
              vim.lsp.buf.format({ async = true })
            end, "[F]ormatear")
          end
        end,
      })

      -- LSP Servers: los binarios los instala NixOS (sin Mason).
      -- Rust, Swift, Flutter/Dart, Nix, Python, TypeScript, Lua, C/C++...
      local servers = {
        rust_analyzer = {},
        sourcekit_lsp = {},          -- Swift
        dartls = {},                 -- Flutter/Dart (usará el Dart SDK de Flutter)
        nil_ls = {},                 -- Nix
        pyright = {},
        ts_ls = {},
        lua_ls = {},
        clangd = {},
        bashls = {},
        yamlls = {},
        jsonls = {},
      }

      local lspconfig = require("lspconfig")
      for server, opts in pairs(servers) do
        opts.capabilities = capabilities
        -- Algunos servidores requieren config extra
        if server == "dartls" then
          -- El dart de Flutter viene en pkgs.flutter; lspconfig necesita el SDK
          opts.settings = { dart = { analysisServerFolding = true } }
        end
        if server == "sourcekit_lsp" then
          opts.cmd = { "sourcekit-lsp" }
        end
        lspconfig[server].setup(opts)
      end
    end,
  },

  -- ============ COMPLETION (nvim-cmp) ============
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
      })

      -- Cmdline completion
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
      })
    end,
  },

  -- ============ DEBUGGING (DAP + DAP UI) ============
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-telescope/telescope-dap.nvim",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- UI
      require("dapui").setup({
        layouts = {
          { elements = { "scopes", "breakpoints", "stacks", "watches" }, size = 40, position = "left" },
          { elements = { "repl", "console" }, size = 12, position = "bottom" },
        },
      })
      require("nvim-dap-virtual-text").setup({ enabled = true, virt_text_pos = "eol" })

      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      -- Atajos de depuración
      vim.keymap.set("n", "<F5>", function()
        if dap.session() then dap.continue() else dap.continue() end
      end, { desc = "Debug: continuar" })
      vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: paso por encima" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: entrar" })
      vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: salir" })
      vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: toggle breakpoint" })
      vim.keymap.set("n", "<leader>B", function() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, { desc = "Debug: breakpoint condicional" })
      vim.keymap.set("n", "<leader>db", "<cmd>Telescope dap list_breakpoints<CR>", { desc = "Debug: lista breakpoints" })
      vim.keymap.set("n", "<leader>dc", "<cmd>Telescope dap commands<CR>", { desc = "Debug: comandos" })
      vim.keymap.set("n", "<leader>di", "<cmd>DapInstall<CR>", { desc = "Debug: instalar adapters" })
      vim.keymap.set("n", "<leader>du", function() dapui.toggle() end, { desc = "Debug: toggle UI" })
      vim.keymap.set("n", "<leader>dR", function() dap.run_to_cursor() end, { desc = "Debug: correr al cursor" })
      vim.keymap.set("n", "<leader>dr", function() dap.repl.toggle() end, { desc = "Debug: repl" })

      -- Adapters: codelldb para Rust/C/C++ (viene con NixOS), lldb para Swift
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = "codelldb",
          args = { "--port", "${port}" },
        },
      }
      -- Rust
      dap.configurations.rust = {
        {
          name = "Launch",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path a binario (target/debug/<nombre>): ", vim.fn.getcwd() .. "/target/debug/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }
      -- Swift (usar lldb con el ejecutable compilado)
      dap.configurations.swift = {
        {
          name = "Launch",
          type = "lldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path a binario: ", vim.fn.getcwd() .. "/.build/debug/", "file")
          end,
          cwd = "${workspaceFolder}",
        },
      }
      -- C/C++ reutilizan la config de Rust (codelldb)
      dap.configurations.c = dap.configurations.rust
      dap.configurations.cpp = dap.configurations.rust
    end,
  },

  -- ============ GIT ============
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "┃" }, change = { text = "┃" }, delete = { text = "▁" },
          topdelete = { text = "‾" }, changedelete = { text = "~" },
        },
        on_attach = function(bufnr)
          vim.keymap.set("n", "<leader>gp", require("gitsigns").preview_hunk, { buffer = bufnr, desc = "Preview hunk" })
          vim.keymap.set("n", "<leader>gr", require("gitsigns").reset_hunk, { buffer = bufnr, desc = "Reset hunk" })
        end,
      })
    end,
  },

  -- ============ FORMATO / LINT NIX ============
  {
    "nvimtools/none-ls.nvim",
    config = function()
      local null_ls = require("null-ls")
      null_ls.setup({
        sources = {
          null_ls.builtins.formatting.nixpkgs_fmt,
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.formatting.prettier,
          null_ls.builtins.formatting.rustfmt,
        },
      })
      vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format, { desc = "Formatear (LSP/null-ls)" })
    end,
  },

  -- ============ BARRA DE ESTADO ============
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require("lualine").setup({
        options = {
          theme = "tokyonight",
          globalstatus = true,
          section_separators = { left = "", right = "" },
          component_separators = { left = "", right = "" },
        },
      })
    end,
  },
}, {
  checker = { enabled = true, notify = false },
  change_detection = { notify = false },
  performance = {
    cache = { enabled = true },
    rtp = { disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" } },
  },
})

-- ============ TEMA ============
vim.cmd.colorscheme("tokyonight-night")

-- ============ KEYMAPS GENERALES ============
local map = vim.keymap.set
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Quitar resaltado" })
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll medio" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll medio" })
map("n", "n", "nzzzv", { desc = "Centrar en búsqueda" })
map("n", "N", "Nzzzv", { desc = "Centrar en búsqueda" })
map("x", "<leader>p", '"_dP', { desc = "Pegar sin perder clipboard" })
map("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Reemplazar palabra" })

-- Ventanas
map("n", "<C-h>", "<C-w>h", { desc = "Ir a la izquierda" })
map("n", "<C-j>", "<C-w>j", { desc = "Ir abajo" })
map("n", "<C-k>", "<C-w>k", { desc = "Ir arriba" })
map("n", "<C-l>", "<C-w>l", { desc = "Ir a la derecha" })
map("n", "<leader>sv", "<C-w>v", { desc = "Split vertical" })
map("n", "<leader>sh", "<C-w>s", { desc = "Split horizontal" })

-- ============ AUTOCOMANDOS ============
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 }) end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark.line > 1 and mark.line <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, { mark.line, mark.column })
    end
  end,
})
