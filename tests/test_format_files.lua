local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local function load()
	return dofile("lua/util/format_files.lua")
end

-- Stubs vim.system. `handler(argv)` returns stdout and an optional exit code.
local function with_git(handler, fn)
	local saved = vim.system
	local calls = {}
	vim.system = function(argv)
		table.insert(calls, table.concat(argv, " "))
		local stdout, code = handler(argv)
		return {
			wait = function()
				return { code = code or 0, stdout = stdout or "" }
			end,
		}
	end
	local ok, err = pcall(fn, calls)
	vim.system = saved
	if not ok then
		error(err)
	end
end

local function nul(...)
	local out = ""
	for _, p in ipairs({ ... }) do
		out = out .. p .. "\0"
	end
	return out
end

-- argv opens with `-c core.quotepath=false`, so match the known verbs.
local VERBS = { ["rev-parse"] = true, diff = true, ["ls-files"] = true }

local function subcommand(argv)
	for _, a in ipairs(argv) do
		if VERBS[a] then
			return a
		end
	end
end

T["root"] = new_set()

T["root"]["strips the trailing newline"] = function()
	with_git(function()
		return "/home/u/repo\n"
	end, function()
		expect.equality(load().root(), "/home/u/repo")
	end)
end

T["root"]["is nil outside a repo"] = function()
	with_git(function()
		return "", 128
	end, function()
		expect.equality(load().root(), nil)
	end)
end

T["staged"] = new_set()

T["staged"]["asks git for index-vs-HEAD names only"] = function()
	with_git(function()
		return nul("a.py")
	end, function(calls)
		load().staged()
		local argv = calls[1]
		expect.equality(argv:find("diff", 1, true) ~= nil, true)
		expect.equality(argv:find("--cached", 1, true) ~= nil, true)
		expect.equality(argv:find("--name-only", 1, true) ~= nil, true)
		expect.equality(argv:find("--diff-filter=d", 1, true) ~= nil, true)
		-- One git call. Untracked files cannot be staged.
		expect.equality(#calls, 1)
	end)
end

T["staged"]["splits NUL-separated paths"] = function()
	with_git(function()
		return nul("lua/a.lua", "src/with space.cpp", "b.py")
	end, function()
		expect.equality(load().staged(), { "lua/a.lua", "src/with space.cpp", "b.py" })
	end)
end

T["staged"]["is empty with nothing staged"] = function()
	with_git(function()
		return ""
	end, function()
		expect.equality(load().staged(), {})
	end)
end

T["staged"]["is empty when git fails"] = function()
	with_git(function()
		return nul("a.py"), 128
	end, function()
		expect.equality(load().staged(), {})
	end)
end

T["changed"] = new_set()

T["changed"]["combines tracked changes with untracked files"] = function()
	with_git(function(argv)
		if subcommand(argv) == "diff" then
			return nul("tracked.lua")
		end
		return nul("brand_new.lua")
	end, function(calls)
		expect.equality(load().changed(), { "tracked.lua", "brand_new.lua" })
		expect.equality(#calls, 2)
		expect.equality(calls[1]:find("--cached", 1, true), nil)
	end)
end

T["changed"]["reports a path listed twice only once"] = function()
	with_git(function()
		return nul("dup.lua")
	end, function()
		expect.equality(load().changed(), { "dup.lua" })
	end)
end

T["format"] = new_set()

local function run_format(scope, handler)
	local mod
	local captured = {}
	local notes = {}
	local saved_notify = vim.notify
	vim.notify = function(msg)
		table.insert(notes, msg)
	end
	with_git(handler, function()
		mod = load()
		mod.run = function(files, opts)
			captured = { files = files, opts = opts }
		end
		mod.format(scope)
	end)
	vim.notify = saved_notify
	return captured, notes
end

T["format"]["passes the staged set and root to run"] = function()
	local captured = run_format("staged", function(argv)
		if subcommand(argv) == "rev-parse" then
			return "/repo\n"
		end
		return nul("a.py", "b.py")
	end)
	-- run() takes absolute paths.
	expect.equality(captured.files, { "/repo/a.py", "/repo/b.py" })
	expect.equality(captured.opts.root, "/repo")
	expect.equality(captured.opts.title, "Format staged")
	expect.equality(captured.opts.id, "format_staged")
end

T["format"]["says so and runs nothing with an empty index"] = function()
	local captured, notes = run_format("staged", function(argv)
		if subcommand(argv) == "rev-parse" then
			return "/repo\n"
		end
		return ""
	end)
	expect.equality(captured.files, nil)
	expect.equality(notes[1], "No staged changes to format")
end

T["format"]["refuses outside a git repo"] = function()
	local captured, notes = run_format("changed", function()
		return "", 128
	end)
	expect.equality(captured.files, nil)
	expect.equality(notes[1], "Not in a git repo")
end

T["under"] = new_set()

T["under"]["a file is its own list"] = function()
	local mod
	with_git(function()
		return ""
	end, function(calls)
		mod = load()
		expect.equality(mod.under("/etc/hostname"), { "/etc/hostname" })
		expect.equality(#calls, 0)
	end)
end

T["under"]["a directory gives its changed files from git, nothing walked"] = function()
	-- under() checks vim.fn.isdirectory, so the directory must exist.
	local dir = vim.fn.tempname()
	vim.fn.mkdir(dir, "p")
	MiniTest.finally(function()
		vim.fn.delete(dir, "d")
	end)

	with_git(function(argv)
		local verb = subcommand(argv)
		if verb == "rev-parse" then
			return "/repo\n"
		elseif verb == "diff" then
			return nul("one.lua", "deep/two.lua")
		end
		return nul("new.lua", "one.lua")
	end, function(calls)
		local files = load().under(dir)
		expect.equality(files, { dir .. "/one.lua", dir .. "/deep/two.lua", dir .. "/new.lua" })
		local diff, others = calls[#calls - 1], calls[#calls]
		expect.equality(diff:find("diff --relative --name-only --diff-filter=d", 1, true) ~= nil, true)
		expect.equality(others:find("ls-files --others --exclude-standard", 1, true) ~= nil, true)
	end)
end

T["under"]["outside a repo a directory gives nothing"] = function()
	local dir = vim.fn.tempname()
	vim.fn.mkdir(dir, "p")
	vim.fn.writefile({ "x" }, dir .. "/a.lua")
	MiniTest.finally(function()
		vim.fn.delete(dir, "rf")
	end)
	with_git(function()
		return "", 128
	end, function()
		expect.equality(load().under(dir), {})
	end)
end

T["format_paths"] = new_set()

T["format_paths"]["dedupes overlapping selections"] = function()
	local captured
	local saved_notify = vim.notify
	vim.notify = function() end
	with_git(function()
		return ""
	end, function()
		local mod = load()
		mod.under = function(p)
			return p == "/a" and { "/a/x.lua", "/a/y.lua" } or { "/a/x.lua" }
		end
		mod.run = function(files, opts)
			captured = { files = files, opts = opts }
		end
		mod.format_paths({ "/a", "/a/x.lua" }, "Format selection")
	end)
	vim.notify = saved_notify
	expect.equality(captured.files, { "/a/x.lua", "/a/y.lua" })
	expect.equality(captured.opts.title, "Format selection")
end

T["format_paths"]["says so when the selection has no changed files"] = function()
	local ran = false
	local notes = {}
	local saved_notify = vim.notify
	vim.notify = function(msg)
		table.insert(notes, msg)
	end
	with_git(function()
		return ""
	end, function()
		local mod = load()
		mod.under = function()
			return {}
		end
		mod.run = function()
			ran = true
		end
		mod.format_paths({ "/empty" })
	end)
	vim.notify = saved_notify
	expect.equality(ran, false)
	expect.equality(notes[1], "No changed files there")
end

T["format_paths"]["while a format runs, says so and asks nothing"] = function()
	local F = load()
	local progress = require("util.format_progress")
	local saved_active, saved_status = progress.active, progress.status
	local saved_confirm, saved_notify = vim.fn.confirm, vim.notify
	local asked, note = false, nil
	progress.active = function()
		return true
	end
	progress.status = function()
		return "Formatting 12/40"
	end
	vim.fn.confirm = function()
		asked = true
		return 1
	end
	vim.notify = function(msg)
		note = msg
	end
	F.format_paths({ "/tmp" }, "x")
	progress.active, progress.status = saved_active, saved_status
	vim.fn.confirm, vim.notify = saved_confirm, saved_notify
	expect.equality(asked, false)
	expect.equality(note, "Still formatting: Formatting 12/40")
end

T["sync_with_disk"] = new_set()

-- The sleep gives the rewrite a later mtime.
local function open_then_rewrite(edit_buffer)
	local path = vim.fn.tempname()
	vim.fn.writefile({ "old" }, path)
	local buf = vim.fn.bufadd(path)
	vim.fn.bufload(buf)
	if edit_buffer then
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "mine" })
	end
	vim.uv.sleep(1100)
	vim.fn.writefile({ "from disk" }, path)
	return buf, path
end

T["sync_with_disk"]["takes the disk version of an unmodified buffer"] = function()
	local saved = vim.o.autoread
	vim.o.autoread = false
	local buf, path = open_then_rewrite(false)
	local reason = load().sync_with_disk(buf)
	vim.o.autoread = saved

	expect.equality(reason, nil)
	expect.equality(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { "from disk" })
	vim.api.nvim_buf_call(buf, function()
		vim.cmd("silent noautocmd write")
	end)
	expect.equality(vim.fn.readfile(path), { "from disk" })
end

T["sync_with_disk"]["leaves a buffer with its own edits alone"] = function()
	local buf, path = open_then_rewrite(true)
	expect.equality(load().sync_with_disk(buf), "conflict")
	expect.equality(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { "mine" })
	expect.equality(vim.fn.readfile(path), { "from disk" })
end

T["sync_with_disk"]["a conflict can take the incoming version"] = function()
	local buf, path = open_then_rewrite(true)
	local mod = load()
	expect.equality(mod.sync_with_disk(buf), "conflict")
	expect.equality(mod.reload_from_disk(buf), true)
	expect.equality(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { "from disk" })
	expect.equality(vim.bo[buf].modified, false)
	vim.api.nvim_buf_call(buf, function()
		vim.cmd("silent noautocmd write")
	end)
	expect.equality(vim.fn.readfile(path), { "from disk" })
end

T["sync_with_disk"]["a conflict can keep the buffer version"] = function()
	local buf, path = open_then_rewrite(true)
	expect.equality(load().sync_with_disk(buf), "conflict")
	vim.api.nvim_buf_call(buf, function()
		vim.cmd("silent noautocmd write!")
	end)
	expect.equality(vim.fn.readfile(path), { "mine" })
end

T["sync_with_disk"]["is a no-op when nothing changed"] = function()
	local path = vim.fn.tempname()
	vim.fn.writefile({ "same" }, path)
	local buf = vim.fn.bufadd(path)
	vim.fn.bufload(buf)
	expect.equality(load().sync_with_disk(buf), nil)
	expect.equality(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { "same" })
end

T["load_buffer"] = new_set()

-- A file held open by a second Neovim, its swap under a directory of its own. Returns the
-- path and the job, and points 'directory' there until `release` runs.
local function held(stop)
	local dir, path = vim.fn.tempname(), vim.fn.tempname()
	vim.fn.mkdir(dir, "p")
	vim.fn.writefile({ "held" }, path)
	local job = vim.fn.jobstart({ "nvim", "--clean", "--headless", "--cmd", "set directory=" .. dir .. "//", path })
	-- Polled with a blocking sleep: vim.wait would let the runner's `qa!` in mid-run.
	for _ = 1, 100 do
		if #vim.fn.glob(dir .. "/*.swp", false, true) > 0 then
			break
		end
		vim.uv.sleep(50)
	end
	local saved = vim.o.directory
	vim.o.directory = dir .. "//"
	if stop then
		vim.fn.jobstop(job)
		vim.fn.jobwait({ job }, 2000)
	end
	return path, dir, function()
		vim.o.directory = saved
		vim.fn.jobstop(job)
	end
end

T["load_buffer"]["loads a file with no swap"] = function()
	local path = vim.fn.tempname()
	vim.fn.writefile({ "free" }, path)
	expect.equality(load().load_buffer(path, vim.fn.bufadd(path)), "loaded")
end

-- Loads a held file with the banner answering `choice`, a 1-based button.
local function answered(choice, batch)
	local path, dir, release = held(false)
	local saved = vim.fn.confirm
	local asked = 0
	vim.fn.confirm = function()
		asked = asked + 1
		return choice
	end
	local status, why = load().load_buffer(path, vim.fn.bufadd(path), batch)
	vim.fn.confirm = saved
	local swaps = vim.fn.glob(dir .. "/*.swp", false, true)
	release()
	return status, asked, why, swaps
end

T["load_buffer"]["Delete it removes the other Neovim's swap and loads"] = function()
	local status, asked, _, swaps = answered(1)
	expect.equality(asked, 1)
	expect.equality(status, "loaded")
	for _, swap in ipairs(swaps) do
		expect.equality(vim.fn.swapinfo(swap).pid, vim.fn.getpid())
	end
end

T["load_buffer"]["Skip leaves it, naming the PID"] = function()
	local status, _, why = answered(3)
	expect.equality(status, "skip")
	expect.equality(why:find("open in another Neovim, PID", 1, true) ~= nil, true)
end

T["load_buffer"]["Delete all answers every later file without asking"] = function()
	local batch = {}
	answered(2, batch)
	expect.equality(batch.answer, "delete")
	local status, asked = answered(3, batch)
	expect.equality(asked, 0)
	expect.equality(status, "loaded")
end

T["load_buffer"]["Skip all answers every later file without asking"] = function()
	local batch = {}
	answered(4, batch)
	expect.equality(batch.answer, "skip")
	local status, asked = answered(1, batch)
	expect.equality(asked, 0)
	expect.equality(status, "skip")
end

T["load_buffer"]["Abort stops the run"] = function()
	expect.equality((answered(5)), "abort")
end

T["load_buffer"]["deletes the swap of a Neovim that is gone, and loads"] = function()
	local path, dir, release = held(true)
	local status = load().load_buffer(path, vim.fn.bufadd(path))
	local left = vim.fn.glob(dir .. "/*.swp", false, true)
	release()
	expect.equality(status, "loaded")
	-- Only this session's own swap is left.
	expect.equality(vim.fn.swapinfo(left[1]).pid, vim.fn.getpid())
end

return T
