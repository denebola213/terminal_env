-- =====================================================================
-- WezTerm 設定 (Windows / WSL Arch / PowerShell / devcontainer 共通)
-- =====================================================================
-- ファイル配置:
--   Windows: %USERPROFILE%\.config\wezterm\wezterm.lua
--   Linux  : ~/.config/wezterm/wezterm.lua
--   chezmoi 管理時は dot_wezterm/wezterm.lua として配置
-- =====================================================================

local wezterm = require "wezterm"
local act = wezterm.action
local mux = wezterm.mux

local config = {}

-- ---------------------------------------------------------------------
-- 基本
-- ---------------------------------------------------------------------
config.color_scheme = "Catppuccin Mocha"
config.font_size = 13.0
config.window_padding = { left = 6, right = 6, top = 6, bottom = 6 }
config.hide_tab_bar_if_only_one_tab = false

-- kitty graphics protocol (Mermaid のインライン描画に必須)
config.enable_kitty_graphics = true

-- デフォルトで kitty keyboard protocol を有効化
config.enable_kitty_keyboard = true

-- ---------------------------------------------------------------------
-- キーバインド (マルチプレクサ内蔵)
-- ---------------------------------------------------------------------
local leader = { key = "a", mods = "CTRL|SHIFT" }

config.leader = leader
config.keys = {
  -- pane 操作
  { key = "|", mods = leader, action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
  { key = "-", mods = leader, action = act.SplitVertical   { domain = "CurrentPaneDomain" } },
  { key = "h", mods = leader, action = act.ActivatePaneDirection "Left" },
  { key = "l", mods = leader, action = act.ActivatePaneDirection "Right" },
  { key = "k", mods = leader, action = act.ActivatePaneDirection "Up" },
  { key = "j", mods = leader, action = act.ActivatePaneDirection "Down" },
  { key = "z", mods = leader, action = act.TogglePaneZoomState },
  { key = "x", mods = leader, action = act.CloseCurrentPane { confirm = false } },

  -- tab 操作
  { key = "c", mods = leader, action = act.SpawnTab "CurrentPaneDomain" },
  { key = "n", mods = leader, action = act.ActivateTabRelative(1) },
  { key = "p", mods = leader, action = act.ActivateTabRelative(-1) },
  { key = "w", mods = leader, action = act.ShowLauncherArgs { flags = "WORKSPACE,TABS" } },

  -- workspace (worktree を 1 workspace に割り当て)
  { key = "1", mods = leader, action = act.SwitchToWorkspace { name = "main" } },
  { key = "2", mods = leader, action = act.SwitchToWorkspace { name = "feat-a" } },
  { key = "3", mods = leader, action = act.SwitchToWorkspace { name = "feat-b" } },

  -- 共通ツール
  { key = "g", mods = leader, action = act.SpawnCommandInNewTab {
      args = { "lazygit" }, domain = "CurrentPaneDomain",
  } },
  { key = "e", mods = leader, action = act.SpawnCommandInNewTab {
      args = { "nvim", "." }, domain = "CurrentPaneDomain",
  } },
}

-- ---------------------------------------------------------------------
-- Domain: 1 ウィンドウ内で複数環境を同居
-- ---------------------------------------------------------------------
-- 環境変数で自動判定。HOSTNAME が WSL なら WSL ドメイン、PowerShell 内なら PS、
-- ローカル Linux なら Default として動作する。
--
-- domain はランチャー (Ctrl+Shift+w) から切り替えることも可能。
-- ---------------------------------------------------------------------
config.default_domain = "DefaultUnixDomain"

if wezterm.add_to_config_search_path then
  wezterm.add_to_config_search_path(
    wezterm.home_dir .. "/.config/wezterm/domains"
  )
end

-- SSH 接続先 (devcontainer) のヒント
-- ~/.ssh/config に host devcontainer を定義しておく想定
config.ssh_domains = {
  {
    name = "devcontainer",
    remote_address = "devcontainer",
  },
}

-- WSL2 の distro 名。デフォルトは Arch。環境によって変更する。
local WSL_DISTRO = os.getenv "WSL_DISTRO_NAME" or "Arch"

-- ランチャー / domain 切替 UI で選択可能にする
local launcher_opts = {
  -- `wezterm start --domain wsl-arch` 等で直接起動も可
  domain = "DefaultUnixDomain",
}

-- タイトルフォーマット
wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
  local title = tab.active_pane.title
  if tab.is_active then
    return { { Foreground = { Color = "#fab387" } }, { Text = " " .. wezterm.truncate_right(title, max_width - 4) .. " " } }
  end
  return { { Text = " " .. wezterm.truncate_right(title, max_width - 4) .. " " } }
end)

-- ステータスバー (右下)
wezterm.on("update-right-status", function(window, pane)
  local names = {}
  for _, w in ipairs(mux.get_workspace_names()) do
    table.insert(names, w)
  end
  local current = window:active_workspace()
  window:set_right_status(
    wezterm.format { { Background = { Color = "#1e1e2e" } } }
    .. wezterm.format {
      { Foreground = { Color = "#cdd6f4" } },
      { Text = "  workspace: " },
      { Foreground = { Color = "#a6e3a1" } },
      { Text = current },
      { Foreground = { Color = "#585b70" } },
      { Text = "  |  domains: " },
      { Foreground = { Color = "#f9e2af" } },
      { Text = table.concat(names, ",") },
      { Text = "  " },
    }
  )
end)

-- ---------------------------------------------------------------------
-- Workspace 定義 (worktree と 1:1 対応)
-- ---------------------------------------------------------------------
-- mux の API は起動時の --workspace でも、CLI の `wezterm start --workspace <name>` でも切替可能。
-- ランチャーで可視化される。
-- ---------------------------------------------------------------------
-- 例: 起動スクリプト側で `wezterm start --workspace feat-a` を呼ぶ運用
--     各 worktree ごとに Neovim と agent pane を立ち上げるセットアップスクリプトを
--     scripts/start-worktree.sh に配置。

return config
