-- Summary notification after a bulk format.

local M = {}

function M.level(result)
	if #result.errors > 0 then
		return vim.log.levels.ERROR
	end
	if #result.skipped > 0 then
		return vim.log.levels.WARN
	end
	return vim.log.levels.INFO
end

local function row(entry)
	local detail = entry.detail
	if detail and detail ~= "" then
		return ("  %s (%s)"):format(entry.path, detail)
	end
	return "  " .. entry.path
end

-- Largest group first, ties alphabetical.
local function by_reason(entries)
	local groups, order = {}, {}
	for _, e in ipairs(entries) do
		local reason = e.reason or "skipped"
		if not groups[reason] then
			groups[reason] = {}
			table.insert(order, reason)
		end
		table.insert(groups[reason], e)
	end
	table.sort(order, function(a, b)
		if #groups[a] ~= #groups[b] then
			return #groups[a] > #groups[b]
		end
		return a < b
	end)
	return groups, order
end

function M.build(result)
	local lines = { ("Formatted %d/%d files"):format(result.formatted, result.total) }

	local function section(label, entries)
		if #entries == 0 then
			return
		end
		table.insert(lines, "")
		table.insert(lines, ("%s (%d)"):format(label, #entries))
		for _, e in ipairs(entries) do
			table.insert(lines, row(e))
		end
	end

	section("Errors", result.errors)

	local groups, order = by_reason(result.skipped)
	for _, reason in ipairs(order) do
		section("Skipped — " .. reason, groups[reason])
	end

	section("No formatter", result.no_formatter)

	return table.concat(lines, "\n")
end

return M
