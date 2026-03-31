-- Checks whether the Neovim config repo (stdpath("config")) is behind upstream.
-- Runs at most once per 24h (cached in stdpath("state")). On a hit, prompts
-- the user with [P]ull / [I]gnore-for-24h / [A]sk-next-launch. All git calls
-- are async; nothing blocks startup.

local M = {}

local STATE_FILE = vim.fn.stdpath("state") .. "/config_update_check_ts"
local INTERVAL_SEC = 24 * 60 * 60

local function read_last_check()
	local f = io.open(STATE_FILE, "r")
	if not f then
		return 0
	end
	local ts = tonumber(f:read("*a")) or 0
	f:close()
	return ts
end

local function write_last_check()
	local f = io.open(STATE_FILE, "w")
	if f then
		f:write(tostring(os.time()))
		f:close()
	end
end

-- on_done(true) → timestamp recorded; (false) → ask again next launch
local function pull(cfg_dir, on_done)
	vim.notify("Pulling Neovim config…", vim.log.levels.INFO)
	vim.system({ "git", "-C", cfg_dir, "pull", "--ff-only" }, { text = true }, function(r)
		vim.schedule(function()
			if r.code == 0 then
				vim.notify("Config updated. Restart Neovim to apply.", vim.log.levels.INFO)
				on_done(true)
			else
				vim.notify(
					"Config pull failed:\n" .. (r.stderr ~= "" and r.stderr or r.stdout or "unknown error"),
					vim.log.levels.ERROR
				)
				on_done(false)
			end
		end)
	end)
end

local function prompt(cfg_dir, _, on_done)
	vim.schedule(function()
		local msg = "Neovim config differs from upstream"
		local choice = vim.fn.confirm(msg, "&Pull\n&Ignore for 24h\n&Ask next launch", 1)
		if choice == 1 then -- Pull
			pull(cfg_dir, on_done)
		elseif choice == 2 then -- Ignore for 24h
			on_done(true)
		else -- Ask next launch (or dismissed)
			on_done(false)
		end
	end)
end

function M.check()
	if os.time() - read_last_check() < INTERVAL_SEC then
		return
	end

	local cfg_dir = vim.fn.stdpath("config")
	if not vim.uv.fs_stat(cfg_dir .. "/.git") then
		return
	end

	vim.system({ "git", "-C", cfg_dir, "fetch", "--quiet" }, { text = true }, function(fr)
		if fr.code ~= 0 then
			return -- network or auth failure; ask again next launch
		end
		vim.system(
			{ "git", "-C", cfg_dir, "rev-parse", "HEAD", "@{upstream}" },
			{ text = true },
			function(cr)
				if cr.code ~= 0 then
					return -- no upstream / detached HEAD; ask again next launch
				end
				local shas = vim.split(vim.trim(cr.stdout or ""), "\n")
				if shas[1] == shas[2] then
					write_last_check() -- up to date, suppress for 24h
				else
					prompt(cfg_dir, 1, function(ok)
						if ok then
							write_last_check()
						end
					end)
				end
			end
		)
	end)
end

return M
