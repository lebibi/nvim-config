return {
	"mrjones2014/smart-splits.nvim",
	lazy = false,
	build = "./kitty/install-kittens.bash",
	opts = {
		at_edge = "stop",
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
		{ "<leader>h", "<cmd>noh<CR>", desc = "Clear search highlights" },
	},
}
