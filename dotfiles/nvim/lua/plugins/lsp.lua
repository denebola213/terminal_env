-- =====================================================================
-- LSP カスタマイズ (LazyVim のデフォルトをオーバーライド)
-- =====================================================================
-- 言語ごとの追加設定・キーマップを定義。
-- =====================================================================
return {
  -- LazyVim が標準で持つ mason / lspconfig の設定を上書き
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = true,
          header = "",
          prefix = "",
        },
      },
      inlay_hints = {
        enabled = true,
        exclude = { "vue", "json", "yaml" },
      },
    },
  },

  -- vtsls (TypeScript / JavaScript)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = {
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "literal",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = false,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
          },
        },
      },
    },
  },

  -- clangd (C / C++)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          settings = {
            clangd = {
              -- プロジェクトの compile_commands.json を自動検索
              compileCommandsDir = vim.fn.getcwd(),
              fallbackFlags = { "-std=c++20", "-Wall", "-Wextra" },
              inlayHints = {
                Enabled = true,
                ParameterNames = true,
                DeducedTypes = true,
                stdLike = true,
                ReferenceLimit = 0,
              },
            },
          },
        },
      },
    },
  },
}
