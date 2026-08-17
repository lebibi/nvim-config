return {
	"neovim/nvim-lspconfig",
	dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
	config = function()
		require("mason").setup()
		-- automatic_enable defaults to true, which also attaches bzl (Starlark, like
		-- starpls) and ruff (Python, like pyright), so diagnostics arrive twice.
		require("mason-lspconfig").setup({
			ensure_installed = { "pyright", "clangd", "rust_analyzer", "starpls" },
			automatic_enable = { "clangd", "pyright", "rust_analyzer", "starpls" },
		})

		vim.lsp.config.clangd = {
			cmd = {
				"clangd",
				"--background-index",
				-- nvim writes every stderr byte to its log synchronously on the main
				-- thread, and clangd's default logging put 23 MB through it in one run.
				"--log=error",
				-- Keep a cold bazel index from competing with the editor for CPU.
				"--background-index-priority=low",
				"--malloc-trim",
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
						-- bazel-* symlinks hold generated copies of the whole tree, so
						-- pyright indexes the repo several times and completion offers
						-- every copy.
						exclude = { "**/bazel-*", "**/.cache", "**/node_modules", "**/.venv" },
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
			filetypes = { "rust" },
			root_dir = function(bufnr, on_dir)
				local fname = vim.api.nvim_buf_get_name(bufnr)
				local root = vim.fs.root(fname, { "rust-project.json", "Cargo.toml", ".git" })
				if root then
					on_dir(root)
				end
			end,
			settings = {
				["rust-analyzer"] = {
					procMacro = { enable = false },
					cargo = { buildScripts = { enable = false } },
					workspace = { symbol = { search = { limit = 128 } } },
				},
			},
		}

		-- Kill any surviving servers on the way out. nvim exits without waiting for
		-- them (exit_timeout defaults to false) and never checks they went.
		--
		-- Straight at the transport, because nvim's own VimLeavePre handler runs
		-- first and marks clients stopping, so Client:stop() would return early. Not
		-- ExitPre, which also fires on quits that get aborted.
		vim.api.nvim_create_autocmd("VimLeavePre", {
			group = vim.api.nvim_create_augroup("LspReapOnExit", { clear = true }),
			callback = function()
				for _, client in ipairs(vim.lsp.get_clients()) do
					pcall(function()
						client.rpc.terminate()
					end)
				end
			end,
		})

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
		})

		vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show error details" })
		vim.keymap.set("n", "<leader>cd", function()
			local enabled = vim.diagnostic.is_enabled()
			vim.diagnostic.enable(not enabled)
			vim.notify("Diagnostics " .. (enabled and "OFF" or "ON"))
		end, { desc = "Toggle diagnostics (squigglies)" })
	end,
}
