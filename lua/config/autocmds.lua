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

-- Toggle scrollbind on all normal windows (skips any special buftype like neo-tree, help, etc.)
vim.keymap.set("n", "<leader>sb", function()
	local enable = not vim.wo.scrollbind
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].buftype == "" then
			vim.wo[win].scrollbind = enable
		end
	end
	vim.notify("Scrollbind " .. (enable and "ON" or "OFF"))
end, { desc = "Toggle scrollbind" })

-- Maintain window proportions on terminal resize (only for normal file windows)
vim.api.nvim_create_autocmd("VimResized", {
	group = vim.api.nvim_create_augroup("KeepWindowProportions", { clear = true }),
	callback = function()
		local wins = vim.tbl_filter(function(win)
			local buf = vim.api.nvim_win_get_buf(win)
			return vim.bo[buf].buftype == ""
		end, vim.api.nvim_tabpage_list_wins(0))
		if #wins > 0 then
			vim.cmd("wincmd =")
		end
	end,
})

-- <CR> jumps into an open floating window, <Esc> closes all floats
vim.keymap.set("n", "<CR>", function()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_config(win).relative ~= "" then
			vim.api.nvim_set_current_win(win)
			return
		end
	end
	-- Default <CR> when no float is open
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
end, { desc = "Enter float or default CR" })

-- Close all floating windows with <Esc>
vim.keymap.set("n", "<Esc>", function()
	local closed = false
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative ~= "" then
			pcall(vim.api.nvim_win_close, win, true)
			closed = true
		end
	end
	if not closed then
		vim.cmd("nohlsearch")
	end
end, { desc = "Close floats or clear highlights" })

-- Draw colorcolumn at the project's formatter line limit
-- (clang-format ColumnLimit, black line-length, rustfmt max_width, stylua column_width, prettier printWidth)
vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
	group = vim.api.nvim_create_augroup("LineLimitColorColumn", { clear = true }),
	callback = function(args)
		require("util.line_limit").apply(args.buf)
	end,
})

-- On save, reformat contiguous comment blocks to fit the limit. Most code
-- formatters (rustfmt, black, stylua) don't wrap comments themselves; this
-- handles them in pure Lua so it works regardless of which formatter (if any)
-- runs next via conform's BufWritePre.
vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("WrapCommentsOnSave", { clear = true }),
	callback = function(args)
		require("util.line_limit").wrap_comments(args.buf)
	end,
})

-- After startup, check if the Neovim config repo is behind upstream (rate-limited
-- to once per 24h). Prompts to pull if so.
vim.api.nvim_create_autocmd("VimEnter", {
	group = vim.api.nvim_create_augroup("ConfigUpdateCheck", { clear = true }),
	once = true,
	callback = function()
		vim.defer_fn(function()
			require("util.check_config_update").check()
		end, 1000)
	end,
})

-- Dead process → auto-delete stale swap; live/unknown → confirm popup
vim.api.nvim_create_autocmd("SwapExists", {
	group = vim.api.nvim_create_augroup("SmartSwapHandler", { clear = true }),
	callback = function()
		vim.v.swapchoice = require("util.swap_handler").handle_swap(vim.v.swapname)
	end,
})
