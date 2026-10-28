local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local function load()
	return dofile("lua/util/format_progress.lua")
end

T["status"] = new_set()

T["status"]["is empty while idle"] = function()
	local p = load()
	expect.equality(p.active(), false)
	expect.equality(p.status(), "")
end

T["status"]["reports index, total and current file"] = function()
	local p = load()
	p.start(40)
	p.step(12, "lua/plugins/conform.lua")
	expect.equality(p.active(), true)
	expect.equality(p.status():match("Formatting (%d+/%d+)"), "12/40")
	expect.equality(p.status():find("lua/plugins/conform.lua", 1, true) ~= nil, true)
	p.stop()
	expect.equality(p.active(), false)
end

T["status"]["spinner advances between steps"] = function()
	local p = load()
	p.start(2)
	p.step(1, "a.lua")
	local first = p.status():sub(1, #"⠋")
	p.step(2, "b.lua")
	local second = p.status():sub(1, #"⠋")
	p.stop()
	expect.no_equality(first, second)
end

T["status"]["step on a stopped run is a no-op"] = function()
	local p = load()
	p.step(1, "a.lua")
	expect.equality(p.status(), "")
end

T["shorten"] = new_set()

T["shorten"]["leaves short paths alone"] = function()
	expect.equality(load().shorten("init.lua"), "init.lua")
end

T["shorten"]["keeps the tail of a long path"] = function()
	local out = load().shorten("very/deeply/nested/directory/tree/target_file_name.lua")
	expect.equality(out:sub(1, #"…"), "…")
	expect.equality(out:sub(-#"target_file_name.lua"), "target_file_name.lua")
	expect.equality(vim.fn.strdisplaywidth(out) <= 30, true)
end

T["shorten"]["cuts on a character boundary"] = function()
	local out = load().shorten(("é"):rep(40))
	expect.equality(out, "…" .. ("é"):rep(29))
end

return T
