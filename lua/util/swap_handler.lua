local M = {}

function M.handle_swap(swapname, opts)
	opts = opts or {}
	local fs_stat = opts.fs_stat or vim.uv.fs_stat
	local confirm = opts.confirm or vim.fn.confirm
	local swapinfo = opts.swapinfo or vim.fn.swapinfo
	local notify = opts.notify or vim.notify

	local info = swapinfo(swapname)
	local pid = info and info.pid and info.pid ~= 0 and info.pid or nil

	if pid then
		local alive = fs_stat("/proc/" .. tostring(pid)) ~= nil
		if not alive then
			local name = vim.fn.fnamemodify(swapname, ":t")
			vim.schedule(function()
				notify("Deleted stale swap file: " .. name, vim.log.levels.WARN)
			end)
			return "d"
		end
	end

	local msg = ("Swap file exists (PID %s)"):format(tostring(pid or "?"))
	local choice = confirm(msg, "&Edit\n&Read-only\n&Delete swap\n&Quit\n&Abort", 1)
	local choices = { "e", "o", "d", "q", "a" }
	return choices[choice] or "q"
end

return M
