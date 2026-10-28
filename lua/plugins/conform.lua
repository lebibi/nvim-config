return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>cf",
			function()
				local governed = require("util.project_hooks").formatters(0) ~= nil
				require("conform").format({ async = true, lsp_format = governed and "never" or "fallback" })
			end,
			mode = "",
			desc = "Format buffer",
		},
		{
			"<leader>cF",
			function()
				require("util.format_files").format("changed")
			end,
			desc = "Format all git-modified files",
		},
		{
			"<leader>cS",
			function()
				require("util.format_files").format("staged")
			end,
			desc = "Format files with staged changes",
		},
	},
	opts = function()
		-- A project's pre-commit hooks replace every pick below.
		local hooks = require("util.project_hooks")
		local function governed(bufnr)
			return hooks.formatters(bufnr) ~= nil
		end
		local by_ft = {
			lua = { "stylua" },
			-- Projects that run black in CI must be formatted with black, not
			-- ruff_format: ruff reads [tool.ruff] line-length (often 100) while
			-- black defaults to 88, so ruff-formatted files fail `black --check`.
			python = function(bufnr)
				local name = vim.api.nvim_buf_get_name(bufnr)
				local root = vim.fs.root(name ~= "" and name or vim.uv.cwd(), {
					"pyproject.toml",
					".pre-commit-config.yaml",
					"setup.cfg",
				})
				-- A bare "black" also matches comments, URLs and "blackboard".
				local declares_black = {
					["pyproject.toml"] = { "%[tool%.black%]" },
					[".pre-commit-config.yaml"] = { "id:%s*[\"']?black", "psf/black" },
					["setup.cfg"] = { "%[black%]" },
				}
				for file, patterns in pairs(declares_black) do
					local fd = root and io.open(root .. "/" .. file, "r")
					if fd then
						local content = fd:read("*a")
						fd:close()
						for _, pattern in ipairs(patterns) do
							if content:find(pattern) then
								return { "isort", "black" }
							end
						end
					end
				end
				return { "ruff_organize_imports", "ruff_format" }
			end,
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
		}
		local formatters_by_ft = {}
		for ft, pick in pairs(by_ft) do
			formatters_by_ft[ft] = function(bufnr)
				local project = hooks.formatters(bufnr)
				if project then
					return project
				end
				return type(pick) == "function" and pick(bufnr) or pick
			end
		end
		-- Filetypes listed nowhere above still get the project's hooks.
		formatters_by_ft["_"] = function(bufnr)
			return hooks.formatters(bufnr) or {}
		end
		return {
			formatters_by_ft = formatters_by_ft,
			format_on_save = function(bufnr)
				return { timeout_ms = 2000, lsp_format = governed(bufnr) and "never" or "fallback" }
			end,
			formatters = {
				shfmt = {
					prepend_args = { "-i", "2" },
				},
				-- matches the `isort --profile black` used by pre-commit hooks
				isort = {
					prepend_args = { "--profile", "black" },
				},
				clang_format = {
					prepend_args = { "--style=file" },
					-- only format C/C++ in projects that ship a .clang-format
					condition = function(_, ctx)
						return vim.fs.root(ctx.filename, ".clang-format") ~= nil
					end,
				},
			},
		}
	end,
	init = function()
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}
