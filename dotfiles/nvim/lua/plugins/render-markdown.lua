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
      -- custom の各要素は { icon = "...", pattern = "...", kind = "..." }
      -- デフォルトの GitHub/Google/Neovim 等のパターンを使用
    },
    latex = { enabled = true },
    html = { enabled = false },
  },
  ft = { "markdown", "norg", "rmd", "quarto" },
  -- Mermaid ブロックは snacks.image が自動検知して画像化する (設定は snacks.lua 参照)
  -- render-markdown 側では code.style = "minimal" により装飾を最小限にして
  -- snacks.image の描画を邪魔しない。
}
