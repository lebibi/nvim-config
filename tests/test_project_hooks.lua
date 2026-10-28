local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

-- A project root with a config, and a fake pre-commit whose shebang is /bin/sh.
local function project()
	local root = vim.fn.tempname()
	vim.fn.mkdir(root, "p")
	vim.fn.writefile({ "repos: []" }, root .. "/.pre-commit-config.yaml")
	local exe = root .. "/pre-commit"
	vim.fn.writefile({ "#!/bin/sh" }, exe)
	return root, exe
end

-- Stubs vim.system. `script()` returns the helper's stdout and exit code.
local function with_system(exe, script, fn)
	local saved_system, saved_exepath, saved_notify = vim.system, vim.fn.exepath, vim.notify
	local calls = { script = 0, install = 0, notify = 0 }
	vim.fn.exepath = function()
		return exe
	end
	vim.notify = function()
		calls.notify = calls.notify + 1
	end
	vim.system = function(argv, _, on_exit)
		if argv[1] == "pre-commit" then
			calls.install = calls.install + 1
			on_exit({ code = 0 })
			return {}
		end
		calls.script = calls.script + 1
		local stdout, code = script()
		return {
			wait = function()
				return { code = code or 0, stdout = stdout, stderr = "boom" }
			end,
		}
	end
	local ok, err = pcall(fn, calls)
	vim.system, vim.fn.exepath, vim.notify = saved_system, saved_exepath, saved_notify
	if not ok then
		error(err)
	end
end

T["prefetch"] = new_set()

T["prefetch"]["installs once while hooks stay missing"] = function()
	local root, exe = project()
	local hooks = dofile("lua/util/project_hooks.lua")
	with_system(exe, function()
		return vim.json.encode({ missing = true, files = {} })
	end, function(calls)
		for _ = 1, 3 do
			hooks.prefetch(root, { root .. "/a.py" })
			vim.wait(10)
		end
		expect.equality(calls.install, 1)
		expect.equality(calls.script, 3)
	end)
end

T["prefetch"]["a failed lookup is not retried until the config changes"] = function()
	local root, exe = project()
	local hooks = dofile("lua/util/project_hooks.lua")
	with_system(exe, function()
		return "", 1
	end, function(calls)
		hooks.prefetch(root, { root .. "/a.py" })
		hooks.prefetch(root, { root .. "/a.py" })
		expect.equality(calls.script, 1)
		expect.equality(calls.notify, 1)

		vim.uv.fs_utime(root .. "/.pre-commit-config.yaml", os.time() + 10, os.time() + 10)
		hooks.prefetch(root, { root .. "/a.py" })
		expect.equality(calls.script, 2)
	end)
end

return T
