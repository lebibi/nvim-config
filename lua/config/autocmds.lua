vim.api.nvim_create_autocmd("BufWritePost", {
	group = vim.api.nvim_create_augroup("NotifyOnSave", { clear = true }),
	callback = function()
		local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
		vim.notify(file .. " saved", vim.log.levels.INFO)
	end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
	group = vim.api.nvim_create_augroup("AutoReloadFile", { clear = true }),
	command = "silent! checktime",
})

-- Dead process → auto-delete stale swap; live/unknown → confirm popup
vim.api.nvim_create_autocmd("SwapExists", {
	group = vim.api.nvim_create_augroup("SmartSwapHandler", { clear = true }),
	callback = function()
		vim.v.swapchoice = require("util.swap_handler").handle_swap(vim.v.swapname)
	end,
})
