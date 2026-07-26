# AGENTS.md - terminal_env プロジェクト ルール & 知見

このファイルは opencode が自動的に読み込み、エージェントの行動指針として扱う。

## 1. コミット前の検証ルール（必須）

設定ファイルやスクリプトを変更した場合、**コミット前に必ず実際の起動テストを行う**。

### Neovim
```bash
# 起動エラーチェック
nvim -V2/tmp/nvim-startup.log --headless +q
grep -cE '^E[0-9]+:' /tmp/nvim-startup.log  # 0 であること
# Markdown を開いて render-markdown エラーが出ないか
timeout 15 nvim --headless README.md +q 2>&1 | grep -i "error"
```

### WezTerm
```bash
# 設定が正しく読み込まれるか（エラーが出ないか）
wezterm --config-file ~/.config/wezterm/wezterm.lua show-keys 2>&1 | grep -i "error"
# キーバインドが登録されているか
wezterm --config-file ~/.config/wezterm/wezterm.lua show-keys 2>&1 | grep "LEADER"
# プロセスが生存するか（実際に起動するか）
timeout 5 wezterm --config-file ~/.config/wezterm/wezterm.lua start --class TestWezterm sleep 8 &
sleep 2 && kill -0 $! && echo "OK"
```

### Lua 構文チェック
```bash
luac -p <file>.lua
```

### dotfiles 同期確認
```bash
# リポジトリ側と展開先（~/.config 等）の差分を確認
diff -q dotfiles/<name> ~/.config/<name>
```

## 2. 環境固有の知見

### Arch Linux パッケージ名
- `delta` は Arch では `git-delta` として提供される
- `npm` は `nodejs` に同梱されているため個別インストール不要
- AUR パッケージは `yay -S` でインストール

### Volta / ユーザー所有 npm
- Volta 経由の npm は root 以外が所有しているため `sudo npm install -g` は失敗する
- npm の所有者を確認し、root 以外なら sudo なしで実行:
  ```bash
  if [ "$(stat -c %U "$(command -v npm)")" != "root" ]; then
    npm install -g <pkg>
  else
    sudo npm install -g <pkg>
  fi
  ```

### zsh 互換性
- `bind -x` は bash 専用。zsh では `bindkey` を使う
- `zoxide init` はシェル別に切り替える（`zoxide init bash` / `zoxide init zsh`）
- starship init もシェル別（`starship init bash` / `starship init zsh`）
- `${ZSH_VERSION:-}` でシェル判定

## 3. LazyVim v16.0 の注意点

### lazyvim.json の extras 書式
- extras は `lazyvim.plugins.extras.` プレフィックス**なし**で書く
- LazyVim 内部で `"lazyvim.plugins.extras." .. extra.extra` と自動付与される
- プレフィックス付きで書くと二重になり module not found エラーになる
```json
{
  "extras": ["lang.typescript", "lang.clangd", "lsp.none-ls"]
}
```

### LazyVim ディレクトリ名
- lazy.nvim の spec 解決のためディレクトリ名は**大文字 `LazyVim`** 必須
- 小文字 `lazyvim` だと rtp に空パスが追加され module not found になる

### その他
- `echasnovski/mini.files` → `nvim-mini/mini.files` にリネームされた
- Netrw を無効化しないと E216 FileExplorer エラーが出る:
  ```lua
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1
  vim.api.nvim_create_augroup("FileExplorer", { clear = true })
  ```
- `snacks.image` に `activate()` メソッドは存在しない。Mermaid は `image.mermaid` 設定で自動検知される
- `render-markdown.nvim` の `link.custom` は `{ icon, pattern, kind }` テーブル形式（文字列値不可）

## 4. WezTerm 設定の注意点

### Leader キー
- `Ctrl+a`（tmux 互換）。`Ctrl+Shift+a` は一部環境でターミナルエミュレータに握り潰される
- `timeout_milliseconds = 2000` を明示設定

### キーバインド指定
- `mods` は文字列（`"LEADER"`, `"LEADER|SHIFT"`）。leader テーブルを直接渡さない
- `|`（パイプ）は Shift 必要なので `"LEADER|SHIFT"` にする

### ShowLauncherArgs
- `flags` は**単一文字列**（配列不可）: `{ flags = "WORKSPACES" }`
- `WORKSPACE`（単数形）は存在しない。`WORKSPACES`（複数形）が正しい
- 複数フラグを組み合わせられない → 別キーに分ける
- 1行でもエラーがあると**設定ファイル全体が読み込まれず**、すべてのキーバインドが無効になる

### default_domain
- 存在しないドメイン名を指定すると起動時クラッシュする
- `DefaultUnixDomain` という名前は存在しない
- 未設定なら WezTerm がローカルドメインを自動選出する

## 5. dotfiles 展開の確認

インストールスクリプト変更時は `cp` 行が漏れていないか確認:
```bash
# dotfiles 配下の全ディレクトリが install スクリプトで cp されているか
find dotfiles -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
grep "cp -r\|cp " scripts/install-linux.sh
```
過去に wezterm.lua のコピー行が欠落していた。

## 6. ドキュメント / Markdown

- Mermaid のエッジラベルはクォート必須: `-. "label" .->`（`-.label.->` はパースエラー）
- GitHub Markdown でコードブロック内のバックスラッシュに注意

## 7. Git 運用

- コミットメッセージは Conventional Commits 形式: `fix(scope): description`
- コミット前に `git diff` で変更内容を確認
- ユーザーが明示的に指示した場合のみ push / PR 作成
