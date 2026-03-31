return {
	"tpope/vim-sleuth",
	config = function()
		vim.api.nvim_create_autocmd("BufReadPost", {
			pattern = "*",
			callback = function()
				vim.defer_fn(function()
					local buf = vim.api.nvim_get_current_buf()
					local lines = vim.api.nvim_buf_get_lines(buf, 0, 50, false)

					if #lines <= 1 or (lines[1] == "" and #lines == 1) then
						return
					end

					local formatters_present = false
					local root_dir = vim.fn.getcwd()
					local formatter_files = {
						".clang-format", ".clangformat",
						".prettierrc", ".prettierrc.json", ".prettierrc.js",
						"pyproject.toml", "setup.cfg", "tox.ini",
						".eslintrc", ".eslintrc.json", ".eslintrc.js",
						"rustfmt.toml", ".rustfmt.toml",
					}

					for _, file in ipairs(formatter_files) do
						if vim.fn.filereadable(root_dir .. "/" .. file) == 1 then
							formatters_present = true
							break
						end
					end

					if not formatters_present then
						local function clamp(v, fb) return (v < 1 or v > 8) and fb or v end
						vim.bo.shiftwidth = clamp(vim.bo.shiftwidth, 4)
						vim.bo.tabstop = clamp(vim.bo.tabstop, 4)
						vim.bo.softtabstop = clamp(vim.bo.softtabstop, 4)
					end
				end, 100)
			end,
		})
	end,
}
