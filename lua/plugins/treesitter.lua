return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		local treesitter = require("nvim-treesitter")

		treesitter.setup({})
		treesitter.install({
			"bash",
			"cpp",
			"dockerfile",
			"helm",
			"html",
			"javascript",
			"json",
			"lua",
			"markdown",
			"markdown_inline",
			"python",
			"query",
			"regex",
			"rust",
			"tsx",
			"typescript",
			"vim",
			"yaml",
		})

		vim.api.nvim_create_autocmd("FileType", {
			pattern = {
				"sh",
				"cpp",
				"dockerfile",
				"helm",
				"html",
				"javascript",
				"json",
				"lua",
				"markdown",
				"python",
				"query",
				"regex",
				"rust",
				"typescriptreact",
				"typescript",
				"vim",
				"yaml",
			},
			callback = function()
				vim.treesitter.start()
			end,
		})
	end,
}
