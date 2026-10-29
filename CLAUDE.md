# CLAUDE.md

Context file for working with this Neovim configuration codebase.

## Architecture Overview

Lazy.nvim-based config:

- **Entry Point**: `init.lua` — requires options, lazy, autocmds; enables exrc
- **Plugin Management**: `lua/core/lazy.lua` — bootstraps lazy.nvim
- **Plugin Specifications**: `lua/plugins/_init.lua` — imports all plugin configs
- **Individual Plugins**: `lua/plugins/*.lua` — one file per plugin
- **Configuration**: `lua/config/options.lua`, `lua/config/autocmds.lua` — vim settings and autocommands
- **Helpers**: `lua/util/*.lua` — plain modules, each with a test in `tests/`

## Key Configuration Details

### LSP Setup (lua/plugins/lsp.lua)

Mason auto-installs: pyright, clangd, rust_analyzer, starpls. Custom server configs for Bazel project support (compile_commands.json, Bazel-aware root markers).

### Formatting (lua/plugins/conform.lua)

Format-on-save with a 2000ms timeout. Python uses isort and black when the project declares black, otherwise ruff. A project's `.pre-commit-config.yaml` replaces every formatter choice (`lua/util/project_hooks.lua`). `<leader>cF` and `<leader>cS` format changed or staged files through `lua/util/format_files.lua`.

### Linting (lua/plugins/nvim-lint.lua)

nvim-lint runs on BufEnter/BufWritePost/InsertLeave. Linters: ruff+mypy (Python), luacheck (Lua), eslint_d (JS/TS), shellcheck (sh), markdownlint-cli2, yamllint, buildifier (Bazel). Markdown line length is 90 and must match `lua/util/line_limit.lua`.

### UI Plugins

- **Telescope**: File/grep/buffer search
- **Neo-tree**: File explorer with git status
- **Trouble**: Diagnostics panel
- **Noice** + **Snacks**: Messages, notifications, statuscolumn, images
- **Flash**: Jump/search motions
- **Lualine** + **Bufferline**: Status and tab lines

### Keymaps

Leader groups follow LazyVim and are declared in `lua/plugins/whichkey.lua`. The README holds the full table.

## Development Commands

- Launch: `nvim`
- Clean launch (no plugins): `nvim --clean`
- Plugin management: `:Lazy`
- Tests: `bazel test //:test_all`
- Format Lua: `stylua lua tests`

## See Also

- **README.md**: Installation, features, comprehensive keybindings, and known issues
