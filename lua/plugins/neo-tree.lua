return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
		{
			"s1n7ax/nvim-window-picker",
			version = "2.*",
			opts = {
				highlights = {
					statusline = {
						focused = { fg = "#ffffff", bg = "#e35e4f", bold = true },
						unfocused = { fg = "#ffffff", bg = "#44579b", bold = true },
					},
					winbar = {
						focused = { fg = "#ffffff", bg = "#e35e4f", bold = true },
						unfocused = { fg = "#ffffff", bg = "#44579b", bold = true },
					},
				},
				filter_rules = {
					autoselect_one = true,
					include_current_win = false,
					bo = {
						filetype = { "neo-tree", "neo-tree-popup", "notify" },
						buftype = { "terminal", "quickfix" },
					},
				},
			},
		},
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
				},
				mappings = {
					["<space>"] = "none",
					["<cr>"] = "open",
					["w"] = "open_with_window_picker",
					["<esc>"] = "cancel",
					["P"] = { "toggle_preview", config = { use_float = true, use_image_nvim = true } },
					["l"] = "open",
					["h"] = "close_node",
					["z"] = "none",
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
					-- Vim fold-style commands (from neo-tree#445)
					neotree_zo = function(state)
						local node = state.tree:get_node()
						if node and node.type == "directory" and not node:is_expanded() then
							require("neo-tree.sources.filesystem").toggle_directory(state, node, nil, true, false)
						end
						require("neo-tree.ui.renderer").redraw(state)
					end,
					neotree_zO = function(state)
						local node = state.tree:get_node()
						if not node then return end
						local stack = { node }
						while next(stack) ~= nil do
							local n = table.remove(stack)
							if n.type == "directory" and not n:is_expanded() then
								require("neo-tree.sources.filesystem").toggle_directory(state, n, nil, true, false)
							end
							local children = state.tree:get_nodes(n:get_id())
							for _, v in ipairs(children) do
								table.insert(stack, v)
							end
						end
						require("neo-tree.ui.renderer").redraw(state)
					end,
					neotree_zc = function(state)
						local node = state.tree:get_node()
						if not node then return end
						if node:has_children() and node:is_expanded() then
							node:collapse()
						else
							local parent = state.tree:get_node(node:get_parent_id())
							if parent and parent:is_expanded() then
								parent:collapse()
								require("neo-tree.ui.renderer").focus_node(state, parent:get_id())
							end
						end
						require("neo-tree.ui.renderer").redraw(state)
					end,
					neotree_zC = function(state)
						local node = state.tree:get_node()
						if not node then return end
						while node and node:get_depth() >= 2 do
							if node:has_children() and node:is_expanded() then
								node:collapse()
							end
							node = state.tree:get_node(node:get_parent_id())
						end
						require("neo-tree.ui.renderer").redraw(state)
					end,
					neotree_za = function(state)
						local node = state.tree:get_node()
						if not node then return end
						if node.type == "directory" and not node:is_expanded() then
							require("neo-tree.sources.filesystem").toggle_directory(state, node, nil, true, false)
						elseif node:has_children() and node:is_expanded() then
							node:collapse()
						end
						require("neo-tree.ui.renderer").redraw(state)
					end,
					neotree_zM = function(state)
						local stack = state.tree:get_nodes()
						while next(stack) ~= nil do
							local node = table.remove(stack)
							if node:has_children() and node:is_expanded() then
								node:collapse()
							end
							local children = state.tree:get_nodes(node:get_id())
							for _, v in ipairs(children) do
								table.insert(stack, v)
							end
						end
						require("neo-tree.ui.renderer").redraw(state)
					end,
					neotree_zR = function(state)
						local stack = state.tree:get_nodes()
						while next(stack) ~= nil do
							local node = table.remove(stack)
							if node.type == "directory" and not node:is_expanded() then
								require("neo-tree.sources.filesystem").toggle_directory(state, node, nil, true, false)
							end
							local children = state.tree:get_nodes(node:get_id())
							for _, v in ipairs(children) do
								table.insert(stack, v)
							end
						end
						require("neo-tree.ui.renderer").redraw(state)
					end,
					next_git_changed = function(state)
						local renderer = require("neo-tree.ui.renderer")
						local lookup = state.git_status_lookup or {}
						local cur = state.tree:get_node()
						local cur_id = cur and cur:get_id() or ""
						local found = 0
						local target = vim.v.count1
						-- Walk all visible nodes in order
						local nodes = state.tree:get_nodes()
						local all = {}
						local function collect(list)
							for _, node in ipairs(list) do
								table.insert(all, node)
								if node:is_expanded() then
									collect(state.tree:get_nodes(node:get_id()))
								end
							end
						end
						collect(nodes)
						local past_current = false
						for _, node in ipairs(all) do
							if node:get_id() == cur_id then
								past_current = true
							elseif past_current and lookup[node:get_id()] then
								found = found + 1
								if found >= target then
									renderer.focus_node(state, node:get_id())
									return
								end
							end
						end
					end,
					prev_git_changed = function(state)
						local renderer = require("neo-tree.ui.renderer")
						local lookup = state.git_status_lookup or {}
						local cur = state.tree:get_node()
						local cur_id = cur and cur:get_id() or ""
						local nodes = state.tree:get_nodes()
						local all = {}
						local function collect(list)
							for _, node in ipairs(list) do
								table.insert(all, node)
								if node:is_expanded() then
									collect(state.tree:get_nodes(node:get_id()))
								end
							end
						end
						collect(nodes)
						-- Collect all git-changed nodes before current
						local candidates = {}
						for _, node in ipairs(all) do
							if node:get_id() == cur_id then break end
							if lookup[node:get_id()] then
								table.insert(candidates, node)
							end
						end
						local idx = #candidates - vim.v.count1 + 1
						if idx >= 1 then
							renderer.focus_node(state, candidates[idx]:get_id())
						end
					end,
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
						["[g"] = { "prev_git_changed", desc = "Prev git change" },
						["]g"] = { "next_git_changed", desc = "Next git change" },
						["zg"] = { "expand_git_modified", desc = "Expand git modified" },
						["zo"] = { "neotree_zo", desc = "Open fold" },
						["zO"] = { "neotree_zO", desc = "Open fold recursively" },
						["zc"] = { "neotree_zc", desc = "Close fold" },
						["zC"] = { "neotree_zC", desc = "Close all parent folds" },
						["za"] = { "neotree_za", desc = "Toggle fold" },
						["zM"] = { "neotree_zM", desc = "Collapse all" },
						["zR"] = { "neotree_zR", desc = "Expand all" },
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
