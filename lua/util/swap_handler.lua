local M = {}

-- Neovim's dialog choices, with Delete it, which Neovim leaves out while the owner runs.
local CHOICES = "&Open Read-Only\n&Edit anyway\n&Recover\n&Delete it\n&Quit\n&Abort"
local LETTERS = { "o", "e", "r", "d", "q", "a" }

local function date(t)
	return t and t > 0 and os.date("%a %b %d %H:%M:%S %Y", t) or "?"
end

-- The details of Neovim's swap ATTENTION message, from swapinfo().
function M.describe(swapname, info, alive)
	local lines = {
		('Found a swap file by the name "%s"'):format(vim.fn.fnamemodify(swapname, ":~")),
		("          owned by: %s   dated: %s"):format(info.user or "?", date(info.mtime)),
		("         file name: %s"):format(info.fname or "?"),
		("          modified: %s"):format(info.dirty == 1 and "YES" or "no"),
		("         user name: %s   host name: %s"):format(info.user or "?", info.host or "?"),
		("        process ID: %s%s"):format(
			tostring(info.pid ~= 0 and info.pid or "?"),
			alive and " (STILL RUNNING)" or ""
		),
	}
	local stat = info.fname and vim.uv.fs_stat(vim.fn.expand(info.fname))
	if stat then
		table.insert(lines, ("     file is dated: %s"):format(date(stat.mtime.sec)))
		if info.mtime and stat.mtime.sec > info.mtime then
			table.insert(lines, "      NEWER than swap file!")
		end
	end
	-- confirm() puts the buttons on the message's last line.
	return table.concat(lines, "\n") .. "\n"
end

local function read(path)
	local file = io.open(path, "rb")
	if not file then
		return nil
	end
	local text = file:read("*a")
	file:close()
	return text
end

-- An `--embed` Neovim reparented to init. Its UI is gone and its swaps are stale.
function M.orphaned(stat, cmdline)
	local after = stat and stat:match("%) %S+ (%d+)")
	return after == "1" and cmdline ~= nil and cmdline:find("--embed", 1, true) ~= nil
end

-- Whether the Neovim behind a swap's PID can still be using the file
--
-- Signal 0 works without /proc. EPERM means the PID belongs to another user.
function M.alive(pid, kill)
	if not pid then
		return false
	end
	local ok, err = (kill or vim.uv.kill)(pid, 0)
	if ok ~= 0 and not tostring(err):find("EPERM", 1, true) then
		return false
	end
	return not M.orphaned(read("/proc/" .. pid .. "/stat"), read("/proc/" .. pid .. "/cmdline"))
end

-- A gone process's swap is deleted. Otherwise asks, and returns a v:swapchoice letter.
function M.handle_swap(swapname, opts)
	opts = opts or {}
	local swapinfo = opts.swapinfo or vim.fn.swapinfo
	local notify = opts.notify or vim.notify
	local confirm = opts.confirm or vim.fn.confirm

	local info = swapinfo(swapname) or {}
	local pid = info.pid and info.pid ~= 0 and info.pid or nil
	local alive = pid ~= nil and M.alive(pid, opts.kill)
	if pid and not alive then
		local name = vim.fn.fnamemodify(swapname, ":t")
		vim.schedule(function()
			notify("Deleted stale swap file: " .. name, vim.log.levels.WARN)
		end)
		return "d"
	end
	return LETTERS[confirm(M.describe(swapname, info, alive), CHOICES, 1)] or "q"
end

return M
