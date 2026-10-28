return {
	"lewis6991/gitsigns.nvim",
	opts = {
		attach_to_untracked = true,
		current_line_blame = true,
		current_line_blame_opts = {
			delay = 300,
		},
	},
	config = function(_, opts)
		local gs = require("gitsigns")
		gs.setup(opts)

		-- Global maps keep <leader>gh a prefix in buffers gitsigns has not attached to.
		local map = function(mode, l, r, desc)
			vim.keymap.set(mode, l, r, { desc = desc })
		end

		map("n", "]h", function()
			gs.nav_hunk("next")
		end, "Next git hunk")
		map("n", "[h", function()
			gs.nav_hunk("prev")
		end, "Prev git hunk")

		map("n", "<leader>ghs", gs.stage_hunk, "Stage hunk (toggles)")
		map("v", "<leader>ghs", function()
			gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, "Stage selected lines")
		map("n", "<leader>ghS", gs.stage_buffer, "Stage entire buffer")

		map("n", "<leader>ghr", gs.reset_hunk, "Reset hunk")
		map("v", "<leader>ghr", function()
			gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, "Reset selected lines")
		map("n", "<leader>ghR", gs.reset_buffer, "Reset entire buffer")

		map("n", "<leader>ghp", gs.preview_hunk, "Preview hunk")
		map("n", "<leader>ghd", gs.diffthis, "Diff against index")
		map("n", "<leader>ghD", function()
			gs.diffthis("~")
		end, "Diff against last commit")

		map("n", "<leader>gb", function()
			gs.blame_line({ full = true })
		end, "Blame line")
		map("n", "<leader>ghB", function()
			gs.blame()
		end, "Blame entire file")
	end,
}
