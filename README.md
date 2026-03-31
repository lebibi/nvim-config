# NeoVim Configuration

A Lazy.nvim-based configuration with LSP, completion, formatting, and motion plugins. Designed for C/C++, Python, Rust, and Bazel development with ROS2 support.

## Prerequisites

Mason auto-installs LSP servers, formatters, and linters, but needs these system packages:

git, ripgrep, python3, pip, node, npm, luarocks, clang, unzip, curl, xclip

**One-liner install:**

Arch:

```sh
sudo pacman -S --needed git ripgrep python python-pip nodejs npm luarocks clang unzip curl xclip
```

Ubuntu/Debian:

```sh
sudo apt install git ripgrep python3 python3-pip python3-venv nodejs npm luarocks clang unzip curl xclip
```

macOS:

```sh
brew install git ripgrep python node luarocks llvm unzip curl
```

Alternatively, install node via [nvm](https://github.com/nvm-sh/nvm) instead of the system package manager:

```sh
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
nvm install --lts
```

## Installation

Clone and symlink:

```sh
git clone <repo-url> ~/.config/nvim
```

Lazy.nvim will auto-bootstrap on first launch.

## Features

### LSP & Completion

- **Language Servers** (auto-installed via Mason):
  - Python: `pyright`
  - C/C++: `clangd` (configured for Bazel projects)
  - Rust: `rust_analyzer`
  - Bazel/Starlark: `starpls`
- **Completion**: nvim-cmp with snippets (LuaSnip)
- **Formatting** (Conform): black, isort, rustfmt, prettier, clang-format, buildifier, stylua
- **Linting** (nvim-lint): flake8, mypy, luacheck, eslint_d, shellcheck, markdownlint-cli2, yamllint, buildifier

### Navigation & Motion

- **Flash**: Quick jump with `s`, treesitter with `S`
- **Telescope**: File/grep/buffer search
- **Neo-tree**: File explorer with git integration
- **Trouble**: Diagnostics panel for LSP errors

### UI Improvements

- **Noice**: Better LSP hover, message display
- **Snacks**: Notifications, dashboard, git integration
- **Lualine**: Status line
- **Bufferline**: Tabbed buffers
- **Render-markdown**: In-buffer markdown rendering
- **Indent-blankline**: Indentation guides

### Other

- **Gitsigns**: Git change indicators
- **Comment.nvim**: Toggle comments (`gc`, `gb`)
- **Vim-fugitive**: Git commands
- **Vim-tmux-navigator**: Seamless tmux/vim navigation
- **DAP**: Debugging support
- **Todo-comments**: Highlight TODO, FIXME, etc.
- **Mini-pairs**: Auto-close brackets/quotes
- **Persistence**: Session management
- **Claude-code**: Claude Code integration
- **99**: LLM completion

## Keybindings

### LSP & Code Navigation

| Shortcut | Action                       |
| -------- | ---------------------------- |
| `gD`     | Go to declaration            |
| `gi`     | Go to implementation         |
| `grt`    | Go to type definition        |
| `gO`     | Document symbols             |
| `gq`     | Format code                  |
| `<C-s>`  | Signature help (insert mode) |

### Diagnostics

| Shortcut     | Action                      |
| ------------ | --------------------------- |
| `[d` / `]d`  | Previous/next diagnostic    |
| `<leader>d`  | Show error details          |
| `<leader>xx` | Toggle all diagnostics      |
| `<leader>xX` | Toggle buffer diagnostics   |
| `<leader>cs` | Show symbols                |
| `<leader>cl` | LSP definitions/references  |
| `<leader>xL` | Location list               |
| `<leader>xQ` | Quickfix list               |
| `[q` / `]q`  | Previous/next quickfix item |

### File Navigation

| Shortcut     | Action          |
| ------------ | --------------- |
| `<leader>ff` | Find files      |
| `<leader>fg` | Live grep       |
| `<leader>fb` | Find buffers    |
| `<leader>fh` | Find help tags  |
| `<leader>e`  | Toggle Neo-tree |
| `<leader>o`  | Focus Neo-tree  |

### Neo-tree Mappings

| Shortcut        | Action                   |
| --------------- | ------------------------ |
| `<cr>`          | Open file/folder         |
| `l` / `h`       | Open file / close folder |
| `a`             | Add file/folder          |
| `d`             | Delete                   |
| `r`             | Rename                   |
| `y` / `x` / `p` | Copy / cut / paste       |
| `c` / `m`       | Copy / move              |
| `R`             | Refresh                  |
| `H`             | Toggle hidden files      |
| `[g` / `]g`     | Previous/next git change |
| `P`             | Toggle preview           |
| `zc` / `ze`     | Close / expand all       |
| `?`             | Show help                |

### Motion

| Shortcut | Action                  |
| -------- | ----------------------- |
| `s`      | Flash jump              |
| `S`      | Flash treesitter        |
| `r`      | Remote flash (operator) |
| `R`      | Treesitter search       |
| `<c-s>`  | Toggle flash search     |

### Comments

| Shortcut | Action               |
| -------- | -------------------- |
| `gc`     | Toggle line comment  |
| `gb`     | Toggle block comment |

### Other

| Shortcut     | Action                 |
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

## Development Notes

### LSP Configuration

Each LSP server has custom configuration in `lua/plugins/lsp.lua`:

- **Clangd**: Bazel-aware with compile_commands.json support
- **Pyright**: Supports both Python and Bazel Python targets
- **Rust-analyzer**: Disables proc macros and build scripts to avoid indexing stalls
- **Starpls**: Configured with bazelisk path

### Formatting

- Auto-formats on save (500ms timeout, LSP fallback)
- Conform.nvim handles all formatter setup
- Custom formatters by filetype (see `lua/plugins/conform.lua`)

### Testing

```sh
bazel test //:test_all          # Run all tests
bazel test //:test_swap_handler # Test swap file handler
```

## Known Issues

- Telescope doesn't find ROS2 nodes/action servers
- `gd` (go to definition), `grr` (references), `grn` (rename), `K` (hover) are Neovim 0.11+ built-in LSP mappings, not defined in this config
