-- =====================================================================
-- LazyVim エントリポイント
-- =====================================================================
-- 配置: ~/.config/nvim/init.lua
--
-- LazyVim 公式のインストール手順:
--   1. lazy.nvim (folke) を手動 bootstrap
--   2. LazyVim 本体も手動 bootstrap  (大文字ディレクトリ名 "LazyVim" 必須)
--   3. lazy.nvim が spec を解釈して残りのプラグインを自動 clone
--
-- 注意: LazyVim のディレクトリ名は必ず大文字 "LazyVim"。
--       小文字で clone すると lazy.nvim の spec と一致せず rtp に
--       空のパスが追加されて module not found エラーになる。
-- =====================================================================

-- Netrw を完全に無効化 (LazyVim は snacks / neo-tree を使うので不要)
-- これを入れておかないと、Netrw 由来の "FileExplorer" augroup 解決エラーが出る
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Netrw 由来の "FileExplorer" augroup を事前定義しておく。
-- 古い Netrw 仕様の autocmd を発行するプラグイン (LazyVim 周辺) が
-- `augroup FileExplorer | autocmd ... | augroup END` を実行するため、
-- augroup が無い状態で E216 が出る問題を回避する。
vim.api.nvim_create_augroup("FileExplorer", { clear = true })

local lazy_root = vim.fn.stdpath("data") .. "/lazy"

-- bootstrap lazy.nvim (folke 本体) — require("lazy") を解決するために必要
local lazy_path = lazy_root .. "/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazy_path) then
  local out = vim.fn.system({
    "git", "clone",
    "--filter=blob:none",
    "--url=https://github.com/folke/lazy.nvim.git",
    lazy_path,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_err_writeln(
      "Failed to clone lazy.nvim into " .. lazy_path .. ":\n" .. out
      .. "\nFix: git clone https://github.com/folke/lazy.nvim.git " .. lazy_path
    )
    error("Aborting nvim startup: lazy.nvim bootstrap failed")
  end
end

-- bootstrap LazyVim (大文字ディレクトリ名。lazy.nvim の spec と一致させる)
local lazyvim_path = lazy_root .. "/LazyVim"
if not (vim.uv or vim.loop).fs_stat(lazyvim_path) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/LazyVim/lazyvim.git",
    lazyvim_path,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_err_writeln(
      "Failed to clone LazyVim into " .. lazyvim_path .. ":\n" .. out
      .. "\nFix: git clone --branch=stable https://github.com/LazyVim/lazyvim.git " .. lazyvim_path
    )
    error("Aborting nvim startup: LazyVim bootstrap failed")
  end
end

vim.opt.rtp:prepend(lazy_path)
vim.opt.rtp:prepend(lazyvim_path)

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
-- extras は lazyvim.json で集中管理 (LazyVim v16.0 推奨)
-- init.lua では LazyVim 全体 + 追加プラグインのみ spec
require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
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
