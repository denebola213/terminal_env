-- =====================================================================
-- snacks.nvim カスタマイズ
-- =====================================================================
-- 役割:
--   - image モジュールで Markdown / Mermaid をターミナル内にインライン描画
--   - dashboard でスタート画面
--   - picker でファジー検索 (files, buffers, grep)
-- =====================================================================

local function wezterm_available()
  return vim.env.TERM_PROGRAM == "WezTerm" or os.getenv("WEZTERM_PANE") ~= nil
end

return {
  "folke/snacks.nvim",
  opts = function()
    local is_wezterm = wezterm_available()
    return {
      image = {
        -- WezTerm + kitty graphics protocol での描画
        backend = is_wezterm and "wezterm" or "kitty",
        -- Mermaid を mmdc で画像化 → インライン表示
        mermaid = {
          args = { "--quiet" },
          config = {
            theme = "dark",
            themeVariables = { background = "#1e1e2e" },
          },
        },
        max_width = 120,
        max_height = 40,
        inline = true,
        -- 対応ターミナル検出 (WezTerm, kitty, Ghostty で動作)
        supported = {
          "wezterm", "kitty", "ghostty",
        },
      },
      dashboard = {
        preset = {
          header = [[
          ╔══════════════════════════════════════════╗
          ║     Terminal-Driven Development Env      ║
          ╚══════════════════════════════════════════╝
          ]],
        },
        keys = {
          { key = "f", desc = "Find File",      action = ":lua Snacks.picker.files()" },
          { key = "g", desc = "Find Word",      action = ":lua Snacks.picker.grep()" },
          { key = "r", desc = "Recent Files",   action = ":lua Snacks.picker.recent()" },
          { key = "l", desc = "Lazy",           action = ":Lazy" },
          { key = "c", desc = "Config",         action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })" },
          { key = "q", desc = "Quit",           action = ":qa" },
        },
      },
      picker = {
        win = { input = { title = " Search " } },
        sources = {
          files = { hidden = true },
        },
      },
      terminal = {
        win = { position = "bottom", height = 0.4 },
      },
      indent = { enabled = true },
      scroll = { enabled = false },  -- LazyVim 標準の neo-tree 操作と干渉するため無効
    }
  end,
}
