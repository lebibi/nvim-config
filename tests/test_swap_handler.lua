local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

T["handle_swap"] = new_set()

local function handle(info, answer, alive)
	local asked
	local result = dofile("lua/util/swap_handler.lua").handle_swap("/tmp/.test.swp", {
		swapinfo = function()
			return info
		end,
		kill = function()
			if alive then
				return 0
			end
			return nil, "ESRCH: no such process", "ESRCH"
		end,
		confirm = function(msg, choices)
			asked = { msg = msg, choices = choices }
			return answer
		end,
		notify = function() end,
	})
	return result, asked
end

T["handle_swap"]["dead process auto-deletes swap"] = function()
	local result, asked = handle({ pid = 99999 }, 1, false)
	expect.equality(result, "d")
	expect.equality(asked, nil)
end

T["handle_swap"]["live process offers Delete it"] = function()
	local result, asked = handle({ pid = 1 }, 4, true)
	expect.equality(result, "d")
	expect.equality(asked.choices:find("&Delete it", 1, true) ~= nil, true)
end

T["handle_swap"]["each answer maps to its swapchoice"] = function()
	for answer, letter in ipairs({ "o", "e", "r", "d", "q", "a" }) do
		expect.equality((handle({ pid = 1 }, answer, true)), letter)
	end
end

T["handle_swap"]["cancelled quits"] = function()
	expect.equality((handle({ pid = 1 }, 0, true)), "q")
end

T["handle_swap"]["no PID asks"] = function()
	local result, asked = handle({ pid = 0 }, 2, false)
	expect.equality(result, "e")
	expect.equality(asked.msg:find("process ID: ?", 1, true) ~= nil, true)
end

T["handle_swap"]["the message carries the swap's details"] = function()
	local _, asked = handle({ pid = 1, fname = "/tmp/robot.yaml", user = "u", host = "h", dirty = 1 }, 1, true)
	expect.equality(asked.msg:find("file name: /tmp/robot.yaml", 1, true) ~= nil, true)
	expect.equality(asked.msg:find("modified: YES", 1, true) ~= nil, true)
	expect.equality(asked.msg:find("process ID: 1 (STILL RUNNING)", 1, true) ~= nil, true)
	expect.equality(asked.msg:sub(-1), "\n")
end

T["orphaned"] = new_set()

T["orphaned"]["an embedded Neovim reparented to init is an orphan"] = function()
	local handler = dofile("lua/util/swap_handler.lua")
	expect.equality(handler.orphaned("46579 (nvim) S 1 46579 0", "nvim\0--embed\0.\0"), true)
end

T["orphaned"]["one whose UI still runs is not"] = function()
	local handler = dofile("lua/util/swap_handler.lua")
	expect.equality(handler.orphaned("46579 (nvim) S 46578 46579 0", "nvim\0--embed\0.\0"), false)
end

T["orphaned"]["a terminal Neovim reparented to init is not"] = function()
	local handler = dofile("lua/util/swap_handler.lua")
	expect.equality(handler.orphaned("46579 (nvim) S 1 46579 0", "nvim\0.\0"), false)
end

T["orphaned"]["a name with spaces and parentheses still parses"] = function()
	local handler = dofile("lua/util/swap_handler.lua")
	expect.equality(handler.orphaned("7 (a (b) c) S 1 7 0", "nvim\0--embed\0"), true)
end

T["alive"] = new_set()

T["alive"]["a missing PID is dead"] = function()
	local handler = dofile("lua/util/swap_handler.lua")
	expect.equality(
		handler.alive(42, function()
			return nil, "ESRCH: no such process", "ESRCH"
		end),
		false
	)
end

T["alive"]["another user's PID is alive"] = function()
	local handler = dofile("lua/util/swap_handler.lua")
	expect.equality(
		handler.alive(42, function()
			return nil, "EPERM: operation not permitted", "EPERM"
		end),
		true
	)
end

T["alive"]["this Neovim is alive"] = function()
	local handler = dofile("lua/util/swap_handler.lua")
	expect.equality(handler.alive(vim.fn.getpid()), true)
end

return T
