# My Neovim Config

A personal Neovim setup built on Lazy.nvim, focused on C/C++, Python, Rust, and Bazel. It has full LSP, formatting, linting, and a handful of UI/motion plugins I use.

## Getting Started

### Prerequisites

Mason handles LSP servers, formatters, and linters automatically — but it needs a few system packages to do its thing.

**Install Node via nvm**

```sh
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
nvm install --lts
```

Then install the remaining dependencies:

**Arch:**

```sh
sudo pacman -S --needed git ripgrep python python-pip luarocks clang unzip curl xclip
```

**Ubuntu/Debian:**

```sh
sudo apt install git ripgrep python3 python3-pip python3-venv luarocks clang unzip curl xclip
```

**macOS:**

```sh
brew install git ripgrep python luarocks llvm unzip curl
```

**Rust toolchain (optional, only if you edit Rust):**

Mason installs `rust-analyzer`, but **does not** ship `rustfmt` (it's not in Mason's registry — `rustfmt` is part of the Rust toolchain). Install via `rustup`:

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup component add rustfmt
```

This also gives you `rustc` and `cargo`, which `rust-analyzer` needs to find the sysroot when opening `.rs` files. Distro-packaged `rustfmt` works too (`sudo apt install rustfmt`), but `rustup` is recommended.

### Installation

```sh
git clone <repo-url> ~/.config/nvim
```

Then just open Neovim — Lazy.nvim bootstraps itself and installs everything on first launch.

---

## What's Included

### LSP & Completion

Language servers are auto-installed via Mason:

- **Python** — `pyright`
- **C/C++** — `clangd`, configured for Bazel projects (compile_commands.json, Bazel root markers)
- **Rust** — `rust_analyzer` (proc macros and build scripts disabled to avoid indexing stalls)
- **Bazel/Starlark** — `starpls`

Completion comes from nvim-cmp with LuaSnip for snippets.

**Formatting** (via Conform, auto-runs on save with 500ms timeout):
black, isort, rustfmt, clang-format, buildifier, stylua, prettier, shfmt

**Linting** (via nvim-lint, runs on BufEnter/BufWrite/InsertLeave):
flake8, mypy, luacheck, eslint_d, shellcheck, markdownlint-cli2, yamllint, buildifier

### Navigation

- **Telescope** — fuzzy file/grep/buffer search
- **Neo-tree** — file explorer with git status
- **Flash** — fast jump motions (`s` to jump, `S` for treesitter selection)
- **Trouble** — diagnostics panel

### UI

- **Noice** — cleaner LSP hover and message display
- **Snacks** — notifications, dashboard, git bits
- **Lualine** — status line
- **Bufferline** — tabbed buffers
- **Render-markdown** — renders markdown right in the buffer
- **Indent-blankline** — indentation guides

### Other Useful Stuff

- **Gitsigns** — git change indicators in the gutter
- **Vim-fugitive** — git commands from within Neovim
- **Lazygit** (via Snacks) — full git TUI
- **DAP** — debugging support
- **Comment.nvim** — `gc` / `gb` to toggle comments
- **Vim-tmux-navigator** — seamless pane navigation between tmux and Neovim
- **Mini-pairs** — auto-closes brackets and quotes
- **Persistence** — session management
- **Todo-comments** — highlights TODO, FIXME, NOTE, etc.
- **Claude-code** — Claude Code integration
- **99** — LLM completion

---

## Keybindings

> **Note:** `gd` (go to definition), `grr` (references), `grn` (rename), and `K` (hover) are built-in Neovim 0.11+ LSP mappings — they're not defined here but work out of the box.

### LSP & Code Navigation

| Key     | Action                       |
| ------- | ---------------------------- |
| `gD`    | Go to declaration            |
| `gi`    | Go to implementation         |
| `grt`   | Go to type definition        |
| `gO`    | Document symbols             |
| `gq`    | Format code                  |
| `<C-s>` | Signature help (insert mode) |

### Diagnostics

| Key          | Action                           |
| ------------ | -------------------------------- |
| `[d` / `]d`  | Previous / next diagnostic       |
| `<leader>d`  | Show error details               |
| `<leader>xx` | Toggle all diagnostics (Trouble) |
| `<leader>xX` | Toggle buffer diagnostics        |
| `<leader>cs` | Show symbols                     |
| `<leader>cl` | LSP definitions / references     |
| `<leader>xL` | Location list                    |
| `<leader>xQ` | Quickfix list                    |
| `[q` / `]q`  | Previous / next quickfix item    |

### File Navigation

| Key          | Action          |
| ------------ | --------------- |
| `<leader>ff` | Find files      |
| `<leader>fg` | Live grep       |
| `<leader>fb` | Find buffers    |
| `<leader>fh` | Find help tags  |
| `<leader>e`  | Toggle Neo-tree |
| `<leader>o`  | Focus Neo-tree  |

### Neo-tree

| Key             | Action                     |
| --------------- | -------------------------- |
| `<cr>`          | Open file / folder         |
| `l` / `h`       | Open file / close folder   |
| `a`             | Add file or folder         |
| `d`             | Delete                     |
| `r`             | Rename                     |
| `y` / `x` / `p` | Copy / cut / paste         |
| `c` / `m`       | Copy / move                |
| `R`             | Refresh                    |
| `H`             | Toggle hidden files        |
| `[g` / `]g`     | Previous / next git change |
| `P`             | Toggle preview             |
| `zc` / `ze`     | Close / expand all         |
| `?`             | Help                       |

### Motion (Flash)

| Key     | Action                  |
| ------- | ----------------------- |
| `s`     | Jump                    |
| `S`     | Treesitter selection    |
| `r`     | Remote flash (operator) |
| `R`     | Treesitter search       |
| `<c-s>` | Toggle flash search     |

### Comments

| Key  | Action               |
| ---- | -------------------- |
| `gc` | Toggle line comment  |
| `gb` | Toggle block comment |

### Misc

| Key          | Action                 |
| ------------ | ---------------------- |
| `<leader>cf` | Format buffer          |
| `<leader>cL` | Trigger linting        |
| `<leader>mt` | Toggle markdown render |
| `<c-/>`      | Toggle terminal        |
| `<leader>gg` | Lazygit                |
| `<leader>gb` | Git blame line         |
| `<leader>gl` | Lazygit log            |
| `<leader>bd` | Delete buffer          |
| `<leader>cR` | Rename file            |

---

## Known Issues

- Telescope doesn't find ROS2 nodes or action servers
