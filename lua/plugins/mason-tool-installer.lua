return {
	"WhoIsSethDaniel/mason-tool-installer.nvim",
	dependencies = { "williamboman/mason.nvim" },
	opts = {
		ensure_installed = {
			"stylua",
			"isort",
			"black",
			"prettier",
			"shfmt",
			"clang-format",
			"buildifier",
			"flake8",
			"mypy",
			"luacheck",
			"eslint_d",
			"shellcheck",
			"markdownlint-cli2",
			"yamllint",
		},
	},
}
