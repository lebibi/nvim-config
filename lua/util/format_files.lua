-- Bulk formatter for <leader>cF, <leader>cS and Neo-tree's F

local M = {}

local function git(args)
	local r = vim.system(args, { text = false }):wait()
	return r.code, r.stdout or "", r.stderr or ""
end

local function git_z(extra)
	local argv = { "git", "-c", "core.quotepath=false" }
	vim.list_extend(argv, extra)
	local code, out = git(argv)
	if code ~= 0 or out == "" then
		return {}
	end
	return vim.split(out, "\0", { trimempty = true })
end

local function dedupe(paths)
	local seen, unique = {}, {}
	for _, p in ipairs(paths) do
		if not seen[p] then
			seen[p] = true
			table.insert(unique, p)
		end
	end
	return unique
end

function M.root()
	local code, out = git({ "git", "rev-parse", "--show-toplevel" })
	if code ~= 0 then
		return nil
	end
	return vim.trim(out)
end

-- Staged, unstaged and untracked. Lowercase --diff-filter=d excludes deletions.
function M.changed()
	local files = {}
	vim.list_extend(files, git_z({ "diff", "--name-only", "--diff-filter=d", "-z", "HEAD" }))
	vim.list_extend(files, git_z({ "ls-files", "--others", "--exclude-standard", "-z" }))
	return dedupe(files)
end

function M.staged()
	return dedupe(git_z({ "diff", "--name-only", "--cached", "--diff-filter=d", "-z" }))
end

-- Where Neovim keeps `path`'s swap files, from 'directory'.
--
-- swapfilelist() joins a `//` entry onto itself, so its paths do not open.
local function swap_candidates(path)
	local full = vim.fn.fnamemodify(vim.fn.resolve(path), ":p")
	local found = {}
	for _, entry in ipairs(vim.split(vim.o.directory, ",", { trimempty = true })) do
		local dir, name
		if entry:sub(-2) == "//" then
			dir = vim.fn.expand((entry:gsub("/+$", "")))
			name = (full:gsub("/", "%%"))
		else
			dir = entry == "." and vim.fs.dirname(full) or vim.fn.expand(entry)
			name = "." .. vim.fs.basename(full)
		end
		for _, ext in ipairs({ ".swp", ".swo", ".swn" }) do
			table.insert(found, dir .. "/" .. name .. ext)
		end
	end
	return found
end

local function find_swap_for(path)
	for _, swap in ipairs(swap_candidates(path)) do
		if vim.uv.fs_stat(swap) then
			return swap
		end
	end
end

-- Swap and PID of a live Neovim holding `path`. Deletes a dead process's swap.
function M.held_elsewhere(path)
	local swap = find_swap_for(path)
	if not swap then
		return nil
	end
	local info = vim.fn.swapinfo(swap) or {}
	local pid = info.pid and info.pid ~= 0 and info.pid or nil
	if pid and pid ~= vim.fn.getpid() and require("util.swap_handler").alive(pid) then
		return swap, pid
	end
	if pid and pid ~= vim.fn.getpid() then
		vim.fn.delete(swap)
	end
	return nil
end

-- "Delete all" and "Skip all" answer for every remaining held file.
local BATCH_CHOICES = "&Delete it\nDelete &all\n&Skip\nSkip a&ll\nA&bort"

-- bufload fails with E325 on a swap, and SwapExists does not fire.
function M.load_buffer(path, buf, batch)
	batch = batch or {}
	-- Open in this session: its swap is our own.
	if vim.api.nvim_buf_is_loaded(buf) then
		return "loaded"
	end
	local swap, pid = M.held_elsewhere(path)
	if swap then
		local answer = batch.answer
		if not answer then
			local handler = require("util.swap_handler")
			local info = vim.fn.swapinfo(swap) or {}
			local choice = vim.fn.confirm(handler.describe(swap, info, true), BATCH_CHOICES, 1)
			answer = ({ "delete", "delete all", "skip", "skip all", "abort" })[choice] or "skip"
			if answer == "delete all" or answer == "skip all" then
				answer = answer:sub(1, -5)
				batch.answer = answer
			end
		end
		if answer == "abort" then
			return "abort"
		elseif answer == "skip" then
			return "skip", ("open in another Neovim, PID %d"):format(pid)
		end
		vim.fn.delete(swap)
	end
	local shortmess = vim.o.shortmess
	vim.opt.shortmess:append("A")
	local ok, err = pcall(vim.fn.bufload, buf)
	vim.o.shortmess = shortmess
	return ok and "loaded" or "error", err
end

-- Reload an unmodified buffer from disk. Returns "conflict" or "deleted" when it cannot.
function M.sync_with_disk(buf)
	local reason
	local id = vim.api.nvim_create_autocmd("FileChangedShell", {
		buffer = buf,
		callback = function()
			reason = vim.v.fcs_reason
			vim.v.fcs_choice = reason == "changed" and "reload" or ""
		end,
	})
	pcall(vim.cmd.checktime, buf)
	pcall(vim.api.nvim_del_autocmd, id)
	if reason == "conflict" or reason == "deleted" then
		return reason
	end
end

function M.resolve_conflict(name)
	local choice = vim.fn.confirm(
		("%s changed on disk and has unsaved edits in Neovim.\nFormat which version?"):format(name),
		"&Incoming (disk)\n&Current (buffer)\n&Skip\n&Abort",
		1,
		"Question"
	)
	return ({ "disk", "buffer", "skip", "abort" })[choice] or "skip"
end

function M.reload_from_disk(buf)
	local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
		vim.cmd("silent edit!")
	end)
	return ok, err and tostring(err) or nil
end

-- Every event except FileChangedShell and FileChangedShellPost, which sync_with_disk reads.
local quiet
local function quiet_events()
	if not quiet then
		local keep = { FileChangedShell = true, FileChangedShellPost = true }
		quiet = table.concat(
			vim.tbl_filter(function(event)
				return not keep[event]
			end, vim.fn.getcompletion("", "event")),
			","
		)
	end
	return quiet
end

function M.run(files, opts)
	local conform = require("conform")
	local formattable = require("util.formattable")
	local progress = require("util.format_progress")
	local report = require("util.format_report")

	if progress.active() then
		vim.notify("A bulk format is already running", vim.log.levels.WARN)
		return
	end

	local result = { formatted = 0, total = #files, errors = {}, skipped = {}, no_formatter = {} }
	local batch = {}

	local function display(path)
		if opts.root and path:sub(1, #opts.root + 1) == opts.root .. "/" then
			return path:sub(#opts.root + 2)
		end
		return vim.fn.fnamemodify(path, ":~")
	end

	local function skip(path, reason, detail)
		table.insert(result.skipped, { path = display(path), reason = reason, detail = detail })
	end
	local function fail(path, detail)
		table.insert(result.errors, { path = display(path), detail = tostring(detail) })
	end

	-- Returns false to abort the whole run.
	local function process(path)
		local ok_gate, reason, detail = formattable.check(path)
		if not ok_gate then
			skip(path, reason, detail)
			return true
		end

		local buf = vim.fn.bufadd(path)
		local status, status_err = M.load_buffer(path, buf, batch)
		if status == "abort" then
			return false
		elseif status == "skip" then
			skip(path, "swap file", status_err)
			return true
		elseif status == "error" then
			fail(path, status_err)
			return true
		end

		local stale = M.sync_with_disk(buf)
		local force_write = false
		if stale == "conflict" then
			local pick = M.resolve_conflict(display(path))
			if pick == "disk" then
				local ok_reload, reload_err = M.reload_from_disk(buf)
				if not ok_reload then
					fail(path, reload_err)
					return true
				end
			elseif pick == "buffer" then
				-- write! skips the "changed since reading it" prompt.
				force_write = true
			elseif pick == "abort" then
				return false
			else
				skip(path, "changed on disk and in Neovim")
				return true
			end
		elseif stale then
			skip(path, "gone")
			return true
		end

		if vim.bo[buf].filetype == "" then
			local ft = vim.filetype.match({ buf = buf, filename = path })
			if ft then
				vim.bo[buf].filetype = ft
			end
		end

		local formatters = conform.list_formatters_for_buffer(buf)
		if #formatters == 0 then
			table.insert(result.no_formatter, { path = display(path) })
			return true
		end

		local ok, err = pcall(conform.format, {
			bufnr = buf,
			async = false,
			timeout_ms = 5000,
		})
		if not ok then
			fail(path, err)
			return true
		end

		local wrote_ok = pcall(vim.api.nvim_buf_call, buf, function()
			vim.cmd(force_write and "silent! noautocmd write!" or "silent! noautocmd write")
		end)
		if wrote_ok then
			result.formatted = result.formatted + 1
		else
			fail(path, "write failed")
		end
		return true
	end

	local function finish()
		progress.stop()
		require("util.notify").persistent(report.build(result), {
			id = opts.id,
			title = opts.title,
			level = report.level(result),
		})
	end

	-- One file per tick. A plain loop blocks redraw until it finishes.
	local function step(i)
		if i > #files then
			return finish()
		end
		progress.step(i, display(files[i]))
		vim.defer_fn(function()
			local existing = vim.fn.bufnr(files[i])
			local was_loaded = existing ~= -1 and vim.api.nvim_buf_is_loaded(existing)
			-- Buffer events move Neo-tree's selection and attach LSP and linters.
			local eventignore = vim.o.eventignore
			vim.o.eventignore = quiet_events()
			local ok, keep_going = pcall(process, files[i])
			-- Close the buffers the run opened, and with them their swaps.
			local buf = vim.fn.bufnr(files[i])
			if existing == -1 and buf ~= -1 and not (vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified) then
				pcall(vim.api.nvim_buf_delete, buf, { force = true })
			elseif not was_loaded and buf ~= -1 and vim.api.nvim_buf_is_loaded(buf) and not vim.bo[buf].modified then
				pcall(vim.api.nvim_buf_delete, buf, { unload = true })
			end
			vim.o.eventignore = eventignore
			if not ok then
				fail(files[i], keep_going)
			elseif keep_going == false then
				return finish()
			end
			step(i + 1)
		end, 0)
	end

	-- One pre-commit lookup per project.
	local hooks = require("util.project_hooks")
	local by_root = {}
	for _, path in ipairs(files) do
		local root = hooks.root(path)
		if root then
			by_root[root] = by_root[root] or {}
			table.insert(by_root[root], path)
		end
	end
	for root, list in pairs(by_root) do
		hooks.prefetch(root, list)
	end
	progress.start(#files)
	step(1)
end

-- Changed files under `path`, as `changed` lists them. A file is its own list.
function M.under(path, root)
	if vim.fn.isdirectory(path) == 0 then
		return { path }
	end
	if root == nil then
		root = M.root()
	end
	if not root then
		return {}
	end
	local rel = {}
	vim.list_extend(
		rel,
		git_z({ "-C", path, "diff", "--relative", "--name-only", "--diff-filter=d", "-z", "HEAD", "--", "." })
	)
	vim.list_extend(rel, git_z({ "-C", path, "ls-files", "--others", "--exclude-standard", "-z", "--", "." }))
	local files = {}
	for _, r in ipairs(dedupe(rel)) do
		files[#files + 1] = path .. "/" .. r
	end
	return files
end

local function busy()
	local progress = require("util.format_progress")
	if not progress.active() then
		return false
	end
	vim.notify("Still formatting: " .. progress.status(), vim.log.levels.WARN)
	return true
end

local CONFIRM_ABOVE = 25

function M.format_paths(paths, label)
	if busy() then
		return
	end
	local root = M.root() or false
	local files = {}
	for _, p in ipairs(paths) do
		vim.list_extend(files, M.under(p, root))
	end
	files = dedupe(files)

	if #files == 0 then
		vim.notify(root and "No changed files there" or "Not in a git repo", vim.log.levels.INFO)
		return
	end

	if #files > CONFIRM_ABOVE then
		local what = #paths == 1 and vim.fn.fnamemodify(paths[1], ":~:.") or (#paths .. " selected paths")
		local choice = vim.fn.confirm(("Format %d files under %s?\n"):format(#files, what), "&Format\n&Cancel", 1)
		if choice ~= 1 then
			return
		end
	end

	M.run(files, {
		root = root or nil,
		id = "format_paths",
		title = label or "Format selection",
	})
end

function M.format(scope)
	if busy() then
		return
	end
	local root = M.root()
	if not root then
		vim.notify("Not in a git repo", vim.log.levels.ERROR)
		return
	end
	local files = scope == "staged" and M.staged() or M.changed()
	if #files == 0 then
		local what = scope == "staged" and "No staged changes" or "No modified files"
		vim.notify(what .. " to format", vim.log.levels.INFO)
		return
	end
	for i, rel in ipairs(files) do
		files[i] = root .. "/" .. rel
	end
	M.run(files, {
		root = root,
		id = "format_" .. scope,
		title = scope == "staged" and "Format staged" or "Format all",
	})
end

return M
