# =====================================================================
# セットアップスクリプト: Windows (PowerShell / winget)
# =====================================================================
# 使い方 (PowerShell 管理者):
#   iwr -useb https://raw.githubusercontent.com/.../install-windows.ps1 | iex
#   または
#   .\scripts\install-windows.ps1
# =====================================================================
#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DOTFILES_DIR = if ($env:DOTFILES_DIR) { $env:DOTFILES_DIR } else { "$env:USERPROFILE\terminal_env\dotfiles" }

# ---------------------------------------------------------------------
# ヘルパー
# ---------------------------------------------------------------------
function Install-WithWinget {
  param([string[]]$PackageIds)
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Warning "winget が見つかりません。App Installer をインストールしてください: https://aka.ms/getwinget"
    return
  }
  foreach ($id in $PackageIds) {
    Write-Host "  -> winget install $id"
    & winget install --id $id --accept-source-agreements --accept-package-agreements --silent
  }
}

function Install-WithScoop {
  param([string]$PackageName)
  if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "  scoop が未インストール。インストール中..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
  }
  & scoop install $PackageName
}

# ---------------------------------------------------------------------
# コアツール
# ---------------------------------------------------------------------
Write-Host "==> Installing core tools via winget"
Install-WithWinget @(
  "Microsoft.WindowsTerminal",
  "wez.wezterm",
  "Neovim.Neovim",
  "Git.Git",
  "jesseduffield.lazygit",
  "Starship.Starship",
  "junegunn.fzf",
  "ajeetdsouza.zoxide",
  "eza-community.eza",
  "sharkdp.bat",
  "BurntSushi.ripgrep.MSVC",
  "sharkdp.fd",
  "dan-t.deltacopy"           # delta 的な diff ビューア。なければ別の選択肢で。
)

# Node.js (Mermaid CLI 用)
Install-WithWinget @("OpenJS.NodeJS.LTS")

# JetBrainsMono Nerd Font
Install-WithWinget @("DEVCOM.JetBrainsMonoNerdFont")

# PowerShell 7 (追加機能のため推奨)
# Install-WithWinget @("Microsoft.PowerShell")

# ---------------------------------------------------------------------
# dotfiles 展開
# ---------------------------------------------------------------------
Write-Host "==> Staging dotfiles to $env:USERPROFILE\.config"
$configRoot = "$env:USERPROFILE\.config"
New-Item -Path $configRoot\nvim\lua\plugins -ItemType Directory -Force | Out-Null
New-Item -Path $configRoot\lazygit   -ItemType Directory -Force | Out-Null
New-Item -Path $configRoot\wezterm   -ItemType Directory -Force | Out-Null
New-Item -Path $configRoot\starship  -ItemType Directory -Force | Out-Null

if (Test-Path "$DOTFILES_DIR\nvim") {
  Copy-Item -Path "$DOTFILES_DIR\nvim\*" -Destination "$configRoot\nvim\" -Recurse -Force
}
if (Test-Path "$DOTFILES_DIR\lazygit") {
  Copy-Item -Path "$DOTFILES_DIR\lazygit\*" -Destination "$configRoot\lazygit\" -Recurse -Force
}
if (Test-Path "$DOTFILES_DIR\wezterm") {
  Copy-Item -Path "$DOTFILES_DIR\wezterm\*" -Destination "$configRoot\wezterm\" -Recurse -Force
}
if (Test-Path "$DOTFILES_DIR\starship") {
  Copy-Item -Path "$DOTFILES_DIR\starship\*" -Destination "$configRoot\starship\" -Recurse -Force
}

# PowerShell profile
$psProfilePath = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
$psProfileDir  = Split-Path $psProfilePath -Parent
New-Item -Path $psProfileDir -ItemType Directory -Force | Out-Null
if (Test-Path "$DOTFILES_DIR\shell\powershell\Microsoft.PowerShell_profile.ps1") {
  Copy-Item -Path "$DOTFILES_DIR\shell\powershell\Microsoft.PowerShell_profile.ps1" -Destination $psProfilePath -Force
}

# git 設定 (Windows 用に autocrlf=true へ)
if (Test-Path "$DOTFILES_DIR\git\.gitconfig") {
  Copy-Item -Path "$DOTFILES_DIR\git\.gitconfig" -Destination "$env:USERPROFILE\.gitconfig" -Force
}

# ---------------------------------------------------------------------
# WezTerm 起動ショートカット
# ---------------------------------------------------------------------
Write-Host "==> WezTerm のフォント設定確認"
$weztermConfig = "$configRoot\wezterm\wezterm.lua"
if (Test-Path $weztermConfig) {
  (Get-Content $weztermConfig) -replace 'font_size = 13.0', 'font_size = 11.5' | Set-Content $weztermConfig
  # Windows 用に WSL distro 名を環境変数経由にしているので、$env:WSL_DISTRO_NAME を
  # ユーザーが Windows Terminal / WezTerm 設定で指定するか、PowerShell で export する。
  Write-Host "  WSL Arch を使う場合: `$env:WSL_DISTRO_NAME = 'Arch' を設定"
}

# ---------------------------------------------------------------------
# Windows Terminal 設定 (WezTerm をデフォルトにしたい場合)
# ---------------------------------------------------------------------
$wtSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $wtSettings) {
  Write-Host "==> Windows Terminal の設定を調整したい場合、settings.json に WezTerm を追加できます"
}

# ---------------------------------------------------------------------
# 完了
# ---------------------------------------------------------------------
Write-Host ""
Write-Host "================================================================"
Write-Host "  Setup complete!"
Write-Host "  - ログアウト / ログインして PATH を反映"
Write-Host "  - WezTerm を起動して PowerShell タブでプロンプトを確認"
Write-Host "  - docs/setup-guide.md を併せて参照"
Write-Host "================================================================"
