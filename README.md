# My Neovim Config

A personal Neovim setup built on Lazy.nvim, focused on C/C++, Python, Rust, and Bazel. It has full LSP, formatting, linting, and a handful of UI/motion plugins I use.

## Getting Started

### Prerequisites

This configuration requires Neovim 0.12 or newer. Mason installs the configured
LSP servers, formatters, and linters, but it relies on system runtimes to install
some packages.

**Install Node.js and npm with nvm**

npm is included with Node.js. Do not install npm separately. Install the current
Node.js LTS release and the latest npm version compatible with it:

```sh
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.6/install.sh | bash
```

Restart the shell, then run:

```sh
nvm install --lts --latest-npm
node --version
npm --version
```

Mason uses Node and npm for tools such as `pyright`, `prettier`, `eslint_d`, and
`markdownlint-cli2`.

**Install the remaining dependencies**

Python 3.10 or newer is required for Mason packages such as `black`, `isort`,
`mypy`, and `yamllint`. The `nvim-treesitter` main branch requires
`tree-sitter-cli` 0.26.1 or newer. Image rendering needs ImageMagick and a
terminal that speaks the kitty graphics protocol (kitty, WezTerm, Ghostty) or
Überzug++ elsewhere.

**Arch:**

```sh
sudo pacman -S --needed git ripgrep python python-pip tree-sitter-cli luarocks clang unzip curl xclip imagemagick
```

**Ubuntu/Debian:**

```sh
sudo apt install git ripgrep python3 python3-pip python3-venv luarocks clang unzip curl xclip imagemagick
npm install -g --allow-scripts=tree-sitter-cli tree-sitter-cli@latest
```

Ubuntu 24.04's `tree-sitter-cli` package is too old for the `nvim-treesitter`
main branch. The npm command installs a current CLI and explicitly permits its
binary installer, which npm 12 blocks by default. Confirm the installed version
with `tree-sitter --version`.

**macOS:**

```sh
brew install git ripgrep python tree-sitter-cli luarocks llvm unzip curl imagemagick
```

Homebrew must appear before `/usr/bin` so Mason finds Homebrew Python instead of
Apple's older system Python. Add this to `~/.zprofile`:

```sh
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Restart the shell and verify the runtimes:

```sh
python3 --version
tree-sitter --version
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

To install any missing Mason tools manually and wait for completion:

```vim
:MasonToolsInstallSync
```

Markdown rendering depends on the `markdown` and `markdown_inline` Tree-sitter
parsers. Check it with:

```vim
:checkhealth render-markdown
```

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

`<leader>cF` formats every changed or untracked file, `<leader>cS` only files
with staged hunks. Both format whole files and leave the result unstaged. An
open buffer is reloaded from disk first. If it also has unsaved edits, you are
asked which version to format.

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
- **Snacks.image** — renders images in the terminal: open a `png`/`jpg`/`gif`/
  `svg`/`pdf` directly, or see markdown and LaTeX images inline
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

Leader is `<space>`. Groups follow the LazyVim convention:

| Prefix      | Group                | Holds                          |
| ----------- | -------------------- | ------------------------------ |
| `<leader>b` | buffer               | pin, close, delete             |
| `<leader>c` | code                 | format, lint, symbols, rename  |
| `<leader>d` | debug                | free, kept for nvim-dap        |
| `<leader>f` | find/file            | files, buffers                 |
| `<leader>g` | git                  | lazygit, blame, `gh*` hunks    |
| `<leader>q` | quit/session         | restore, don't save            |
| `<leader>s` | search               | grep, help, todos              |
| `<leader>u` | ui/toggle            | notifications, markdown, image |
| `<leader>x` | diagnostics/quickfix | Trouble panels, lists          |

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
| `<leader>cd` | Line diagnostics                 |
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
| `<leader>fb` | Find buffers    |
| `<leader>e`  | Toggle Neo-tree |
| `<leader>E`  | Focus Neo-tree  |

### Search

| Key          | Action                  |
| ------------ | ----------------------- |
| `<leader>sg` | Live grep               |
| `<leader>sh` | Help tags               |
| `<leader>st` | Todos                   |
| `<leader>sT` | Todo / Fix / Fixme      |
| `<Esc>`      | Clear search highlights |

### Git

| Key           | Action                           |
| ------------- | -------------------------------- |
| `<leader>gg`  | Lazygit                          |
| `<leader>gl`  | Lazygit log                      |
| `<leader>gf`  | Lazygit file history             |
| `<leader>gb`  | Blame line                       |
| `<leader>gB`  | Open in browser                  |
| `<leader>ghs` | Stage hunk / selection (toggles) |
| `<leader>ghS` | Stage entire buffer              |
| `<leader>ghp` | Preview hunk                     |
| `<leader>ghd` | Diff against index               |
| `<leader>ghD` | Diff against last commit         |
| `<leader>ghr` | Reset hunk (or selection)        |
| `<leader>ghR` | Reset entire buffer              |
| `<leader>ghB` | Blame entire file                |
| `[h` / `]h`   | Previous / next hunk             |

Hunk keys work in every buffer, untracked files included. Staging an untracked
file runs `git add --intent-to-add` first. `gh`, `gH` and `g<C-h>`, which start
Select mode, are mapped to `<Nop>`. `:unmap gh` restores `gh`.

### UI & Toggles

| Key          | Action                    |
| ------------ | ------------------------- |
| `<leader>un` | Dismiss all notifications |
| `<leader>ud` | Toggle diagnostics        |
| `<leader>um` | Toggle markdown rendering |
| `<leader>ui` | Image at cursor (float)   |
| `<leader>ub` | Toggle scrollbind         |

### Buffers

| Key          | Action                      |
| ------------ | --------------------------- |
| `<leader>bd` | Delete buffer               |
| `<leader>bp` | Toggle pin                  |
| `<leader>bP` | Delete non-pinned buffers   |
| `<leader>bo` | Delete other buffers        |
| `<leader>br` | Delete buffers to the right |
| `<leader>bl` | Delete buffers to the left  |

### Session

| Key          | Action                  |
| ------------ | ----------------------- |
| `<leader>qs` | Restore session for cwd |
| `<leader>ql` | Restore last session    |
| `<leader>qd` | Stop saving the session |

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
| `F`             | Format file or directory   |
| `H`             | Toggle hidden files        |
| `[g` / `]g`     | Previous / next git change |
| `P`             | Toggle preview             |
| `zc` / `ze`     | Close / expand all         |
| `?`             | Help                       |

`F` formats what the cursor sits on: a single file, or every changed or
untracked file under a directory, recursively. Select several lines in visual
mode to format that whole selection. The file list comes from git, so
`.gitignore`d paths and `.git/` are skipped, and anything over 25 files asks
first.

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

### Folding

Folds come from the language server's folding ranges where it offers them, and
from treesitter elsewhere. Files open unfolded. Click a chevron in the
statuscolumn to toggle a fold.

| Key  | Action                    |
| ---- | ------------------------- |
| `za` | Toggle fold under cursor  |
| `zo` | Open fold                 |
| `zc` | Close fold                |
| `zR` | Open all folds            |
| `zM` | Close all folds           |
| `zj` | Jump to next fold start   |
| `zk` | Jump to previous fold end |
| `zv` | Open just enough to see   |

### Misc

| Key           | Action                         |
| ------------- | ------------------------------ |
| `<leader>cf`  | Format buffer                  |
| `<leader>cF`  | Format all git-modified files  |
| `<leader>cS`  | Format files with staged hunks |
| `<leader>cL`  | Trigger linting                |
| `<leader>cR`  | Rename file                    |
| `<leader>co`  | Show code owners               |
| `<c-/>`       | Toggle terminal                |
| `<c-h/j/k/l>` | Move between splits            |

---

## Known Issues

- Telescope doesn't find ROS2 nodes or action servers
