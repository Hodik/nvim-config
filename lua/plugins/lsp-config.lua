return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "stevearc/conform.nvim",
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "hrsh7th/nvim-cmp",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "j-hui/fidget.nvim",
  },

  config = function()
    require("conform").setup({
      formatters_by_ft = {},
    })
    local cmp = require("cmp")
    local cmp_lsp = require("cmp_nvim_lsp")
    local capabilities = vim.tbl_deep_extend(
      "force",
      {},
      vim.lsp.protocol.make_client_capabilities(),
      cmp_lsp.default_capabilities()
    )

    require("fidget").setup({})
    require("mason").setup()
    require("mason-lspconfig").setup({
      ensure_installed = {
        "lua_ls",
        "rust_analyzer",
        "gopls",
        "jedi_language_server",
      },
      auto_install = true,
      handlers = {
        function(server_name) -- default handler (optional)
          if server_name ~= "pyright" then
            require("lspconfig")[server_name].setup({
              capabilities = capabilities,
            })
          end
        end,

        zls = function()
          local lspconfig = require("lspconfig")
          lspconfig.zls.setup({
            root_dir = lspconfig.util.root_pattern(".git", "build.zig", "zls.json"),
            settings = {
              zls = {
                enable_inlay_hints = true,
                enable_snippets = true,
                warn_style = true,
              },
            },
          })
          vim.g.zig_fmt_parse_errors = 0
          vim.g.zig_fmt_autosave = 0
        end,
        ["lua_ls"] = function()
          local lspconfig = require("lspconfig")
          lspconfig.lua_ls.setup({
            capabilities = capabilities,
            settings = {
              Lua = {
                runtime = { version = "Lua 5.1" },
                diagnostics = {
                  globals = { "bit", "vim", "it", "describe", "before_each", "after_each" },
                },
              },
            },
          })
        end,
        ["jedi_language_server"] = function()
          local lspconfig = require("lspconfig")
          local function get_python_path(workspace)
            -- Use the workspace's virtual environment if it exists
            local venv = workspace .. "/env/bin/python"
            if vim.fn.executable(venv) == 1 then
              return venv
            end
            -- Fallback to system Python
            return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
          end

          lspconfig.jedi_language_server.setup({
            capabilities = capabilities,
            on_new_config = function(config, root)
              config.settings = {
                workspace = {
                  environmentPath = get_python_path(root),
                  symbols = {
                    ignoreFolders = {
                      ".nox",
                      ".tox",
                      ".env",
                      ".venv",
                      "__pycache__",
                      "venv",
                      "env",
                    },
                  },
                },
              }
            end,
          })
        end,
      },
    })

    local cmp_select = { behavior = cmp.SelectBehavior.Select }

    cmp.setup({
      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
        ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
        ["<C-y>"] = cmp.mapping.confirm({ select = true }),
        ["<C-Space>"] = cmp.mapping.complete(),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" }, -- For luasnip users.
      }, {
        { name = "buffer" },
      }),
    })

    vim.diagnostic.config({
      -- update_in_insert = true,
      float = {
        focusable = false,
        style = "minimal",
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
      },
    })
    vim.keymap.set("n", "gd", vim.lsp.buf.definition)         -- Go to definition
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration)        -- Go to declaration
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation)     -- Go to implementation
    vim.keymap.set("n", "gr", vim.lsp.buf.references)         -- Show references
    vim.keymap.set("n", "K", vim.lsp.buf.hover)               -- Hover documentation
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)     -- Rename symbol
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action) -- Code actions
    vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float) -- Show diagnostics
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)       -- Go to previous diagnostic
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next)       -- Go to next diagnostic
  end,
}
