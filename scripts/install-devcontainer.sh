#!/usr/bin/env bash
# =====================================================================
# セットアップスクリプト: devcontainer (Ubuntu ベース)
# =====================================================================
# devcontainer.json の postCreateCommand から呼ばれる。
# 手動実行: ./scripts/install-devcontainer.sh
# =====================================================================
set -euo pipefail

if [ ! -f /.dockerenv ] && [ ! -f /run/.containerenv ]; then
  echo "WARN: devcontainer 外で実行されているように見えます。続行します..."
fi

echo "==> apt update"
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  build-essential curl wget unzip ca-certificates gnupg \
  software-properties-common apt-transport-https \
  git fd-find ripgrep bat \
  zsh

# bat → batcat シンボリックリンク
sudo ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true

# ---- Neovim ----
if ! command -v nvim >/dev/null 2>&1; then
  echo "==> Installing Neovim"
  NVIM_VERSION=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep tag_name | cut -d'"' -f4 | sed 's/^v//')
  curl -Lo /tmp/nvim-linux64.deb "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux64.deb"
  sudo apt install -y /tmp/nvim-linux64.deb
fi

# ---- lazygit ----
if ! command -v lazygit >/dev/null 2>&1; then
  echo "==> Installing lazygit"
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
  curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz"
  sudo tar xf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit
fi

# ---- eza ----
if ! command -v eza >/dev/null 2>&1; then
  echo "==> Installing eza"
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb/release.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
  sudo apt update
  sudo apt install -y eza
fi

# ---- starship ----
if ! command -v starship >/dev/null 2>&1; then
  echo "==> Installing starship"
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# ---- fzf ----
[ -f ~/.fzf.bash ] || {
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install --all --no-bash --no-zsh --no-fish
}

# ---- zoxide ----
curl -sSf https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# ---- delta ----
DELTA_VERSION=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest | grep tag_name | cut -d'"' -f4)
curl -Lo /tmp/delta.deb "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION#v}_amd64.deb"
sudo dpkg -i /tmp/delta.deb || sudo apt install -f -y

# ---- Mermaid CLI (snacks.image 経由の Mermaid レンダリング用) ----
echo "==> Installing Mermaid CLI"
if command -v npm >/dev/null 2>&1; then
  sudo npm install -g @mermaid-js/mermaid-cli 2>/dev/null || npm install -g @mermaid-js/mermaid-cli
else
  echo "  WARN: npm が見つかりません。Mermaid レンダリングを使うには Node.js を別途導入"
fi

# ---- dotfiles 展開 (devcontainer の `dotfiles` 機能では installPath に展開済み) ----
DOTFILES_TARGET="${DOTFILES_TARGET:-$HOME/dotfiles-target}"
DOTFILES_SOURCE="${DOTFILES_SOURCE:-$HOME/dotfiles}"

if [ -d "$DOTFILES_TARGET" ]; then
  echo "==> Applying dotfiles from $DOTFILES_TARGET"
  DOTFILES_DIR="$DOTFILES_TARGET"
else
  # dotfiles 機能を使わず、このリポジトリを使う場合 (fallback)
  DOTFILES_DIR="$DOTFILES_SOURCE"
fi

# 設定のコピー
mkdir -p ~/.config/{nvim/lua/plugins,lazygit,wezterm,starship}
[ -d "$DOTFILES_DIR/nvim" ] && cp -rn "$DOTFILES_DIR/nvim/." ~/.config/nvim/
[ -d "$DOTFILES_DIR/lazygit" ] && cp -rn "$DOTFILES_DIR/lazygit/." ~/.config/lazygit/
[ -d "$DOTFILES_DIR/starship" ] && cp -rn "$DOTFILES_DIR/starship/." ~/.config/starship/
[ -d "$DOTFILES_DIR/git" ] && cp -n "$DOTFILES_DIR/git/.gitconfig" ~/.gitconfig 2>/dev/null || true
[ -d "$DOTFILES_DIR/shell" ] && cp -n "$DOTFILES_DIR/shell/bash_aliases.sh" ~/.bash_aliases 2>/dev/null || true

# シェル統合
for rc in ~/.bashrc ~/.zshrc; do
  [ -f "$rc" ] || continue
  grep -qF 'bash_aliases.sh' "$rc" || {
    echo "[ -f ~/.bash_aliases ] && . ~/.bash_aliases" >> "$rc"
  }
done
grep -qF 'starship init' ~/.bashrc 2>/dev/null || {
  echo 'eval "$(starship init bash)"' >> ~/.bashrc
}

# ---- フォント ----
echo "==> Installing Nerd Font"
mkdir -p ~/.local/share/fonts
curl -L -o /tmp/jbm.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" 2>/dev/null
unzip -qo /tmp/jbm.zip -d ~/.local/share/fonts 2>/dev/null || true
fc-cache -fv >/dev/null 2>&1 || true

# ---- 完了 ----
echo ""
echo "================================================================"
echo "  devcontainer setup complete!"
echo "  - nvim を起動して LazyVim をブートストラップ: nvim ~/.config/nvim/init.lua"
echo "================================================================"
