# =====================================================================
# PowerShell プロファイル (Windows 用)
# =====================================================================
# 配置: $PROFILE (例: ~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1)
# Linux の bash_aliases.sh と等価なコマンド体系を提供
# =====================================================================

# ---- モダンコマンド (winget / scoop 前提) ----
if (Get-Command eza -ErrorAction SilentlyContinue) {
  function ls  { eza --icons --group-directories-first @args }
  function ll  { eza -l --icons --group-directories-first --time-style=long-iso @args }
  function la  { eza -la --icons --group-directories-first --time-style=long-iso @args }
  function lt  { eza --tree --level=2 --icons @args }
}
if (Get-Command bat -ErrorAction SilentlyContinue) {
  function cat { bat --paging=never --style=plain @args }
}

if (Get-Command rg -ErrorAction SilentlyContinue) {
  Set-Alias -Name grep -Value rg -Option AllScope -Force
}

if (Get-Command fd -ErrorAction SilentlyContinue) {
  Set-Alias -Name find -Value fd -Option AllScope -Force
}

# ---- コアショートカット ----
Set-Alias -Name lg -Value lazygit -Option AllScope -Force
Set-Alias -Name n  -Value nvim    -Option AllScope -Force
Set-Alias -Name vim -Value nvim   -Option AllScope -Force

# ---- git ----
function gs  { git status -sb @args }
function gp  { git push @args }
function gpl { git pull --rebase --autostash @args }
function gco { git checkout @args }
function gcb { git checkout -b @args }
function gb  { git branch @args }
function gl  { git log --oneline --decorate --graph -20 @args }

# worktree
function gw  { git worktree @args }
function gwl { git worktree list }
function gwa { git worktree add @args }
function gwr { git worktree remove @args }

# ---- 環境変数 ----
$env:EDITOR   = 'nvim'
$env:VISUAL  = 'nvim'
$env:PAGER   = 'less -R'
$env:BAT_THEME = 'Catppuccin Mocha'

# ---- starship ----
if (Get-Command starship -ErrorAction SilentlyContinue) {
  Invoke-Expression (&starship init powershell)
}

# ---- zoxide ----
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  Invoke-Expression (&zoxide init powershell | Out-String)
}

# ---- fzf ----
if (Get-Command fzf -ErrorAction SilentlyContinue) {
  $env:FZF_DEFAULT_OPTS = '--height 60% --layout=reverse --border rounded --preview "bat --color=always --style=numbers --line-range=:500 {}"'
  if (Get-Command fd -ErrorAction SilentlyContinue) {
    $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
    $env:FZF_ALT_C_COMMAND   = 'fd --type d --hidden --follow --exclude .git'
  }
}

# ---- PSReadLine ----
if (Get-Module -ListAvailable -Name PSReadLine) {
  Set-PSReadLineOption -EditMode Vi
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -BellStyle None
  Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

# ---- WezTerm 経由 WSL へのクイック移動 ----
function wsl-arch {
  if (Get-Command wsl -ErrorAction SilentlyContinue) {
    wsl -d Arch
  } else {
    Write-Error "WSL is not available"
  }
}
