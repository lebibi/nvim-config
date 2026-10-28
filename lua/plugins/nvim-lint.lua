return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		-- Always pass --config. Over stdin, markdownlint-cli2 looks for config in nvim's cwd.
		local md_defaults = vim.fs.joinpath(vim.fn.stdpath("cache"), "markdownlint.json")
		vim.fn.writefile({
			vim.json.encode({
				config = { MD013 = { line_length = 90, code_blocks = false, tables = false } },
			}),
		}, md_defaults)

		local md_project = {
			".markdownlint-cli2.jsonc",
			".markdownlint-cli2.yaml",
			".markdownlint-cli2.yml",
			".markdownlint-cli2.cjs",
			".markdownlint-cli2.mjs",
			".markdownlint.json",
			".markdownlint.jsonc",
			".markdownlint.yaml",
			".markdownlint.yml",
		}

		local function markdownlint_args(bufnr)
			local fname = vim.api.nvim_buf_get_name(bufnr)
			local dir = (fname ~= "" and vim.fs.dirname(fname)) or vim.fn.getcwd()
			local found = vim.fs.find(md_project, { upward = true, path = dir, stop = vim.uv.os_homedir() })[1]
			return { "--config", found or md_defaults, "-" }
		end

		lint.linters_by_ft = {
			python = { "ruff", "mypy" },
			lua = { "luacheck" },
			javascript = { "eslint_d" },
			typescript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			typescriptreact = { "eslint_d" },
			sh = { "shellcheck" },
			bash = { "shellcheck" },
			markdown = { "markdownlint-cli2" },
			yaml = { "yamllint" },
			bzl = { "buildifier" },
			bazel = { "buildifier" },
		}

		lint.linters.buildifier.args = {
			"-lint",
			"warn",
			"-mode",
			"check",
			"-format",
			"json",
			"-type",
			function()
				local fname = vim.fn.expand("%:t"):lower()
				if fname == "module.bazel" then
					return "module"
				elseif vim.endswith(fname, ".bzl") then
					return "bzl"
				elseif fname == "build" or vim.startswith(fname, "build.") or vim.endswith(fname, ".build") then
					return "build"
				elseif
					fname == "workspace"
					or vim.startswith(fname, "workspace.")
					or vim.endswith(fname, ".workspace")
				then
					return "workspace"
				else
					return "default"
				end
			end,
		}

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function(args)
				if not lint.linters_by_ft[vim.bo.filetype] then
					return
				end
				if vim.bo.filetype == "markdown" then
					lint.linters["markdownlint-cli2"].args = markdownlint_args(args.buf)
				end
				lint.try_lint()
			end,
		})

		vim.keymap.set("n", "<leader>cL", function()
			lint.try_lint()
		end, { desc = "Trigger linting" })
	end,
}
