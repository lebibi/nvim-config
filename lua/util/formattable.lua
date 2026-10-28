-- Whether the bulk formatter should load a path into a buffer
--
-- bufload on a large or binary file blocks the UI while syntax, treesitter and LSP run.

local M = {}

-- Override with `vim.g.format_all_max_bytes`.
M.default_max_bytes = 1024 * 1024

local SNIFF_BYTES = 4096

-- Control bytes under 0x20 except tab, LF, CR and form feed.
local CTRL_PATTERN = "[\1-\8\11\14-\31]"
local CTRL_RATIO = 0.02

local function human(bytes)
	if bytes >= 1024 * 1024 then
		return ("%.1f MiB"):format(bytes / (1024 * 1024))
	end
	return ("%.1f KiB"):format(bytes / 1024)
end

function M.is_binary(chunk)
	if not chunk or chunk == "" then
		return false
	end
	-- NUL means binary. conform cannot format UTF-16 either.
	if chunk:find("\0", 1, true) then
		return true
	end
	local ctrl = 0
	for _ in chunk:gmatch(CTRL_PATTERN) do
		ctrl = ctrl + 1
	end
	return ctrl / #chunk > CTRL_RATIO
end

-- Returns ok, reason, detail. The report groups rows by reason.
function M.check(path, opts)
	opts = opts or {}
	local fs_stat = opts.fs_stat or vim.uv.fs_stat
	local open = opts.open or io.open
	local max_bytes = opts.max_bytes or vim.g.format_all_max_bytes or M.default_max_bytes

	local stat = fs_stat(path)
	if not stat then
		return false, "gone"
	end
	if stat.type ~= "file" then
		return false, "not a regular file", stat.type
	end
	if stat.size > max_bytes then
		return false, "too large", human(stat.size)
	end

	local fd = open(path, "rb")
	if not fd then
		return false, "unreadable"
	end
	local chunk = fd:read(SNIFF_BYTES) or ""
	fd:close()
	if M.is_binary(chunk) then
		return false, "binary"
	end

	return true
end

return M
