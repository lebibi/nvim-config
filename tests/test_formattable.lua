local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local function load()
	return dofile("lua/util/formattable.lua")
end

local function reader(content)
	return function()
		return {
			read = function(_, n)
				return content:sub(1, n)
			end,
			close = function() end,
		}
	end
end

local function file(size)
	return function()
		return { type = "file", size = size }
	end
end

T["is_binary"] = new_set()

T["is_binary"]["plain source is text"] = function()
	expect.equality(load().is_binary("local x = 1\n-- comment\tindented\r\n"), false)
end

T["is_binary"]["empty chunk is text"] = function()
	expect.equality(load().is_binary(""), false)
end

T["is_binary"]["NUL byte means binary"] = function()
	expect.equality(load().is_binary("PK\3\4\0\0some zip"), true)
end

T["is_binary"]["form feed alone stays text"] = function()
	expect.equality(load().is_binary(("x"):rep(200) .. "\12" .. ("y"):rep(200)), false)
end

T["is_binary"]["dense control bytes mean binary"] = function()
	expect.equality(load().is_binary(("\1\2\3\4"):rep(50)), true)
end

T["check"] = new_set()

T["check"]["small text file passes"] = function()
	local ok, reason = load().check("/x/main.lua", {
		fs_stat = file(120),
		open = reader("local M = {}\nreturn M\n"),
	})
	expect.equality(ok, true)
	expect.equality(reason, nil)
end

T["check"]["oversized file is skipped without being read"] = function()
	local read_attempted = false
	local ok, reason, detail = load().check("/x/model.bin", {
		fs_stat = file(50 * 1024 * 1024),
		open = function()
			read_attempted = true
			return nil
		end,
	})
	expect.equality(ok, false)
	expect.equality(reason, "too large")
	expect.equality(detail, "50.0 MiB")
	expect.equality(read_attempted, false)
end

T["check"]["max_bytes is honoured"] = function()
	local ok = load().check("/x/big.json", {
		fs_stat = file(2048),
		open = reader("{}"),
		max_bytes = 1024,
	})
	expect.equality(ok, false)
end

T["check"]["binary content is skipped"] = function()
	local ok, reason = load().check("/x/logo.png", {
		fs_stat = file(4096),
		open = reader("\137PNG\r\n\26\n\0\0\0\13IHDR"),
	})
	expect.equality(ok, false)
	expect.equality(reason, "binary")
end

T["check"]["missing path reports gone"] = function()
	local ok, reason = load().check("/x/deleted.lua", {
		fs_stat = function()
			return nil
		end,
	})
	expect.equality(ok, false)
	expect.equality(reason, "gone")
end

T["check"]["directory is not a regular file"] = function()
	local ok, reason, detail = load().check("/x/dir", {
		fs_stat = function()
			return { type = "directory", size = 4096 }
		end,
	})
	expect.equality(ok, false)
	expect.equality(reason, "not a regular file")
	expect.equality(detail, "directory")
end

T["check"]["unreadable path is skipped"] = function()
	local ok, reason = load().check("/x/secret.lua", {
		fs_stat = file(10),
		open = function()
			return nil
		end,
	})
	expect.equality(ok, false)
	expect.equality(reason, "unreadable")
end

return T
