# =====================================================================
# bash / zsh 共通エイリアス & 設定
# =====================================================================
# 配置: ~/.bashrc.d/aliases.sh (source する) または ~/.bash_aliases
# 3 環境で同等のコマンド体系を保証
# =====================================================================

# ---- モダンコマンド ----
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first --time-style=long-iso'
alias la='eza -la --icons --group-directories-first --time-style=long-iso'
alias lt='eza --tree --level=2 --icons'
alias lta='eza --tree --level=3 -a --icons'

alias cat='bat --paging=never --style=plain'
alias less='bat --paging=always'

alias grep='rg'
alias find='fd'

alias cd='z'
alias lg='lazygit'
alias n='nvim'
alias vim='nvim'

# ---- git ショートカット ----
alias gs='git status -sb'
alias gp='git push'
alias gpl='git pull --rebase --autostash'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gl='git log --oneline --decorate --graph -20'
alias gdiff='git diff'
alias gst='git stash'
alias gstp='git stash pop'

# worktree 関連 (詳細は docs/worktree-workflow.md 参照)
alias gw='git worktree'
alias gwl='git worktree list'
alias gwa='git worktree add'
alias gwr='git worktree remove'
alias gwq='git worktree add ../$(basename $(pwd))-worktree'

# ---- fzf / zoxide ----
if command -v fzf >/dev/null 2>&1; then
  # fzf のデフォルトオプション
  export FZF_DEFAULT_OPTS='--height 60% --layout=reverse --border rounded --preview "bat --color=always --style=numbers --line-range=:500 {}"'
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

if command -v zoxide >/dev/null 2>&1; then
  # bash と zsh で初期化コマンドが異なるためシェル判定
  if [ -n "${ZSH_VERSION:-}" ]; then
    eval "$(zoxide init zsh)"
  else
    eval "$(zoxide init bash)"
  fi
fi

# ---- 環境変数 ----
export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='less -R'
export MANPAGER='nvim +Man!'

# bat テーマ
export BAT_THEME='Catppuccin Mocha'

# fzf の Ctrl-R で ripgrep 全文検索 (シェル別)
if [ -n "${ZSH_VERSION:-}" ]; then
  # zsh 用 (bindkey)
  if command -v fzf >/dev/null 2>&1; then
    __fzf_history_grep() {
      local selected
      selected=$(builtin history -i 2>/dev/null | fzf --query="$LBUFFER" +m) || return
      LBUFFER="$selected"
      zle reset-prompt
    }
    zle -N __fzf_history_grep
    bindkey '^R' __fzf_history_grep
  fi
else
  # bash 用 (bind -x)
  if command -v fzf >/dev/null 2>&1; then
    __fzf_history_grep() {
      local selected
      selected=$(builtin history | fzf --query="$READLINE_LINE" +m) || return
      READLINE_LINE="$selected"
      READLINE_POINT=${#READLINE_LINE}
    }
    bind -x '"\C-r": __fzf_history_grep' 2>/dev/null || true
  fi
fi
