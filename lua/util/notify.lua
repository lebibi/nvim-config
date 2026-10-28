-- Snacks notifications that stay until clicked
--
-- Dismissed by mouse. snacks' `q` map needs the window focused.

local M = {}

local BUF_VAR = "persistent_notif_id"

local CLOSE = " ✕ "

local function style(buf, notif, ctx)
	-- snacks' "compact" style, which snacks does not export.
	local title = vim.trim(notif.icon .. " " .. (notif.title or ""))
	if title ~= "" then
		ctx.opts.title = { { " " .. title .. " ", ctx.hl.title } }
		ctx.opts.title_pos = "center"
	end
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(notif.msg, "\n"))
	vim.api.nvim_buf_set_extmark(buf, ctx.ns, 0, 0, {
		virt_text = { { CLOSE, ctx.hl.title } },
		virt_text_pos = "right_align",
		priority = 200,
	})
	vim.b[buf][BUF_VAR] = notif.id
end

function M.persistent(msg, opts)
	opts = vim.tbl_extend("force", { timeout = 0, style = style }, opts or {})
	local ok, snacks = pcall(require, "snacks")
	if not ok or not snacks.notifier then
		return vim.notify(msg, opts.level)
	end
	return snacks.notifier.notify(msg, opts.level, opts)
end

-- Notifier id of the persistent notification under the mouse.
local function under_mouse()
	local pos = vim.fn.getmousepos()
	local win = pos.winid
	if win == 0 or not vim.api.nvim_win_is_valid(win) then
		return nil
	end
	local buf = vim.api.nvim_win_get_buf(win)
	local ok, id = pcall(function()
		return vim.b[buf][BUF_VAR]
	end)
	return ok and id or nil
end

function M.setup()
	vim.keymap.set({ "n", "i" }, "<LeftRelease>", function()
		local id = under_mouse()
		if id == nil then
			return "<LeftRelease>"
		end
		-- Textlock in an expr mapping forbids closing the window.
		vim.schedule(function()
			pcall(function()
				require("snacks").notifier.hide(id)
			end)
		end)
		return "<Ignore>"
	end, { expr = true, replace_keycodes = true, desc = "Dismiss notification under mouse" })
end

return M
