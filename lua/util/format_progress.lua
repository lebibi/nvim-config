-- Bulk format progress in noice's "mini" view, or the message line.

local M = {}

local SPINNER = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local MAX_NAME = 30

-- Must match the format_progress route in lua/plugins/noice.lua.
M.event = "format_progress"

local state = nil

local function noice()
	if not package.loaded["noice"] then
		return nil
	end
	local ok, mods = pcall(function()
		-- Without a UI noice is loaded but not running.
		if not require("noice.config").is_running() then
			return nil
		end
		return {
			Manager = require("noice.message.manager"),
			Message = require("noice.message"),
			Router = require("noice.message.router"),
		}
	end)
	return ok and mods or nil
end

local function has_ui()
	return #vim.api.nvim_list_uis() > 0
end

local function render(text)
	if not has_ui() then
		return
	end
	local n = noice()
	if not n then
		vim.api.nvim_echo({ { text, "DiagnosticInfo" } }, false, {})
		return
	end
	-- Re-adding the same message updates it in place.
	state.message = state.message or n.Message(M.event, "progress")
	state.message:set(text)
	n.Manager.add(state.message)
	n.Router.update()
end

local function clear(message)
	if not has_ui() then
		return
	end
	local n = noice()
	if not n or not message then
		vim.api.nvim_echo({ { "" } }, false, {})
		return
	end
	n.Manager.remove(message)
	n.Router.update()
end

function M.start(total)
	state = { index = 0, total = total, path = "", frame = 0 }
	render(M.status())
end

function M.step(index, path)
	if not state then
		return
	end
	state.index = index
	state.path = path or ""
	state.frame = state.frame + 1
	render(M.status())
end

function M.stop()
	if not state then
		return
	end
	local message = state.message
	state = nil
	clear(message)
end

function M.active()
	return state ~= nil
end

function M.shorten(path)
	if vim.fn.strdisplaywidth(path) <= MAX_NAME then
		return path
	end
	return "…" .. vim.fn.strcharpart(path, vim.fn.strchars(path) - (MAX_NAME - 1))
end

function M.status()
	if not state then
		return ""
	end
	local spinner = SPINNER[state.frame % #SPINNER + 1]
	local text = ("%s Formatting %d/%d"):format(spinner, state.index, state.total)
	if state.path == "" then
		return text
	end
	return text .. " " .. M.shorten(state.path)
end

return M
