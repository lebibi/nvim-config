-- Formatters from a project's pre-commit hooks, at the versions pre-commit installed
--
-- A file under a .pre-commit-config.yaml gets exactly the hooks that apply to it.
-- scripts/precommit_formatters.py reads the config under pre-commit's own interpreter.

local M = {}

local SCRIPT = vim.fn.stdpath("config") .. "/scripts/precommit_formatters.py"

-- Per root: the config's mtime, and each file's formatters.
local cache = {}
-- Per root: the config mtime install-hooks last ran for.
local installed = {}

local function python()
	local exe = vim.fn.exepath("pre-commit")
	if exe == "" then
		return nil
	end
	local fd = io.open(vim.fn.resolve(exe), "r")
	local first = fd and fd:read("*l") or ""
	if fd then
		fd:close()
	end
	local interpreter = first:match("^#!%s*(%S+)")
	return interpreter and vim.fn.executable(interpreter) == 1 and interpreter or nil
end

function M.root(path)
	return vim.fs.root(path, ".pre-commit-config.yaml")
end

local function install(root, mtime)
	if installed[root] == mtime then
		return
	end
	installed[root] = mtime
	vim.notify("Installing pre-commit hook environments for " .. vim.fn.fnamemodify(root, ":~"), vim.log.levels.INFO)
	vim.system({ "pre-commit", "install-hooks" }, { cwd = root }, function(result)
		vim.schedule(function()
			cache[root] = nil
			local level = result.code == 0 and vim.log.levels.INFO or vim.log.levels.WARN
			vim.notify("pre-commit install-hooks finished with code " .. result.code, level)
		end)
	end)
end

-- Fills the cache for `files` under `root` in one call.
function M.prefetch(root, files)
	local py = python()
	local stat = vim.uv.fs_stat(root .. "/.pre-commit-config.yaml")
	if not py or not stat then
		return
	end
	local entry = cache[root]
	if not entry or entry.mtime ~= stat.mtime.sec then
		entry = { mtime = stat.mtime.sec, files = {} }
		cache[root] = entry
	end
	if entry.failed then
		return
	end
	local todo = vim.tbl_filter(function(f)
		return entry.files[f] == nil
	end, files)
	if #todo == 0 then
		return
	end
	local result = vim.system(vim.list_extend({ py, SCRIPT, root }, todo), { text = true }):wait()
	local ok, decoded = pcall(vim.json.decode, result.stdout or "")
	if result.code ~= 0 or not ok then
		-- Retried once the config changes.
		entry.failed = true
		vim.notify("pre-commit formatters: " .. vim.trim(result.stderr or ""), vim.log.levels.WARN)
		return
	end
	if decoded.missing then
		install(root, entry.mtime)
	end
	for file, list in pairs(decoded.files) do
		entry.files[file] = list
	end
end

-- Defines conform formatters for `list` and returns their names.
local function register(list)
	local conform = require("conform")
	local names = {}
	for _, f in ipairs(list) do
		if f.builtin then
			table.insert(names, f.builtin)
		else
			local name = "precommit:" .. f.name .. ":" .. f.cmd[1]
			if not conform.formatters[name] then
				local args = {}
				for i = 2, #f.cmd do
					args[#args + 1] = (f.cmd[i]:gsub("{file}", "$FILENAME"))
				end
				conform.formatters[name] = { command = f.cmd[1], args = args, stdin = true }
			end
			table.insert(names, name)
		end
	end
	return names
end

-- The formatter names for `bufnr`, or nil when no project hooks govern it.
function M.formatters(bufnr)
	local path = vim.api.nvim_buf_get_name(bufnr)
	if path == "" then
		return nil
	end
	local root = M.root(path)
	if not root or not python() then
		return nil
	end
	M.prefetch(root, { path })
	local entry = cache[root]
	local list = entry and entry.files[path]
	if list == nil then
		return nil
	end
	return register(list)
end

return M
