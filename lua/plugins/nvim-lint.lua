return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			python = { "flake8", "mypy" },
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
			"-lint", "warn",
			"-mode", "check",
			"-format", "json",
			"-type", function()
				local fname = vim.fn.expand("%:t"):lower()
				if fname == "module.bazel" then
					return "module"
				elseif vim.endswith(fname, ".bzl") then
					return "bzl"
				elseif fname == "build" or vim.startswith(fname, "build.") or vim.endswith(fname, ".build") then
					return "build"
				elseif fname == "workspace" or vim.startswith(fname, "workspace.") or vim.endswith(fname, ".workspace") then
					return "workspace"
				else
					return "default"
				end
			end,
		}

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				if lint.linters_by_ft[vim.bo.filetype] then
					lint.try_lint()
				end
			end,
		})

		vim.keymap.set("n", "<leader>cL", function()
			lint.try_lint()
		end, { desc = "Trigger linting" })
	end,
}
