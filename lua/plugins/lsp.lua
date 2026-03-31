return {
	"neovim/nvim-lspconfig",
	dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
	config = function()
		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = { "pyright", "clangd", "rust_analyzer", "starpls" },
			handlers = {
				function(server_name)
					vim.lsp.enable(server_name)
				end,
			},
		})

		vim.lsp.config.clangd = {
			cmd = {
				"clangd",
				"--background-index",
				"--fallback-style=webkit",
				"--query-driver=/usr/bin/clang++",
				"--clang-tidy",
				"--all-scopes-completion",
				"--completion-style=detailed",
				"--header-insertion=iwyu",
				"--pch-storage=memory",
			},
			root_markers = { "compile_commands.json", ".clangd", "WORKSPACE", "MODULE.bazel", ".git" },
			filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
			init_options = {
				fallbackFlags = { "-std=c++20", "-xc++", "-Wall", "-Wextra" },
			},
		}

		vim.lsp.config.pyright = {
			cmd = { "pyright-langserver", "--stdio" },
			root_markers = {
				{ "pyrightconfig.json", "pyproject.toml" },
				{ "setup.py", "setup.cfg", "requirements.txt" },
				{ "WORKSPACE", "WORKSPACE.bazel", "MODULE.bazel" },
				".git",
			},
			filetypes = { "python" },
			settings = {
				python = {
					analysis = {
						autoSearchPaths = true,
						useLibraryCodeForTypes = true,
						diagnosticMode = "workspace",
					},
				},
			},
		}

		vim.lsp.config.starpls = {
			cmd = { "starpls" },
			root_markers = { "MODULE.bazel", "WORKSPACE.bazel", "WORKSPACE" },
			filetypes = { "bzl" },
			settings = {
				starpls = {
					bazel = { path = "/usr/bin/bazelisk" },
				},
			},
		}

		vim.lsp.config.rust_analyzer = {
			cmd = { "rust-analyzer" },
			root_markers = { "rust-project.json", "Cargo.toml", ".git" },
			filetypes = { "rust" },
			settings = {
				["rust-analyzer"] = {
					procMacro = { enable = false },
					cargo = { buildScripts = { enable = false } },
					workspace = { symbol = { search = { limit = 128 } } },
				},
			},
		}

		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(event)
				local bufmap = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, desc = desc })
				end
				bufmap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", "Go to declaration")
				bufmap("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", "Go to implementation")
				bufmap("n", "grt", "<cmd>lua vim.lsp.buf.type_definition()<cr>", "Go to type definition")
				bufmap("n", "gO", "<cmd>lua vim.lsp.buf.document_symbol()<cr>", "Document symbols")
				bufmap({ "n", "x" }, "gq", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", "Format code")
				bufmap({ "i", "s" }, "<C-s>", "<cmd>lua vim.lsp.buf.signature_help()<cr>", "Signature help")
			end,
		})

		vim.diagnostic.config({
			virtual_text = { prefix = "■" },
			float = { border = "rounded" },
		})

		vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show error details" })
	end,
}
