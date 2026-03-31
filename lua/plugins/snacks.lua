return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		scroll = { enabled = false },
		bigfile = { enabled = true },
		notifier = {
			enabled = true,
			timeout = 3000,
		},
		quickfile = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = true },
		git = { enabled = true },
		gitbrowse = { enabled = true },
		dashboard = {
			enabled = true,
			sections = {
				{ section = "header" },
				{ section = "keys", gap = 1, padding = 1 },
				{ section = "startup" },
			},
		},
		input = { enabled = true },
		styles = {
			notification = {
				wo = { wrap = true },
				border = "rounded",
			},
		},
	},
	keys = {
		{ "<leader>un", function() require("snacks").notifier.hide() end, desc = "Dismiss All Notifications" },
		{ "<leader>bd", function() require("snacks").bufdelete() end, desc = "Delete Buffer" },
		{ "<leader>gg", function() require("snacks").lazygit() end, desc = "Lazygit" },
		{ "<leader>gb", function() require("snacks").git.blame_line() end, desc = "Git Blame Line" },
		{ "<leader>gB", function() require("snacks").gitbrowse() end, desc = "Git Browse" },
		{ "<leader>gf", function() require("snacks").lazygit.log_file() end, desc = "Lazygit Current File History" },
		{ "<leader>gl", function() require("snacks").lazygit.log() end, desc = "Lazygit Log" },
		{ "<leader>cR", function() require("snacks").rename.rename_file() end, desc = "Rename File" },
		{ "<c-/>", function() require("snacks").terminal() end, desc = "Toggle Terminal" },
		{ "<c-_>", function() require("snacks").terminal() end, desc = "Toggle Terminal (alternative)" },
	},
	config = function(_, opts)
		require("snacks").setup(opts)
		vim.api.nvim_create_user_command("Bd", function() require("snacks").bufdelete() end, {})
		vim.cmd("cabbrev bd Bd")
	end,
	init = function()
		vim.api.nvim_create_autocmd("User", {
			pattern = "VeryLazy",
			callback = function()
				_G.dd = function(...)
					require("snacks").debug.inspect(...)
				end
				_G.bt = function()
					require("snacks").debug.backtrace()
				end
				vim.print = _G.dd
			end,
		})
	end,
}
