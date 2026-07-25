# ターミナル完結の開発環境構成

## 背景・目的

- Claude Code / Codex の TUI での開発が快適なため、なるべくターミナルエミュレータから離れずに開発できる構成にしたい
- VSCode の遅さに耐えられなくなったため、エディタもターミナル内に移行する
- 実行環境は **WSL上のArch / devcontainer / PowerShell** の3つ。すべてほぼ同じ操作感で使えることが条件

## 必須要件

1. Markdown プレビュー(Mermaid 含む)
2. js/ts, C#, C++ など多言語の Language Server / syntax highlight(定義・参照ジャンプ)
3. git との統合
4. 複数 Agent × git worktree での並行開発
5. Agent を回しつつ、自分でもコード閲覧・レビュー・テスト環境起動・動作確認ができる

## 結論: 推奨構成

| レイヤ | ツール | 理由 |
|---|---|---|
| ターミナル | **WezTerm** | Windows/Linux 両対応。マルチプレクサ内蔵で、PowerShell 上でも pane/tab/workspace が使える |
| エディタ | **Neovim + LazyVim** | LSP・Treesitter・git 統合・Markdown レンダリングをプラグインで全部カバー。Windows ネイティブでも動作 |
| git TUI | **lazygit** | worktree 管理も UI 上で可能。3環境すべてで動作 |
| dotfiles 管理 | **chezmoi** | Windows と Linux で設定を単一リポジトリから配布。devcontainer には dotfiles 機能で自動注入 |

## 要件ごとの実現方法

### 1. Markdown + Mermaid プレビュー

- インエディタ: `render-markdown.nvim`(見出し・表・コードブロックの装飾表示)+ **`snacks.nvim` の image モジュール**
  - snacks.image は Mermaid ブロックを `mmdc` で画像化し、kitty graphics protocol でターミナル内にインライン描画する
  - WezTerm は `enable_kitty_graphics = true` で対応 → **ターミナル内で Mermaid 図が表示可能**
- ブラウザ確認用: `peek.nvim` または `markdown-preview.nvim`(Mermaid 対応・ライブリロード)

### 2. 多言語 LSP

LazyVim の extras を有効化するだけで揃う:

- js/ts → `vtsls`
- C++ → `clangd`
- C# → `roslyn.nvim`(VS と同じ Roslyn LSP。OmniSharp より高速)

`gd`(定義ジャンプ)、`gr`(参照一覧)、`K`(hover)が全言語共通で使える。

### 3. git 統合

- `lazygit`(Neovim 内から `<leader>gg` で起動)
- `gitsigns.nvim`(行単位 diff・hunk 操作)
- `diffview.nvim`(レビュー用 diff / 履歴ビュー)

### 4. 複数 Agent × git worktree 並行開発

- WezTerm の **workspace** を「1 worktree = 1 workspace」で割り当て、ランチャーで瞬時に切り替える
- worktree 作成は lazygit の worktree 機能、または `gwq` などの CLI ヘルパ
- Claude Code 自体にも worktree 分離機能があるため、agent 側に自動で分離させることも可能

### 5. Agent 並走 + 自分の作業

- workspace A で agent 2つ、workspace B で自分の Neovim + テストサーバの pane、という分け方ができる
- tmux と違い **PowerShell のセッションも同じ workspace に混在可能**(WezTerm mux の利点)
- レビューは `diffview.nvim` で worktree 間 diff、または lazygit で branch 間 diff

## 環境間の統一

- WezTerm の **domain** 機能で「このタブは WSL Arch、このタブは PowerShell」を1ウィンドウに同居
- devcontainer へは `devcontainer exec` か SSH domain で接続
- Neovim / lazygit / WezTerm の設定を chezmoi の1リポジトリに集約。devcontainer には `"dotfiles"` 設定で流し込む → **3環境どこで `nvim` を叩いても同じ環境**
- PowerShell 側の体験統一: `starship`(プロンプト)、`fzf` + `zoxide`(移動)、`eza` / `bat`

## Ghostty との比較(プライベートで使用中)

- **Ghostty は Windows 版が存在しない**(2026年時点で macOS / Linux のみ)ため、PowerShell 要件がある今回の用途では選択肢外
- Ghostty はマルチプレクサ非内蔵(tmux 等が前提)だが、tmux は PowerShell では使えない → 3環境統一には WezTerm 内蔵 mux が現実的
- 一方、描画速度・入力レイテンシ・kitty graphics protocol の完全性は Ghostty が上
- 使い分け方針:
  - 仕事マシン(Windows)→ WezTerm 一択
  - Linux/mac 中心なら Ghostty + tmux/zellij 併用も成立。ただし操作感の統一を最優先するなら全環境 WezTerm に寄せる方が楽

## 補足: Helix という選択肢

- LSP・Treesitter が設定ゼロで動き、Windows でも快適
- ただし Markdown + Mermaid のインラインプレビューやプラグインエコシステムがほぼ無いため、今回の必須要件では Neovim (LazyVim) が確実

## 導入手順(推奨順)

1. WezTerm を Windows にインストールし、WSL domain を設定
2. WSL Arch 側に Neovim (LazyVim) + lazygit を導入
3. 慣れてきたら chezmoi で設定をリポジトリ化し、PowerShell 側・devcontainer にも展開
