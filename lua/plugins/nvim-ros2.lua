return {
	"ErickKramer/nvim-ros2",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	opts = {
		autocmds = true,
		telescope = true,
		treesitter = false, -- handled below; plugin's built-in setup uses removed API
	},
	config = function(_, opts)
		-- Register the ros2 parser with nvim-treesitter before plugin setup
		local parsers = require("nvim-treesitter.parsers")
		local plugin_path
		for _, p in pairs(vim.api.nvim_list_runtime_paths()) do
			if p:match("nvim%-ros2") then
				plugin_path = p
				break
			end
		end
		if plugin_path then
			parsers.ros2 = {
				install_info = {
					url = plugin_path .. "/treesitter-ros2/",
					files = { "src/parser.c" },
					generate_requires_npm = false,
					requires_generate_from_grammar = false,
				},
				filetype = "ros",
			}
			vim.treesitter.language.register("ros2", "ros")
		end

		require("nvim-ros2").setup(opts)
	end,
}
