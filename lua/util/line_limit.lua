-- Per-filetype line limit, sourced from the project's formatter (or markdown
-- linter) config when present. Sets `textwidth` and `colorcolumn` only — line
-- wrapping is handled by the formatter on save (conform.nvim), never while
-- typing. Also strips `t`/`c` from `formatoptions` to override the stdlib
-- ftplugins that opt-in to auto-wrap behavior.

local M = {}

local function read(path)
	if not path then
		return nil
	end
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local c = f:read("*a")
	f:close()
	return c
end

local function find_up(names, start)
	return vim.fs.find(names, { upward = true, path = start, stop = vim.uv.os_homedir() })[1]
end

-- Reads `path` and returns the first Lua-pattern capture that matches as a
-- number. Each pattern must capture a single digit run.
local function extract(path, ...)
	local c = read(path)
	if not c then
		return nil
	end
	for _, pat in ipairs({ ... }) do
		local n = c:match(pat)
		if n then
			return tonumber(n)
		end
	end
	return nil
end

-- TOML lookup: optionally narrow to `[section]` first, then match `key = N`.
-- Good enough for rustfmt.toml, stylua.toml, pyproject.toml — not a full parser.
local function from_toml(path, section, key)
	local c = read(path)
	if not c then
		return nil
	end
	local body = c
	if section then
		local s = c:find("%[%s*" .. section:gsub("[%-%.]", "%%%0") .. "%s*%]")
		if not s then
			return nil
		end
		body = c:sub(s, (c:find("\n%[", s + 1) or #c + 1) - 1)
	end
	return tonumber(body:match(key:gsub("[%-_]", "%%%0") .. "%s*=%s*(%d+)"))
end

local prettier_names = {
	".prettierrc",
	".prettierrc.json",
	".prettierrc.yaml",
	".prettierrc.yml",
	".prettierrc.js",
	".prettierrc.cjs",
	"prettier.config.js",
	"prettier.config.cjs",
}

local markdownlint_names = {
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

local function prettier(start)
	return extract(find_up(prettier_names, start), '"printWidth"%s*:%s*(%d+)', "printWidth%s*[:=]%s*(%d+)")
end

local function markdownlint(start)
	local c = read(find_up(markdownlint_names, start))
	if not c then
		return nil
	end
	-- Prefer MD013.line_length; fall back to a bare line-length / line_length key.
	local md = c:find('["\']?MD013["\']?%s*[:=]')
	if md then
		local n = c:sub(md, md + 400):match('["\']?line[_-]length["\']?%s*[:=]%s*(%d+)')
		if n then
			return tonumber(n)
		end
	end
	return tonumber(c:match('["\']?line[_-]length["\']?%s*[:=]%s*(%d+)'))
end

-- Each entry: { fn(start) -> limit|nil, default = N }
local sources = {}
local function add(fts, source)
	for _, ft in ipairs(fts) do
		sources[ft] = source
	end
end

add({ "c", "cpp", "objc", "objcpp", "cuda", "proto" }, {
	fn = function(start)
		return extract(find_up({ ".clang-format", "_clang-format" }, start), "ColumnLimit:%s*(%d+)")
	end,
	default = 80,
})

add({ "python" }, {
	fn = function(start)
		return from_toml(find_up({ "pyproject.toml" }, start), "tool.black", "line-length")
	end,
	default = 88,
})

add({ "rust" }, {
	fn = function(start)
		return from_toml(find_up({ "rustfmt.toml", ".rustfmt.toml" }, start), nil, "max_width")
	end,
	default = 100,
})

add({ "lua" }, {
	fn = function(start)
		return from_toml(find_up({ "stylua.toml", ".stylua.toml" }, start), nil, "column_width")
	end,
	default = 120,
})

add({ "javascript", "typescript", "javascriptreact", "typescriptreact", "json", "yaml", "html", "css", "scss" }, {
	fn = prettier,
	default = 80,
})

add({ "markdown" }, {
	fn = function(start)
		return markdownlint(start) or prettier(start)
	end,
	default = 80,
})

-- Match base_leader plus repeats of its last char and an optional `!`, so we
-- treat `//`, `///`, `//!` (Rust doc comments), `##`, `--` etc. as distinct
-- leaders. Lines with different prefixes won't be merged into one block.
local function leader_pattern(base)
	local last = base:sub(-1)
	return "(" .. vim.pesc(base) .. vim.pesc(last) .. "*!?)"
end

-- Wraps each over-limit comment line *individually*. Original line breaks are
-- preserved — blank-leader lines, list items, indented continuations all stay
-- where they were. Only long lines get broken; short lines are untouched and
-- never merged with neighbours.
function M.wrap_comments(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) or not vim.bo[bufnr].modifiable then
		return
	end
	local ft = vim.bo[bufnr].filetype
	local src = sources[ft]
	if not src then
		return
	end
	-- Skip block-style commentstrings (e.g. `<!-- %s -->`); we only handle
	-- single-line comments here. Prose filetypes like markdown are wrapped
	-- by prettier instead.
	local cs = vim.bo[bufnr].commentstring or ""
	local base = cs:match("^(.-)%s*%%s$")
	if not base or base == "" or cs:find("%%s.") then
		return
	end
	base = vim.trim(base)
	if base == "" then
		return
	end

	local fname = vim.api.nvim_buf_get_name(bufnr)
	local start = (fname ~= "" and vim.fs.dirname(fname)) or vim.fn.getcwd()
	local limit = src.fn(start) or src.default
	if not limit then
		return
	end

	-- Capture: line-indent, comment leader, single space after leader,
	-- content-indent (extra spaces, e.g. `///   A.`), then the actual words.
	local pat = "^(%s*)" .. leader_pattern(base) .. "(%s?)(%s*)(.*)$"
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local out = {}
	local changed = false
	local fmt_disabled = false

	for _, line in ipairs(lines) do
		if line:find("clang-format off", 1, true) then
			fmt_disabled = true
		elseif line:find("clang-format on", 1, true) then
			fmt_disabled = false
		end
		if fmt_disabled or vim.fn.strdisplaywidth(line) <= limit then
			table.insert(out, line)
		else
			local indent, leader, space, content_indent, content = line:match(pat)
			if not indent or not content or content == "" then
				table.insert(out, line)
			else
				-- Continuations reuse the full original prefix including content
				-- indent, so list items / nested blocks stay aligned.
				local prefix = indent .. leader .. (space ~= "" and space or " ") .. content_indent
				local avail = math.max(20, limit - vim.fn.strdisplaywidth(prefix))
				local words = {}
				for w in content:gmatch("%S+") do
					table.insert(words, w)
				end
				if #words == 0 then
					table.insert(out, line)
				else
					local current = words[1]
					for w = 2, #words do
						if #current + 1 + #words[w] <= avail then
							current = current .. " " .. words[w]
						else
							table.insert(out, prefix .. current)
							current = words[w]
						end
					end
					table.insert(out, prefix .. current)
					changed = true
				end
			end
		end
	end

	if not changed then
		return
	end
	local view = vim.api.nvim_win_is_valid(0) and vim.fn.winsaveview() or nil
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, out)
	if view then
		pcall(vim.fn.winrestview, view)
	end
end

function M.apply(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	local ft = vim.bo[bufnr].filetype
	local src = sources[ft]
	if not src then
		return
	end

	local fname = vim.api.nvim_buf_get_name(bufnr)
	local start = (fname ~= "" and vim.fs.dirname(fname)) or vim.fn.getcwd()
	local limit = src.fn(start) or src.default
	if not limit then
		return
	end

	vim.bo[bufnr].textwidth = limit
	for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
		vim.api.nvim_set_option_value("colorcolumn", tostring(limit), { win = win })
	end

	-- No wrap-while-typing. Strip `t` (text auto-wrap) and `c` (comment
	-- auto-wrap) that stdlib ftplugins like rust.vim opt into. The formatter
	-- (conform.nvim, runs on BufWritePre) does the actual wrapping on save.
	local fo = vim.bo[bufnr].formatoptions:gsub("[tc]", "")
	vim.bo[bufnr].formatoptions = fo
end

return M
