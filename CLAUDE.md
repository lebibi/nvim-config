# CLAUDE.md

Context file for working with this Neovim configuration codebase.

## Architecture Overview

Lazy.nvim-based config:

- **Entry Point**: `init.lua` — requires options, lazy, autocmds; enables exrc
- **Plugin Management**: `lua/core/lazy.lua` — bootstraps lazy.nvim
- **Plugin Specifications**: `lua/plugins/_init.lua` — imports all plugin configs
- **Individual Plugins**: `lua/plugins/*.lua` — one file per plugin
- **Configuration**: `lua/config/options.lua`, `lua/config/autocmds.lua` — vim settings and autocommands

## Key Configuration Details

### LSP Setup (lua/plugins/lsp.lua)

Mason auto-installs: pyright, clangd, rust_analyzer, starpls. Custom server configs for Bazel project support (compile_commands.json, Bazel-aware root markers).

### Formatting (lua/plugins/conform.lua)

Format-on-save enabled (500ms timeout). Supports: Python (black, isort), Rust (rustfmt), C/C++ (clang-format), Bazel (buildifier), Lua (stylua), JS/TS (prettier), shell (shfmt).

### Linting (lua/plugins/nvim-lint.lua)

nvim-lint runs on BufEnter/BufWritePost/InsertLeave. Linters: flake8+mypy (Python), luacheck (Lua), eslint_d (JS/TS), shellcheck (sh), markdownlint-cli2, yamllint, buildifier (Bazel).

### UI Plugins

- **Telescope**: File/grep/buffer search
- **Neo-tree**: File explorer with git status
- **Trouble**: Diagnostics panel
- **Noice** + **Snacks**: Message/notification improvements
- **Flash**: Jump/search motions
- **Lualine** + **Bufferline**: Status and tab lines

### AI Plugins

- **claude-code**: Claude Code integration
- **99**: LLM completion (ThePrimeagen/99)

## Development Commands

- Launch: `nvim`
- Clean launch (no plugins): `nvim --clean`
- Plugin management: `:Lazy`
- Tests: `bazel test //:test_all`

## See Also

- **README.md**: Installation, features, comprehensive keybindings, and known issues
