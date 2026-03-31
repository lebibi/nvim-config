return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "modern",
		delay = 500,
		win = {
			border = "rounded",
			padding = { 1, 2 },
		},
	},
	config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)

		wk.add({
			{ "<leader>b", group = "buffer" },
			{ "<leader>c", group = "code" },
			{ "<leader>d", group = "debug/diagnostics" },
			{ "<leader>f", group = "find/file" },
			{ "<leader>g", group = "git" },
			{ "<leader>l", group = "lsp" },
			{ "<leader>q", group = "quit/session" },
			{ "<leader>s", group = "search" },
			{ "<leader>t", group = "toggle" },
			{ "<leader>u", group = "ui" },
			{ "<leader>w", group = "windows" },
			{ "<leader>x", group = "diagnostics/quickfix" },
			{ "[", group = "prev" },
			{ "]", group = "next" },
			{ "g", group = "goto" },
			{ "gr", group = "references" },
			{ "z", group = "fold" },
		})
	end,
}
