vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.clipboard = "unnamedplus"
vim.o.autoread = true

vim.opt.scrolloff = 5
vim.o.winborder = "rounded"
vim.opt.fixendofline = true

vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4

-- Treesitter folds. LspAttach in plugins/lsp.lua switches to LSP folding ranges.
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldtext = ""
-- Snacks' statuscolumn only draws the fold chevrons when foldcolumn is not "0".
vim.opt.foldcolumn = "1"
vim.opt.fillchars:append({ foldopen = "", foldclose = "", fold = " ", foldsep = " " })
