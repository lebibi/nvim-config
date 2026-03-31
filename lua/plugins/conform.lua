return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>cf",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = "",
			desc = "Format buffer",
		},
		{
			"<leader>cF",
			function()
				local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
				if vim.v.shell_error ~= 0 then
					vim.notify("Not in a git repo", vim.log.levels.ERROR)
					return
				end
				-- modified (staged + unstaged) and untracked files
				local files = vim.fn.systemlist("git diff --name-only HEAD 2>/dev/null")
				local untracked = vim.fn.systemlist("git ls-files --others --exclude-standard")
				vim.list_extend(files, untracked)

				-- deduplicate
				local seen = {}
				local unique = {}
				for _, f in ipairs(files) do
					if not seen[f] then
						seen[f] = true
						table.insert(unique, f)
					end
				end

				local formatted = 0
				local current_buf = vim.api.nvim_get_current_buf()
				for _, rel_path in ipairs(unique) do
					local path = git_root .. "/" .. rel_path
					if vim.fn.filereadable(path) == 1 then
						-- check if conform has a formatter for this file
						local buf = vim.fn.bufadd(path)
						vim.fn.bufload(buf)
						local ft = vim.filetype.match({ buf = buf }) or ""
						local formatters = require("conform").list_formatters_for_buffer(buf)
						if #formatters > 0 then
							require("conform").format({ bufnr = buf, async = false, lsp_fallback = true, timeout_ms = 2000 })
							vim.api.nvim_buf_call(buf, function()
								vim.cmd("silent! write")
							end)
							formatted = formatted + 1
						end
						-- close buffer if it wasn't already open
						if buf ~= current_buf and not vim.tbl_contains(
							vim.fn.getbufinfo({ buflisted = 1 }),
							function(b) return b.bufnr == buf end
						) then
							-- only wipe if we loaded it fresh (not listed before)
						end
					end
				end
				vim.notify("Formatted " .. formatted .. "/" .. #unique .. " modified files")
			end,
			desc = "Format all git-modified files",
		},
	},
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "isort", "black" },
			rust = { "rustfmt" },
			javascript = { "prettier" },
			typescript = { "prettier" },
			javascriptreact = { "prettier" },
			typescriptreact = { "prettier" },
			json = { "prettier" },
			yaml = { "prettier" },
			markdown = { "prettier" },
			html = { "prettier" },
			css = { "prettier" },
			scss = { "prettier" },
			sh = { "shfmt" },
			bash = { "shfmt" },
			c = { "clang_format" },
			cpp = { "clang_format" },
			bzl = { "buildifier" },
			bazel = { "buildifier" },
		},
		format_on_save = {
			timeout_ms = 500,
			lsp_fallback = true,
		},
		formatters = {
			shfmt = {
				prepend_args = { "-i", "2" },
			},
			clang_format = {
				prepend_args = { "--style=file" },
			},
		},
	},
	init = function()
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}
