#!/usr/bin/env bash
# =====================================================================
# セットアップスクリプト: Linux / WSL (Arch / Debian 系) 共通
# =====================================================================
# 使い方:
#   curl -fsSL <url> | bash
#   または
#   ./scripts/install-linux.sh
# =====================================================================
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/terminal_env/dotfiles}"

# ---- パッケージマネージャ判定 ----
if command -v pacman >/dev/null 2>&1; then
  PM="pacman"
  DISTRO="arch"
elif command -v apt >/dev/null 2>&1; then
  PM="apt"
  DISTRO="debian"
else
  echo "ERROR: pacman / apt のいずれも見つかりません。対応: pacman (Arch) / apt (Debian/Ubuntu)" >&2
  exit 1
fi
echo "==> Detected: $DISTRO ($PM)"

# ---- 必須ツール (ターミナル / エディタ / git TUI) ----
# Arch パッケージ名:
#   - delta は extra に "git-delta" として存在
#   - npm は nodejs に同梱されているので個別指定不要
echo "==> Installing core packages"
case "$PM" in
  pacman)
    sudo pacman -Syu --needed --noconfirm \
      neovim git lazygit starship fzf zoxide eza bat ripgrep fd git-delta \
      nodejs go rust python base-devel \
      clang llvm lldb gdb || {
        echo "  WARN: 一部パッケージのインストールに失敗しましたが続行します"
      }
    ;;
  apt)
    sudo apt update
    sudo apt install -y software-properties-common apt-transport-https ca-certificates gnupg
    # ripgrep / fd / delta
    sudo apt install -y ripgrep fd-find
    # bat は Debian で "batcat" のためリネーム
    sudo apt install -y bat
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
    sudo apt install -y git curl wget unzip make build-essential
    # lazygit
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz"
    sudo tar xf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit
    # eza (公式リポジトリ)
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb/release.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza
    # starship
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    ;;
esac

# ---- Neovim (LazyVim 要件: 0.9 以上) ----
if ! command -v nvim >/dev/null 2>&1; then
  echo "==> Installing Neovim"
  if [ "$PM" = "pacman" ]; then
    sudo pacman -S --noconfirm neovim
  else
    sudo snap install nvim --classic 2>/dev/null || {
      # snap が無い環境向け
      NVIM_VERSION=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep tag_name | cut -d'"' -f4)
      curl -Lo /tmp/nvim.appimage "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim.appimage"
      sudo install /tmp/nvim.appimage /usr/local/bin/nvim
    }
  fi
fi

# ---- Mermaid CLI (Markdown プレビュー用) ----
# Volta 経由の npm がある環境では sudo なし、それ以外は sudo でグローバル導入
echo "==> Installing @mermaid-js/mermaid-cli (mmdc)"
if command -v npm >/dev/null 2>&1; then
  # sudo で呼ぶと root の PATH に volta がない → 失敗する。
  # npm が root 以外の所有 (Volta など) なら sudo なしで実行
  if [ "$(stat -c %U "$(command -v npm)" 2>/dev/null)" != "root" ]; then
    npm install -g @mermaid-js/mermaid-cli 2>/dev/null || echo "  WARN: mmdc インストール失敗"
  else
    sudo npm install -g @mermaid-js/mermaid-cli 2>/dev/null || echo "  WARN: mmdc インストール失敗"
  fi
fi

# ---- fzf (apt では fuzzy finder パッケージ) ----
[ -f ~/.fzf.bash ] || {
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install --all --no-bash --no-zsh --no-fish
}

# ---- dotfiles 展開 (chezmoi 経由) ----
if command -v chezmoi >/dev/null 2>&1; then
  echo "==> chezmoi detected — applying $DOTFILES_DIR"
  # chezmoi ソース形式に揃えるため dotfiles/ を一時リポジトリに push する運用が理想
  echo "    初回は:  chezmoi init --apply https://github.com/your-name/dotfiles-repo.git"
  echo "    詳細は chezmoi/README.md 参照"
fi

# ---- 設定ファイル展開 (chezmoi 未使用時のフォールバック) ----
echo "==> Staging dotfiles into ~/.config"
mkdir -p ~/.config/{nvim/lua/plugins,lazygit,wezterm,starship}

[ -d "$DOTFILES_DIR/nvim" ] && cp -r "$DOTFILES_DIR/nvim/." ~/.config/nvim/
[ -d "$DOTFILES_DIR/lazygit" ] && cp -r "$DOTFILES_DIR/lazygit/." ~/.config/lazygit/
[ -d "$DOTFILES_DIR/starship" ] && cp -r "$DOTFILES_DIR/starship/." ~/.config/starship/
[ -d "$DOTFILES_DIR/wezterm" ] && cp -r "$DOTFILES_DIR/wezterm/." ~/.config/wezterm/
[ -d "$DOTFILES_DIR/git" ] && cp "$DOTFILES_DIR/git/.gitconfig" ~/.gitconfig 2>/dev/null || true
[ -d "$DOTFILES_DIR/shell" ] && cp "$DOTFILES_DIR/shell/bash_aliases.sh" ~/.bash_aliases 2>/dev/null || true

# ---- シェルに統合 (bash / zsh 両対応) ----
for rc in ~/.bashrc ~/.zshrc; do
  [ -f "$rc" ] || continue
  grep -qF 'bash_aliases.sh' "$rc" || {
    echo "[ -f ~/.bash_aliases ] && . ~/.bash_aliases" >> "$rc"
  }
done

# ---- starship 初期化 ----
grep -qF 'starship init' ~/.bashrc 2>/dev/null || {
  echo 'eval "$(starship init bash)"' >> ~/.bashrc
}
[ -f ~/.zshrc ] && ! grep -qF 'starship init' ~/.zshrc 2>/dev/null && {
  echo 'eval "$(starship init zsh)"' >> ~/.zshrc
}

# ---- WezTerm ----
# Linux 側にも WezTerm を入れるなら AppImage をダウンロード
if [ "$PM" = "pacman" ] && ! command -v wezterm >/dev/null 2>&1; then
  echo "==> Installing WezTerm (Linux)"
  yay -S --noconfirm wezterm 2>/dev/null || {
    WEZTERM_URL=$(curl -s https://api.github.com/repos/wez/wezterm/releases/latest | grep "browser_download_url" | grep -i "Ubuntu" | head -1 | cut -d'"' -f4)
    [ -n "$WEZTERM_URL" ] && curl -L "$WEZTERM_URL" -o /tmp/wezterm.deb && sudo apt install -y /tmp/wezterm.deb
  }
fi

# ---- フォント (Nerd Font) ----
echo "==> Installing JetBrainsMono Nerd Font (for symbols)"
mkdir -p ~/.local/share/fonts
curl -L -o /tmp/jbm.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
unzip -qo /tmp/jbm.zip -d ~/.local/share/fonts
fc-cache -fv >/dev/null

# ---- 完了 ----
echo ""
echo "================================================================"
echo "  Setup complete!"
echo "  - nvim を起動して LazyVim の初回ブートストラップを完了させてください"
echo "    nvim ~/.config/nvim/init.lua"
echo "  - docs/setup-guide.md も併せて参照"
echo "================================================================"
