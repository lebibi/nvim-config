return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	opts = {
		-- suppress the default "written" msg; we show our own via BufWritePost autocmd
		routes = {
			{
				filter = {
					event = "msg_show",
					find = "written",
				},
				opts = { skip = true },
			},
		},
		lsp = {
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
				["cmp.entry.get_documentation"] = true,
			},
		},
		presets = {
			long_message_to_split = true,
			lsp_doc_border = true,
		},
	},
	config = function(_, opts)
		require("noice").setup(opts)

		-- Neovim does NOT emit search_count messages during incremental search,
		-- only after Enter and during n/N. Compute the count ourselves on each
		-- keystroke and inject it into noice so the virtualtext view shows it live.
		local function update_search_count()
			local cmdtype = vim.fn.getcmdtype()
			if cmdtype ~= "/" and cmdtype ~= "?" then
				return
			end
			local pattern = vim.fn.getcmdline()
			if pattern == "" then
				return
			end
			-- Validate regex before searchcount; partial patterns (e.g. "[", "\(")
			-- cause emsg() internally which Noice intercepts, closing the cmdline.
			if not pcall(vim.regex, pattern) then
				return
			end
			local ok, result = pcall(vim.fn.searchcount, {
				pattern = pattern,
				maxcount = 999,
				timeout = 100,
			})
			if ok and result.total and result.total > 0 then
				local text = string.format("[%d/%d]", result.current, result.total)
				require("noice.ui.msg").on_show("msg_show", "search_count", { { 0, text } })
				pcall(require("noice.message.router").update)
			end
		end

		vim.api.nvim_create_autocmd("CmdlineChanged", {
			callback = update_search_count,
		})

		-- <C-g>/<C-t> navigate matches without changing cmdline text,
		-- so CmdlineChanged doesn't fire. Wrap them to also update the count.
		vim.keymap.set("c", "<C-g>", function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-g>", true, false, true), "n", false)
			vim.schedule(update_search_count)
		end)
		vim.keymap.set("c", "<C-t>", function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-t>", true, false, true), "n", false)
			vim.schedule(update_search_count)
		end)
	end,
}
