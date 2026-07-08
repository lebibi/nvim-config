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
				local function git(args)
					local r = vim.system(args, { text = false }):wait()
					return r.code, r.stdout or "", r.stderr or ""
				end

				local code, root_out = git({ "git", "rev-parse", "--show-toplevel" })
				if code ~= 0 then
					vim.notify("Not in a git repo", vim.log.levels.ERROR)
					return
				end
				local git_root = vim.trim(root_out)

				local function git_z(extra)
					local argv = { "git", "-c", "core.quotepath=false" }
					vim.list_extend(argv, extra)
					local c, out = git(argv)
					if c ~= 0 or out == "" then
						return {}
					end
					return vim.split(out, "\0", { trimempty = true })
				end

				-- --diff-filter=d (lowercase) excludes deleted paths so we don't
				-- try to format files that no longer exist on disk.
				local files = {}
				vim.list_extend(files, git_z({ "diff", "--name-only", "--diff-filter=d", "-z", "HEAD" }))
				vim.list_extend(files, git_z({ "ls-files", "--others", "--exclude-standard", "-z" }))

				local seen, unique = {}, {}
				for _, f in ipairs(files) do
					if not seen[f] then
						seen[f] = true
						table.insert(unique, f)
					end
				end

				local conform = require("conform")
				local formatted, no_formatter, missing, errored = 0, {}, {}, {}
				for _, rel_path in ipairs(unique) do
					local path = git_root .. "/" .. rel_path
					local stat = vim.uv.fs_stat(path)
					if not stat or stat.type ~= "file" then
						table.insert(missing, rel_path .. (stat and (" (" .. stat.type .. ")") or " (gone)"))
					else
						local buf = vim.fn.bufadd(path)
						vim.fn.bufload(buf)
						if vim.bo[buf].filetype == "" then
							local ft = vim.filetype.match({ buf = buf, filename = path })
							if ft then
								vim.bo[buf].filetype = ft
							end
						end
						local formatters = conform.list_formatters_for_buffer(buf)
						if #formatters == 0 then
							table.insert(no_formatter, rel_path)
						else
							local ok, err = pcall(conform.format, {
								bufnr = buf,
								async = false,
								timeout_ms = 5000,
							})
							if not ok then
								table.insert(errored, rel_path .. ": " .. tostring(err))
							else
								local wrote_ok = pcall(vim.api.nvim_buf_call, buf, function()
									vim.cmd("silent! noautocmd write")
								end)
								if wrote_ok then
									formatted = formatted + 1
								else
									table.insert(errored, rel_path .. ": write failed")
								end
							end
						end
					end
				end

				local parts = { ("Formatted %d/%d files"):format(formatted, #unique) }
				if #missing > 0 then
					table.insert(parts, "Missing: " .. table.concat(missing, ", "))
				end
				if #no_formatter > 0 then
					table.insert(parts, "No formatter: " .. table.concat(no_formatter, ", "))
				end
				if #errored > 0 then
					table.insert(parts, "Errors: " .. table.concat(errored, "; "))
				end
				vim.notify(table.concat(parts, "\n"))
			end,
			desc = "Format all git-modified files",
		},
	},
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "ruff_organize_imports", "ruff_format" },
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
				-- only format C/C++ in projects that ship a .clang-format
				condition = function(_, ctx)
					return vim.fs.root(ctx.filename, ".clang-format") ~= nil
				end,
			},
		},
	},
	init = function()
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}
