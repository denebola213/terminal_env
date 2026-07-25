-- =====================================================================
-- diffview.nvim カスタマイズ
-- =====================================================================
-- レビュー用 diff / 履歴ビュー。worktree 間 diff もサポート。
-- =====================================================================
return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
  opts = {
    enhanced_diff_hl = false,
    toggle_between_diff_and_exit = true,
    default_args = {
      DiffviewOpen = {
        "--cmd", "set diffopt+=linematch:60",
        "--tab"  -- 別タブで開く
      },
      DiffviewFileHistory = {
        "--tab",
      },
    },
    file_history_panel = {
      log_options = {
        max_count = 50,
        follow = false,
        all = false,
      },
    },
    view = {
      -- 1 ファイルごとに垂直分割
      split = "vertical",
      layout = "diff2_3",
    },
  },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>",       desc = "Diffview: open" },
    { "<leader>gv", "<cmd>DiffviewClose<cr>",      desc = "Diffview: close" },
    { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview: file history" },
    { "<leader>gw", function()
        -- 現在の worktree と main の diff を開く
        local main = vim.fn.system "git rev-parse --verify main 2>/dev/null || git rev-parse --verify master 2>/dev/null"
        if main and #main > 0 then
          vim.cmd(string.format("DiffviewOpen %s...HEAD", main:gsub("%s+$", "")))
        else
          vim.notify("No main/master branch found", vim.log.levels.WARN)
        end
      end, desc = "Diffview: vs main" },
  },
}
