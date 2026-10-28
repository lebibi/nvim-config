return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" },
	ft = { "markdown" },
	opts = {},
	keys = {
		{ "<leader>um", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle markdown rendering" },
	},
}
