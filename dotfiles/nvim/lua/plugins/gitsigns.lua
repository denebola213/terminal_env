-- =====================================================================
-- gitsigns.nvim カスタマイズ
-- =====================================================================
-- 行単位 diff・hunk 操作をエディタ内で完結させる。
-- <leader>gh で hunk preview, <leader>gs で stage などが利用可能。
-- =====================================================================
return {
  "lewis6991/gitsigns.nvim",
  opts = {
    signs = {
      add          = { text = "▎" },
      change       = { text = "▎" },
      delete       = { text = "" },
      topdelete    = { text = "" },
      changedelete = { text = "▎" },
      untracked    = { text = "▎" },
    },
    signs_staged = {
      add          = { text = "▎" },
      change       = { text = "▎" },
      delete       = { text = "" },
      topdelete    = { text = "" },
      changedelete = { text = "▎" },
    },
    signcolumn = true,
    numhl       = false,
    linehl     = false,
    word_diff  = false,
    watch_gitdir = {
      follow_files = true,
    },
    attach_to_untracked = false,
    current_line_blame = false,
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol",
      delay = 500,
      ignore_whitespace = false,
    },
    update_debounce = 100,
    preview_config = {
      border = "rounded",
      style = "minimal",
      relative = "cursor",
      row = 0,
      col = 1,
    },
  },
}
