-- =====================================================================
-- render-markdown.nvim カスタマイズ
-- =====================================================================
-- Markdown の見出し・リスト・コードブロックを装飾表示。
-- snacks.image と組み合わせて Mermaid 図も描画。
-- =====================================================================
return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    file_types = { "markdown", "norg", "org", "rmd", "quarto" },
    render_modes = { "buf", "edit", "on_demand" },
    code = {
      enabled = true,
      sign = false,
      style = "minimal",
    },
    heading = {
      enabled = true,
      sign = false,
      -- Mermaid コードブロックは snacks に任せてスキップ
      render_modes = { "buf", "edit", "on_demand" },
    },
    link = {
      enabled = true,
      custom = {
        ["^%[.-%]%(.-%)"] = "link",
      },
    },
    latex = { enabled = true },
    html = { enabled = false },
  },
  ft = { "markdown", "norg", "rmd", "quarto" },
  config = function(_, opts)
    require("render-markdown").setup(opts)
    -- Mermaid ブロックは snacks に任せる
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "markdown", "rmd", "quarto" },
      callback = function()
        -- snacks が image モジュールで Mermaid を処理
        local ok, snacks = pcall(require, "snacks.image")
        if ok then
          snacks.activate("markdown", { pattern = "^###%%mermaid" })
        end
      end,
    })
  end,
}
