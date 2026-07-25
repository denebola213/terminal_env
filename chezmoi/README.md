# chezmoi による dotfiles 管理

## 概要

[chezmoi](https://www.chezmoi.io/) を使うと、Linux/WSL/Windows PowerShell の設定を **1 つの Git リポジトリから** 配布できます。devcontainer の `dotfiles` プロパティ経由でも、起動時に自動で流し込めます。

このリポジトリの `dotfiles/` 配下は chezmoi のソースツリーと互換の構造になっています。

```
dotfiles/
├── git/.gitconfig                        → ~/.gitconfig
├── lazygit/config.yml                    → ~/.config/lazygit/config.yml
├── nvim/                                 → ~/.config/nvim/   (init.lua + lua/plugins/)
├── shell/bash_aliases.sh                 → ~/.bash_aliases   (source で読み込み)
├── shell/powershell/Microsoft.PowerShell_profile.ps1
│                                        → ~/Documents/PowerShell/.../profile.ps1
├── starship/starship.toml                → ~/.config/starship.toml
└── wezterm/wezterm.lua                   → ~/.config/wezterm/wezterm.lua
```

## 初回セットアップ

### 1. chezmoi 用リポジトリの準備

```bash
# この terminal_env リポジトリの dotfiles/ だけを chezmoi 用に分離するのが楽。
# 例えば ~/dotfiles-repo というリポジトリに dotfiles/ の中身をコピーして push。
cd ~
git init dotfiles-repo
cp -r Projects/terminal_env/dotfiles/. dotfiles-repo/
cd dotfiles-repo
git add . && git commit -m "Initial dotfiles"
git remote add origin git@github.com:your-name/dotfiles-repo.git
git push -u origin main
```

### 2. chezmoi をインストール

```bash
# Arch
sudo pacman -S chezmoi
# Ubuntu
sudo apt install chezmoi    # snap でも可
# macOS
brew install chezmoi
# Windows
winget install twpayne.chezmoi
# PowerShell にパスを反映: $env:Path = [System.Environment]::GetEnvironmentVariable("Path","User") + ";$env:Path"
```

### 3. 適用

```bash
# 初回: 既存ファイルとの衝突を避けるため --force は付けずに。
chezmoi init --apply your-name/dotfiles-repo

# 2 回目以降
chezmoi update
```

### 4. 動作確認

```bash
chezmoi status                  # 適用状態の一覧
chezmoi diff                    # ローカル vs chezmoi ソースの差分
chezmoi apply --dry-run --verbose # 適用前の dry run
```

## ターゲット別の調整

chezmoi は OS / マシンごとに上書きできます。`chezmoi.os` / `chezmoi.arch` / テンプレート変数が利用可能。

例: WSL だけに固有の追加設定 (`dot_gitconfig` を WSL で上書き)

```toml
# chezmoi ソース側
[git]
    user = { name = "WSL User", email = "wsl@example.com" }
```

```text
# ファイル名規則: dot_gitconfig.tmpl にして、chezmoi のテンプレート内で
# {{ if eq .chezmoi.os "linux" }} で分岐
```

## devcontainer からの自動展開

`devcontainer/devcontainer.json` で以下の設定をします。

```json
"dotfiles": {
  "repository": "https://github.com/your-name/dotfiles-repo.git",
  "installPath": "~/dotfiles",
  "targetPath": "~/dotfiles-target"
},
"postCreateCommand": "bash scripts/install-devcontainer.sh"
```

devcontainer は `devcontainer up` / VS Code の "Reopen in Container" で起動した瞬間に GitHub の dotfiles リポジトリをクローンし、`installPath` で指定したスクリプト (`./install.sh` 等) を実行します。

ここでは `scripts/install-devcontainer.sh` でツール本体もまとめて入れる構成にしています。

## シークレットの扱い

- API キー・トークン類は `~/.config/chezmoi/chezmoi.toml` の `[diff]` / template で読み込むか、
  **絶対** に Git リポジトリに含めない。
- 代替: Bitwarden / 1Password CLI の vault から環境変数経由で展開。

```bash
chezmoi template --init       # テンプレート機能の初期化
```

## おすすめ運用フロー

```bash
# 1. 設定変更
nvim ~/.config/nvim/init.lua
# 2. chezmoi で取り込み
chezmoi re-add ~/.config/nvim/init.lua
# 3. コミット & プッシュ
chezmoi cd
git add -A && git commit -m "Update nvim config"
git push
# 4. 別環境で反映
chezmoi update -v
```
