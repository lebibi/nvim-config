return {
	"towolf/vim-helm",
	ft = { "helm", "yaml" },
	config = function()
		vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
			pattern = { "*/templates/*.yaml", "*/templates/*.yml" },
			callback = function()
				vim.bo.filetype = "helm"
			end,
		})

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "helm",
			callback = function()
				vim.bo.shiftwidth = 2
				vim.bo.tabstop = 2
				vim.bo.softtabstop = 2
				vim.bo.expandtab = true
			end,
		})
	end,
}
