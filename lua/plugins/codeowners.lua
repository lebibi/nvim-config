return {
	"rsreimer/codeowners.nvim",
	config = function()
		require("codeowners").setup()
		vim.keymap.set("n", "<leader>co", function()
			local owner = require("codeowners").get_buf_owner()
			vim.notify("Owner: " .. (owner or "none"), vim.log.levels.INFO)
		end, { desc = "Show codeowner" })
	end,
}
