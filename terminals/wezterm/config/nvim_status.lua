-- config/nvim_status.lua
-- Shows what a Neovim running in a pane is doing: tab title and right status from the
-- per-pane user variables that terminal.nvim publishes (OSC 1337 SetUserVar).
--
-- Contract (see terminal.nvim, docs/ and lua/terminal/status/exporters/wezterm.lua):
--   MUX_NVIM    "1" while a Neovim with terminal.nvim runs in the pane, "" after it left
--   MUX_PIPE    that Neovim's RPC address (for control from outside; not used here)
--   MUX_STATUS  the dataset as JSON: { v, pid, mode, file, ft, cwd, branch, e, w, i, h, rec, mod }
--
-- Everything read from the pane is untrusted text (file names, branch names): it is
-- sanitised again here, and a malformed or oversized value shows nothing instead of failing.
--
-- Usage from the config:
--   local nvim_status = require("config.nvim_status")
--   local st = nvim_status.read(pane)            -- nil when no Neovim status is available
--   if st then title = nvim_status.tab_title(st) end
--   window:set_right_status(wezterm.format(nvim_status.right_status(st)))

local wezterm = require("wezterm")

local M = {}

--- Options; override with `M.setup({ ... })`.
M.opts = {
	-- The newest dataset version understood here. A higher one is ignored (shows nothing).
	max_version = 1,
	-- Refuse a MUX_STATUS value longer than this many bytes.
	max_bytes = 2048,
	-- Also require that the pane's foreground process looks like Neovim. Catches a Neovim that
	-- died without clearing its variables (the user vars would otherwise stay forever).
	require_nvim_process = true,
	-- Names the foreground process may have (lowercase, substring match).
	process_names = { "nvim" },
	-- Mode code (first letters of Neovim's mode) -> label and ANSI colour for the right status.
	modes = {
		n = { "NORMAL", "Blue" },
		i = { "INSERT", "Green" },
		v = { "VISUAL", "Fuchsia" },
		V = { "V-LINE", "Fuchsia" },
		["\22"] = { "V-BLOCK", "Fuchsia" },
		s = { "SELECT", "Fuchsia" },
		R = { "REPLACE", "Red" },
		c = { "COMMAND", "Yellow" },
		t = { "TERMINAL", "Aqua" },
		nt = { "TERM-N", "Aqua" },
		no = { "OP-PEND", "Blue" },
	},
	-- Segment switches for the right status.
	show_mode = true,
	show_branch = true,
	show_diagnostics = true,
	show_recording = true,
	-- Icon prefixes; set to "" for none. (Needs a font with the Nerd symbols for the default.)
	branch_icon = " ",
}

--- Override options.
---@param opts table|nil
function M.setup(opts)
	for k, v in pairs(opts or {}) do
		M.opts[k] = v
	end
end

---@param s any
---@param max integer
---@return string
local function clean(s, max)
	if type(s) ~= "string" then
		return ""
	end
	s = s:gsub("[%z\1-\31\127]", "?")
	if #s > max then
		s = s:sub(1, max)
	end
	return s
end

---@param n any
---@return integer
local function count(n)
	if type(n) ~= "number" or n ~= n or n < 0 then
		return 0
	end
	return math.min(math.floor(n), 99999)
end

--- Whether the pane's foreground process looks like Neovim.
---@param pane any
---@return boolean
local function process_is_nvim(pane)
	local ok, name = pcall(function()
		return pane:get_foreground_process_name()
	end)
	if not ok or type(name) ~= "string" or name == "" then
		-- Unknown (remote domain, no permission): do not hide a status that may be right.
		return true
	end
	name = name:lower()
	for _, want in ipairs(M.opts.process_names) do
		if name:find(want, 1, true) then
			return true
		end
	end
	return false
end

--- The status of the Neovim in `pane`, or nil.
---@param pane any
---@return table|nil
function M.read(pane)
	local ok, vars = pcall(function()
		return pane:get_user_vars()
	end)
	if not ok or type(vars) ~= "table" then
		return nil
	end
	if vars.MUX_NVIM ~= "1" then
		return nil
	end
	local raw = vars.MUX_STATUS
	if type(raw) ~= "string" or raw == "" or #raw > M.opts.max_bytes then
		return nil
	end
	local parsed_ok, data = pcall(wezterm.json_parse, raw)
	if not parsed_ok or type(data) ~= "table" then
		return nil
	end
	if type(data.v) ~= "number" or data.v > M.opts.max_version then
		return nil
	end
	if M.opts.require_nvim_process and not process_is_nvim(pane) then
		return nil
	end
	return {
		mode = clean(data.mode, 4),
		file = clean(data.file, 120),
		ft = clean(data.ft, 40),
		cwd = clean(data.cwd, 200),
		branch = clean(data.branch, 80),
		e = count(data.e),
		w = count(data.w),
		i = count(data.i),
		h = count(data.h),
		rec = clean(data.rec, 4),
		mod = data.mod == true,
	}
end

--- Whether the pane runs a Neovim that publishes status (for key handling).
---@param pane any
---@return boolean
function M.is_nvim(pane)
	local ok, vars = pcall(function()
		return pane:get_user_vars()
	end)
	return ok and type(vars) == "table" and vars.MUX_NVIM == "1" and process_is_nvim(pane)
end

--- The text for a tab title: file name, a `+` when modified, error/warning counts.
---@param st table
---@return string
function M.tab_title(st)
	local parts = { st.file ~= "" and st.file or "nvim" }
	if st.mod then
		parts[#parts + 1] = "+"
	end
	if st.e > 0 then
		parts[#parts + 1] = "E" .. st.e
	end
	if st.w > 0 then
		parts[#parts + 1] = "W" .. st.w
	end
	return table.concat(parts, " ")
end

---@param mode string
---@return string label
---@return string color
local function mode_chip(mode)
	local m = M.opts.modes[mode] or M.opts.modes[mode:sub(1, 1)]
	if m then
		return m[1], m[2]
	end
	return mode:upper(), "Silver"
end

--- Items for `wezterm.format()`: mode chip, branch, diagnostics, recording.
---@param st table|nil
---@return table items Empty when `st` is nil
function M.right_status(st)
	local items = {}
	if not st then
		return items
	end
	local o = M.opts
	if o.show_recording and st.rec ~= "" then
		items[#items + 1] = { Foreground = { AnsiColor = "Red" } }
		items[#items + 1] = { Text = " REC @" .. st.rec .. " " }
	end
	if o.show_diagnostics and (st.e + st.w + st.i + st.h) > 0 then
		if st.e > 0 then
			items[#items + 1] = { Foreground = { AnsiColor = "Red" } }
			items[#items + 1] = { Text = " E" .. st.e }
		end
		if st.w > 0 then
			items[#items + 1] = { Foreground = { AnsiColor = "Yellow" } }
			items[#items + 1] = { Text = " W" .. st.w }
		end
		items[#items + 1] = { Text = " " }
	end
	if o.show_branch and st.branch ~= "" then
		items[#items + 1] = { Foreground = { AnsiColor = "Silver" } }
		items[#items + 1] = { Text = " " .. o.branch_icon .. st.branch .. " " }
	end
	if o.show_mode and st.mode ~= "" then
		local label, color = mode_chip(st.mode)
		items[#items + 1] = { Foreground = { AnsiColor = color } }
		items[#items + 1] = { Attribute = { Intensity = "Bold" } }
		items[#items + 1] = { Text = " " .. label .. " " }
		items[#items + 1] = "ResetAttributes"
	end
	return items
end

return M
