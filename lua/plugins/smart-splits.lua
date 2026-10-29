-- Inside tmux, wrap in tmux passthrough, which needs allow-passthrough on
local function send_to_kitty(seq)
	if vim.env.TMUX then
		seq = "\27Ptmux;" .. seq:gsub("\27", "\27\27") .. "\27\\"
	end
	vim.api.nvim_ui_send(seq)
end

local kitty_edge = { left = "left", right = "right", up = "top", down = "bottom" }

local function move_kitty_window(ctx)
	send_to_kitty(
		string.format(
			'\27P@kitty-cmd{"cmd":"action","version":[0,47,0],"no_response":true,'
				.. '"payload":{"action":"neighboring_window %s","self":true}}\27\\',
			kitty_edge[ctx.direction]
		)
	)
end

-- kitty's pass_keys.py forwards ctrl+hjkl over ssh while IS_NVIM is set
if not vim.env.TMUX then
	local group = vim.api.nvim_create_augroup("kitty_is_nvim", {})
	vim.api.nvim_create_autocmd({ "VimEnter", "VimResume" }, {
		group = group,
		callback = function()
			send_to_kitty("\27]1337;SetUserVar=IS_NVIM=MQ==\7")
		end,
	})
	vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, {
		group = group,
		callback = function()
			send_to_kitty("\27]1337;SetUserVar=IS_NVIM\7")
		end,
	})
end

return {
	"mrjones2014/smart-splits.nvim",
	lazy = false,
	build = "./kitty/install-kittens.bash",
	init = function()
		-- kitty is reached through escape codes, so only tmux is a multiplexer
		vim.g.smart_splits_multiplexer_integration = vim.env.TMUX and "tmux" or false
	end,
	opts = {
		at_edge = move_kitty_window,
	},
	keys = {
		{
			"<c-h>",
			function()
				require("smart-splits").move_cursor_left()
			end,
			desc = "Go to left split",
		},
		{
			"<c-j>",
			function()
				require("smart-splits").move_cursor_down()
			end,
			desc = "Go to below split",
		},
		{
			"<c-k>",
			function()
				require("smart-splits").move_cursor_up()
			end,
			desc = "Go to above split",
		},
		{
			"<c-l>",
			function()
				require("smart-splits").move_cursor_right()
			end,
			desc = "Go to right split",
		},
	},
}
