local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

T["handle_swap"] = new_set()

T["handle_swap"]["dead process auto-deletes swap"] = function()
	local handler = dofile("lua/util/swap_handler.lua")
	local result = handler.handle_swap("/tmp/.test.swp", {
		swapinfo = function() return { pid = 99999 } end,
		fs_stat = function() return nil end, -- dead process
		notify = function() end,
	})
	expect.equality(result, "d")
end

T["handle_swap"]["no PID shows confirm, user picks Edit"] = function()
	local handler = dofile("lua/util/swap_handler.lua")
	local result = handler.handle_swap("/tmp/.test.swp", {
		swapinfo = function() return { pid = 0 } end,
		confirm = function() return 1 end, -- Edit
		notify = function() end,
	})
	expect.equality(result, "e")
end

T["handle_swap"]["live process shows confirm, user picks Read-only"] = function()
	local handler = dofile("lua/util/swap_handler.lua")
	local result = handler.handle_swap("/tmp/.test.swp", {
		swapinfo = function() return { pid = 1 } end,
		fs_stat = function() return {} end, -- PID 1 always alive
		confirm = function() return 2 end, -- Read-only
		notify = function() end,
	})
	expect.equality(result, "o")
end

T["handle_swap"]["live process shows confirm, user picks Delete"] = function()
	local handler = dofile("lua/util/swap_handler.lua")
	local result = handler.handle_swap("/tmp/.test.swp", {
		swapinfo = function() return { pid = 1 } end,
		fs_stat = function() return {} end,
		confirm = function() return 3 end, -- Delete swap
		notify = function() end,
	})
	expect.equality(result, "d")
end

T["handle_swap"]["confirm cancelled (Esc) defaults to quit"] = function()
	local handler = dofile("lua/util/swap_handler.lua")
	local result = handler.handle_swap("/tmp/.test.swp", {
		swapinfo = function() return { pid = 1 } end,
		fs_stat = function() return {} end,
		confirm = function() return 0 end, -- Esc
		notify = function() end,
	})
	expect.equality(result, "q")
end

T["handle_swap"]["nil swapinfo returns confirm prompt"] = function()
	local handler = dofile("lua/util/swap_handler.lua")
	local confirmed_msg = nil
	local result = handler.handle_swap("/tmp/.test.swp", {
		swapinfo = function() return {} end,
		confirm = function(msg) confirmed_msg = msg; return 5 end, -- Abort
		notify = function() end,
	})
	expect.equality(result, "a")
	expect.equality(confirmed_msg, "Swap file exists (PID ?)")
end

return T
