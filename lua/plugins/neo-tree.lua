return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("neo-tree").setup({
			close_if_last_window = true, -- Close Neo-tree if it's the last window
			popup_border_style = "rounded",
			enable_git_status = true,
			enable_diagnostics = true,

			-- Better window management
			window = {
				position = "left",
				width = 30,
				mapping_options = {
					noremap = true,
					nowait = true,
				},
				mappings = {
					["<space>"] = "none",
					["<cr>"] = "open",
					["<esc>"] = "cancel",
					["P"] = { "toggle_preview", config = { use_float = true, use_image_nvim = true } },
					["l"] = "open",
					["h"] = "close_node",
					["zc"] = "close_all_nodes",
					["ze"] = "expand_all_nodes",
					["a"] = { "add", config = { show_path = "relative" } },
					["d"] = "delete",
					["r"] = "rename",
					["y"] = "copy_to_clipboard",
					["x"] = "cut_to_clipboard",
					["p"] = "paste_from_clipboard",
					["c"] = "copy",
					["m"] = "move",
					["q"] = "close_window",
					["R"] = "refresh",
					["?"] = "show_help",
				},
			},

			filesystem = {
				filtered_items = {
					visible = false,
					hide_dotfiles = false,
					hide_gitignored = false,
					hide_by_name = {
						"node_modules",
					},
					never_show = {
						".DS_Store",
						"thumbs.db",
					},
				},
				follow_current_file = {
					enabled = false,
					leave_dirs_open = false,
				},
				use_libuv_file_watcher = true, -- Auto-refresh on file changes
				commands = {
					expand_git_modified = function(state)
						local handle = io.popen(string.format(
							"git -C %s status --porcelain 2>/dev/null",
							vim.fn.shellescape(state.path)
						))
						if not handle then return end
						local output = handle:read("*a")
						handle:close()

						local dirs = {}
						for line in output:gmatch("[^\n]+") do
							local file = line:sub(4)
							local arrow = file:find(" -> ", 1, true)
							if arrow then file = file:sub(arrow + 4) end
							file = file:gsub("%s+$", "")
							local current = state.path
							for segment in file:gmatch("([^/]+)/") do
								current = current .. "/" .. segment
								dirs[current] = true
							end
						end
						state.force_open_folders = vim.tbl_keys(dirs)
						require("neo-tree.sources.filesystem").navigate(state, state.path)
					end,
				},
				window = {
					mappings = {
						["<bs>"] = "navigate_up",
						["."] = "set_root",
						["H"] = "toggle_hidden",
						["/"] = "fuzzy_finder",
						["f"] = "filter_on_submit",
						["<c-x>"] = "clear_filter",
						["[g"] = "prev_git_modified",
						["]g"] = "next_git_modified",
						["zg"] = "expand_git_modified",
					},
				},
			},

			buffers = {
				follow_current_file = {
					enabled = true,
					leave_dirs_open = false,
				},
			},

			git_status = {
				window = {
					position = "float",
				},
			},
		})

		-- Follow current file on buffer change (only if neo-tree is already visible)
		local follow_timer = vim.uv.new_timer()
		vim.api.nvim_create_autocmd("BufEnter", {
			group = vim.api.nvim_create_augroup("NeoTreeFollowOnBufChange", { clear = true }),
			callback = function()
				if vim.bo.buftype ~= "" then
					return
				end
				local filepath = vim.api.nvim_buf_get_name(0)
				if filepath == "" then
					return
				end
				-- Debounce: avoids flash when rapidly switching buffers (e.g. opening file from neo-tree)
				follow_timer:stop()
				follow_timer:start(50, 0, vim.schedule_wrap(function()
					-- Only follow in normal mode; skip during search, insert, visual, etc.
					if vim.fn.mode() ~= "n" then return end
					-- Bail if a float is now active (e.g. telescope)
					local cur_win = vim.api.nvim_get_current_win()
					if vim.api.nvim_win_get_config(cur_win).relative ~= "" then return end
					if vim.bo.buftype ~= "" then return end
					local ok, manager = pcall(require, "neo-tree.sources.manager")
					if not ok then return end
					local state = manager.get_state("filesystem")
					local ok2, renderer = pcall(require, "neo-tree.ui.renderer")
					if not ok2 or not renderer.window_exists(state) then return end
					pcall(function()
						require("neo-tree.sources.filesystem").navigate(state, state.path, filepath)
					end)
					-- Restore focus if it shifted (fixes search popup close focusing neo-tree)
					if vim.api.nvim_win_is_valid(cur_win) and vim.api.nvim_get_current_win() ~= cur_win then
						vim.api.nvim_set_current_win(cur_win)
					end
				end))
			end,
		})

		-- Keymaps for neo-tree
		vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { desc = 'Toggle Neo-tree', silent = true })
		vim.keymap.set('n', '<leader>o', ':Neotree focus<CR>', { desc = 'Focus Neo-tree', silent = true })
	end,
}
