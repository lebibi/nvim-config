vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.clipboard = "unnamedplus"

-- Over ssh, yank to the local clipboard with OSC 52
-- Paste the last yank, as reading the clipboard makes kitty prompt on every p
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
	local osc52 = require("vim.ui.clipboard.osc52")
	local last = { {}, "v" }
	local function copy(reg)
		local send = osc52.copy(reg)
		return function(lines, regtype)
			last = { lines, regtype }
			send(lines, regtype)
		end
	end
	local function paste()
		return last
	end
	vim.g.clipboard = {
		name = "OSC 52",
		copy = { ["+"] = copy("+"), ["*"] = copy("*") },
		paste = { ["+"] = paste, ["*"] = paste },
	}
end
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
