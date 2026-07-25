# アーキテクチャ

## 全体像

```mermaid
graph TB
  subgraph Host["Windows Host"]
    WT["WezTerm<br/>(mux + domain + workspace)"]
  end

  WT -->|domain: WSL| WSL["WSL2 Arch"]
  WT -->|domain: PowerShell| PS["PowerShell"]
  WT -->|domain: SSH| DC["devcontainer / remote"]
  WT -->|domain: SSH| RDP["将来: Linux / Mac 直"]

  subgraph WSLEnv["WSL 環境"]
    WSL --> ZSH["zsh / bash<br/>(starship prompt)"]
    ZSH --> NV1["Neovim (LazyVim)"]
    ZSH --> LG1["lazygit"]
    ZSH --> ALI1["eza, bat, fd, ripgrep, fzf, zoxide"]
  end

  subgraph PSEnv["PowerShell 環境"]
    PS --> PSProf["PSReadLine + Starship"]
    PSProf --> NV2["Neovim (LazyVim)"]
    PSProf --> LG2["lazygit"]
    PSProf --> ALI2["eza, bat, fd, ripgrep, fzf, zoxide"]
  end

  subgraph DCEnv["devcontainer"]
    DC --> SH3["bash + starship"]
    SH3 --> NV3["Neovim (LazyVim)"]
    SH3 --> LG3["lazygit"]
    SH3 --> ALI3["同等の CLI ツール"]
  end

  NV1 -. chezmoi .-> DOTS
  NV2 -. chezmoi .-> DOTS
  NV3 -. devcontainer.dotfiles .-> DOTS
  DOTS[("GitHub: dotfiles-repo")]

  LG1 --> WT1[("git worktree")]
  LG2 --> WT1
  LG3 --> WT1

  WT1 --> AG1[Agent 1: Claude Code]
  WT1 --> AG2[Agent 2: Codex]
  WT1 --> YOU[自分の Neovim]

  classDef host fill:#fab387,color:#1e1e2e,stroke:#1e1e2e
  classDef env fill:#a6e3a1,color:#1e1e2e,stroke:#1e1e2e
  classDef dot fill:#89b4fa,color:#1e1e2e,stroke:#1e1e2e
  classDef agent fill:#cba6f7,color:#1e1e2e,stroke:#1e1e2e
  class WT host
  class WSL,PS,DC env
  class DOTS dot
  class AG1,AG2,YOU agent
```

---

## レイヤ別責務

```mermaid
graph TB
  L1[Layer 1: 表示<br/>WezTerm] --> L2[Layer 2: シェル + プロンプト<br/>bash / zsh / PowerShell + starship]
  L2 --> L3[Layer 3: エディタ + LSP<br/>Neovim / LazyVim / vtsls / clangd / roslyn]
  L2 --> L4[Layer 4: git TUI<br/>lazygit + diffview + gitsigns]
  L2 --> L5[Layer 5: 移動 / 検索<br/>fzf / zoxide / ripgrep / fd]
  L1 --> L6[Layer 6: 設定同期<br/>chezmoi / devcontainer.dotfiles]
  L3 --> L6
  L4 --> L6
  L5 --> L6
```

| Layer | 役割 | 該当ツール |
|---|---|---|
| 1. 表示 | ターミナル描画 / ペイン分割 / domain 切替 | WezTerm |
| 2. シェル | コマンド実行環境・プロンプト | bash / zsh / PowerShell + starship |
| 3. エディタ | 編集・LSP・Markdown 描画 | Neovim + LazyVim + snacks / render-markdown / 各 LSP |
| 4. git TUI | worktree 作成・コミット・diff 確認 | lazygit + gitsigns.nvim + diffview.nvim |
| 5. 移動 / 検索 | ファイル移動・全文検索・履歴 | fzf / zoxide / ripgrep / fd / eza / bat |
| 6. 設定同期 | 3 環境で設定を単一リポジトリから配信 | chezmoi / devcontainer.json dotfiles |

---

## dotfiles 配布のデータフロー

```mermaid
flowchart LR
  subgraph Source["ソース (リポジトリ)"]
    S1[dotfiles/nvim/]
    S2[dotfiles/wezterm/]
    S3[dotfiles/lazygit/]
    S4[dotfiles/shell/]
    S5[dotfiles/starship/]
    S6[dotfiles/git/]
  end

  S1 --> GH
  S2 --> GH
  S3 --> GH
  S4 --> GH
  S5 --> GH
  S6 --> GH
  GH[("GitHub: dotfiles-repo")]

  GH -->|chezmoi init --apply| WSL_CFG["~/.config/nvim<br/>~/.config/wezterm<br/>~/.config/lazygit<br/>..."]
  GH -->|chezmoi init --apply| PS_CFG["%APPDATA%\\nvim<br/>%APPDATA%\\lazygit<br/>$PROFILE"]
  GH -->|devcontainer.dotfiles| DC_CFG["~/dotfiles-target → ~/.config/*"]
```

---

## Neovim (LazyVim) 内部構成

```mermaid
graph TB
  INIT["init.lua<br/>(LazyVim boot)"] --> LAZY["lazy.nvim"]
  LAZY --> LV["LazyVim コア"]
  LAZY --> SPEC["spec / extras"]
  SPEC --> EX1["lang.typescript → vtsls"]
  SPEC --> EX2["lang.clangd → clangd"]
  SPEC --> EX3["roslyn.nvim (手動追加)"]

  LAZY --> CUSTOM["lua/plugins/ (自作)"]
  CUSTOM --> SN["snacks<br/>(dashboard/picker/image)"]
  CUSTOM --> RM["render-markdown"]
  CUSTOM --> GS["gitsigns"]
  CUSTOM --> DV["diffview"]
  CUSTOM --> LSP["LSP overrides<br/>(inlay hints, settings)"]

  SN -. "Mermaid" .-> MMD["@mermaid-js/mermaid-cli (mmdc)"]
  SN -. "kitty graphics" .-> WT["WezTerm (kitty protocol)"]
```

---

## WezTerm の domain / workspace モデル

```mermaid
graph TB
  W["WezTerm Window"] --> D1["Domain: WSL"]
  W --> D2["Domain: PowerShell"]
  W --> D3["Domain: SSH (devcontainer)"]

  D1 --> T1A["Tab 1 (workspace: main)"]
  D1 --> T1B["Tab 2 (workspace: feat-a)"]
  D1 --> T1C["Tab 3 (workspace: feat-b)"]
  D2 --> T2A["Tab 1 (PowerShell workspace)"]
  D3 --> T3A["Tab 1 (devcontainer workspace)"]

  T1A --> P1["pane: nvim"]
  T1A --> P2["pane: shell"]
  T1B --> P3["pane: claude code"]
  T1B --> P4["pane: test server"]
  T1C --> P5["pane: codex"]
```

- **Domain**: プロセス (WSL, PowerShell, SSH) を識別
- **Workspace**: そのドメイン内の論理グループ (worktree 1:1 が基本)
- **Tab / Pane**: 実際の UI

---

## 拡張ポイント

新環境 (例: 会社の mac) を追加する場合:

```mermaid
graph TB
  R[("dotfiles-repo")] -->|chezmoi init| NEW["新環境 (mac)"]
  NEW -. macOS固有 .-> ADD["mac 用のオーバーレイ設定<br/>(chezmoi テンプレート)"]
```

- `chezmoi/templates/` 配下に `.tmpl` ファイルで OS 別分岐を書く
- mac 固有 (`iTerm2` から移行するなら AppleScript で WezTerm 起動等) もここに集約
- 新言語 LSP 追加: `init.lua` の `spec.extras.lang` に 1 行追加

---

## 関連

- [setup-guide.md](setup-guide.md) — 構築手順
- [worktree-workflow.md](worktree-workflow.md) — 並行開発
- [../README.md](../README.md) — トップ
- [../design.md](../design.md) — 元となった設計
