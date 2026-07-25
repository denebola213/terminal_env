-- =====================================================================
-- LazyVim エントリポイント
-- =====================================================================
-- 配置: ~/.config/nvim/init.lua
-- 環境変数 LAZYVIM_PATH を変えることで別ブランチの LazyVim を利用可能。
-- =====================================================================

local lazypath = vim.env.LAZYVIM_PATH or vim.fn.stdpath "data" .. "/lazy/lazyvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system {
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/LazyVim/lazyvim.git",
    lazypath,
  }
end

vim.opt.rtp:prepend(lazypath)

-- カスタム設定ディレクトリを優先 (chezmoi で管理)
vim.opt.rtp:prepend(vim.fn.stdpath "config" .. "/lua")

-- 基本オプション
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400
vim.opt.splitright = true
vim.opt.splitbelow = true

-- 互換性
if vim.fn.has "nvim-0.10" == 1 then
  vim.cmd("set packpath^=" .. vim.fn.stdpath "config" .. "/site")
end

-- LazyVim 読み込み
require("lazy").setup({
  spec = {
    -- 言語 / 機能を LazyVim extras で有効化
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "lazyvim.plugins.extras.lang.typescript" },   -- vtsls
    { import = "lazyvim.plugins.extras.lang.clangd" },       -- C / C++
    { import = "lazyvim.plugins.extras.lsp.none-ls" },      -- フォーマッタ
    -- C# は roslyn.nvim を自前で追加
    {
      "seblyng/roslyn.nvim",
      ft = { "cs", "csproj" },
      opts = {
        server = {
          install_path = vim.fn.stdpath "data" .. "/lspinstall/roslyn",
        },
      },
    },
    -- このディレクトリ配下のカスタマイズを自動取り込み
    { import = "plugins" },
  },
  defaults = { lazy = false },
  install = { missing = false },
  ui = { border = "rounded" },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})
