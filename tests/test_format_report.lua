local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local function load()
	return dofile("lua/util/format_report.lua")
end

local function result(over)
	return vim.tbl_extend("force", {
		formatted = 0,
		total = 0,
		errors = {},
		skipped = {},
		no_formatter = {},
	}, over or {})
end

T["build"] = new_set()

T["build"]["clean run is a single line"] = function()
	expect.equality(load().build(result({ formatted = 4, total = 4 })), "Formatted 4/4 files")
end

T["build"]["one path per row, not a paragraph"] = function()
	local out = load().build(result({
		formatted = 1,
		total = 3,
		no_formatter = { { path = "a.txt" }, { path = "b.txt" } },
	}))
	expect.equality(
		out,
		table.concat({
			"Formatted 1/3 files",
			"",
			"No formatter (2)",
			"  a.txt",
			"  b.txt",
		}, "\n")
	)
end

T["build"]["skips are grouped by reason"] = function()
	local out = load().build(result({
		total = 3,
		skipped = {
			{ path = "logo.png", reason = "binary" },
			{ path = "model.bin", reason = "too large", detail = "12.4 MiB" },
			{ path = "icon.ico", reason = "binary" },
		},
	}))
	expect.equality(
		out,
		table.concat({
			"Formatted 0/3 files",
			"",
			"Skipped — binary (2)",
			"  logo.png",
			"  icon.ico",
			"",
			"Skipped — too large (1)",
			"  model.bin (12.4 MiB)",
		}, "\n")
	)
end

T["build"]["equal-sized groups sort alphabetically"] = function()
	local out = load().build(result({
		skipped = {
			{ path = "z.bin", reason = "too large", detail = "2.0 MiB" },
			{ path = "a.png", reason = "binary" },
		},
	}))
	local order = {}
	for line in out:gmatch("[^\n]+") do
		local reason = line:match("^Skipped — (.-) %(")
		if reason then
			table.insert(order, reason)
		end
	end
	expect.equality(order, { "binary", "too large" })
end

T["build"]["errors come first and keep their message"] = function()
	local out = load().build(result({
		total = 2,
		errors = { { path = "src/x.py", detail = "timeout" } },
		skipped = { { path = "big.bin", reason = "too large", detail = "9.0 MiB" } },
	}))
	expect.equality(
		out,
		table.concat({
			"Formatted 0/2 files",
			"",
			"Errors (1)",
			"  src/x.py (timeout)",
			"",
			"Skipped — too large (1)",
			"  big.bin (9.0 MiB)",
		}, "\n")
	)
end

T["level"] = new_set()

T["level"]["errors outrank skips"] = function()
	local r = load()
	expect.equality(
		r.level(result({ errors = { { path = "a" } }, skipped = { { path = "b" } } })),
		vim.log.levels.ERROR
	)
end

T["level"]["skips warn"] = function()
	expect.equality(load().level(result({ skipped = { { path = "b" } } })), vim.log.levels.WARN)
end

T["level"]["clean run is info"] = function()
	expect.equality(load().level(result()), vim.log.levels.INFO)
end

return T
