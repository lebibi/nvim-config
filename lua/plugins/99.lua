return {
	"ThePrimeagen/99",
	config = function()
		local ok, _99 = pcall(require, "99")
		if not ok then
			return
		end

		local cwd = vim.uv.cwd() or vim.fn.getcwd()
		vim.fn.mkdir(cwd .. "/tmp", "p")

		_99.setup({
			model = "lelelem/QuantTrio/Qwen3-Coder-30B-A3B-Instruct-AWQ",
			logger = {
				level = _99.DEBUG,
				path = "/tmp/" .. vim.fs.basename(cwd) .. ".99.debug",
				print_on_error = true,
			},
			completion = {
				custom_rules = {},
				source = "cmp",
			},
			md_files = { "AGENT.md" },
		})

		local maps = {
			{ "n", "<leader>9f", _99.fill_in_function, "Fill in function" },
			{ "n", "<leader>9F", _99.fill_in_function_prompt, "Fill in function with prompt" },
			{ "v", "<leader>9v", _99.visual, "Visual selection fill in function" },
			{ "v", "<leader>9V", _99.visual_prompt, "Visual selection fill in function with prompt" },
			{ "n", "<leader>9s", _99.stop_all_requests, "Stop all requests" },
			{ "n", "<leader>9l", _99.view_logs, "View logs" },
		}
		for _, m in ipairs(maps) do
			if m[3] then
				vim.keymap.set(m[1], m[2], m[3], { desc = m[4] })
			end
		end
	end,
}
