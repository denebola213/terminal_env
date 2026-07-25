-- =====================================================================
-- 一般カスタマイズ (autocmd, キーマップなど)
-- =====================================================================
return {
  {
    "LazyVim/LazyVim",
    keys = {
      {
        "<leader>gg",
        function()
          -- WezTerm 内なら現在の pane domain で lazygit を起動
          if vim.env.TERM_PROGRAM == "WezTerm" then
            vim.fn.jobstart({ "lazygit" }, { detach = 1 })
          else
            vim.cmd("LazyGit")
          end
        end,
        desc = "Lazygit",
      },
      {
        "<leader>fm",
        function()
          -- Markdown / Mermaid のプレビューを snacks で更新
          local ok, snacks = pcall(require, "snacks.image")
          if ok then
            snacks.activate "markdown"
          end
        end,
        desc = "Render Markdown / Mermaid",
      },
    },
  },

  -- 任意: file rename を便利にする
  {
    "echasnovski/mini.files",
    opts = {
      mappings = {
        go_in       = "l",
        go_out      = "h",
        go_in_plus  = "L",
        go_out_plus = "H",
      },
    },
  },
}
