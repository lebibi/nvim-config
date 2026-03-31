return {
	"lewis6991/gitsigns.nvim",
	opts = {
		current_line_blame = true,
		current_line_blame_opts = {
			delay = 300,
		},
		on_attach = function(bufnr)
			local gs = require("gitsigns")
			local map = function(mode, l, r, desc)
				vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
			end

			-- Navigation between hunks
			map("n", "]h", function() gs.nav_hunk("next") end, "Next git hunk")
			map("n", "[h", function() gs.nav_hunk("prev") end, "Prev git hunk")

			-- Restore (reset) hunks
			map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
			map("v", "<leader>gr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset selected lines")
			map("n", "<leader>gR", gs.reset_buffer, "Reset entire buffer")

			-- Preview what changed
			map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")

			-- Blame
			map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
			map("n", "<leader>gB", function() gs.blame() end, "Blame entire file")
		end,
	},
}
