return {
	"nvim-lualine/lualine.nvim",
	config = function()
		require("lualine").setup({
			options = {
				theme = "auto",
				disabled_filetypes = {
					statusline = { "neo-tree" },
				},
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff", "diagnostics" },
				lualine_c = { "filename" },
				lualine_x = {
					{
						function() return require("noice").api.status.command.get() end,
						cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
						color = { fg = "#ff9e64" },
					},
					{
						function() return require("noice").api.status.mode.get() end,
						cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
						color = { fg = "#ff9e64" },
					},
					{
						function() return require("noice").api.status.search.get() end,
						cond = function() return package.loaded["noice"] and require("noice").api.status.search.has() end,
						color = { fg = "#ff9e64" },
					},
					"encoding",
					"fileformat",
					"filetype",
				},
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
		})
	end,
}
