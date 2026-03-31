return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" },
	ft = { "markdown" },
	opts = {},
	keys = {
		{ "<leader>mt", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle markdown rendering" },
		{ "<leader>me", "<cmd>RenderMarkdown enable<cr>", desc = "Enable markdown rendering" },
		{ "<leader>md", "<cmd>RenderMarkdown disable<cr>", desc = "Disable markdown rendering" },
	},
}
