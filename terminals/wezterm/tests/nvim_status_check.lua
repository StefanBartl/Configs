-- luacheck: globals vim utf8
-- terminals/wezterm/tests/nvim_status_check.lua
-- Checks config/nvim_status.lua against the dataset terminal.nvim publishes, without WezTerm:
-- the `wezterm` module is stubbed, panes are plain tables. Run from this repo's root:
--
--   nvim --headless -u NONE -l terminals/wezterm/tests/nvim_status_check.lua
--
-- Prints one line per check and "RESULT ok" / "RESULT failed" (exit code 1 on failure).

-- WezTerm's Lua is 5.4 and has `utf8`; the LuaJIT host of this script does not: a strict validator.
if type(utf8) ~= "table" then
	utf8 = {
		len = function(str)
			local i, n = 1, 0
			while i <= #str do
				local b = str:byte(i)
				local need = b < 0x80 and 0
					or (b >= 0xC2 and b < 0xE0) and 1
					or (b >= 0xE0 and b < 0xF0) and 2
					or (b >= 0xF0 and b < 0xF5) and 3
					or nil
				if need == nil or i + need > #str then
					return nil
				end
				for k = 1, need do
					local c = str:byte(i + k)
					if c < 0x80 or c >= 0xC0 then
						return nil
					end
				end
				i = i + need + 1
				n = n + 1
			end
			return n
		end,
	}
end

package.loaded["wezterm"] = {
	json_parse = function(s)
		return vim.json.decode(s)
	end,
}
local here = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p"):gsub("\\", "/")
local base = here:match("^(.*)/tests/nvim_status_check%.lua$")
package.path = base .. "/?.lua;" .. package.path
local ns = require("config.nvim_status")

local failed = false
local function check(name, cond, detail)
	if cond then
		print("ok   " .. name)
	else
		failed = true
		print("FAIL " .. name .. (detail ~= nil and (" -- " .. vim.inspect(detail)) or ""))
	end
end

local function dataset(over)
	return vim.json.encode(vim.tbl_extend("force", {
		v = 1,
		pid = 1,
		mode = "n",
		file = "a.lua",
		ft = "lua",
		cwd = "/p",
		branch = "main",
		e = 2,
		w = 1,
		i = 0,
		h = 0,
		rec = "",
		mod = true,
	}, over or {}))
end

-- A `Pane` object (update-status, key callbacks): methods.
local function pane_object(vars, process)
	return {
		get_user_vars = function()
			return vars
		end,
		get_foreground_process_name = function()
			return process
		end,
	}
end

-- A `PaneInformation` snapshot (format-tab-title): fields, no methods.
local function pane_info(vars, process)
	return { user_vars = vars, foreground_process_name = process }
end

local live = { MUX_NVIM = "1", MUX_STATUS = dataset() }

check("a Pane object is read", ns.read(pane_object(live, "C:\\nvim.exe")) ~= nil)
check("a PaneInformation snapshot is read too (the tab title path)", ns.read(pane_info(live, "C:\\nvim.exe")) ~= nil)
local st = ns.read(pane_info(live, "C:\\nvim.exe"))
check("the tab title is built from it", st and ns.tab_title(st) == "a.lua + E2 W1", st and ns.tab_title(st))

check("no MUX_NVIM, no status", ns.read(pane_info({ MUX_STATUS = dataset() }, "nvim")) == nil)
check(
	"a higher dataset version is ignored",
	ns.read(pane_info({ MUX_NVIM = "1", MUX_STATUS = dataset({ v = 2 }) }, "nvim")) == nil
)
check("garbage shows nothing", ns.read(pane_info({ MUX_NVIM = "1", MUX_STATUS = "{nope" }, "nvim")) == nil)

-- Foreground process: a Neovim inside tmux / ssh / wsl is not the foreground process itself.
for _, proc in ipairs({ "/usr/bin/tmux", "C:\\Windows\\System32\\wsl.exe", "/usr/bin/ssh" }) do
	check("a wrapper counts as Neovim: " .. proc, ns.read(pane_object(live, proc)) ~= nil)
end
check("a plain shell does not (a Neovim that died without clearing)", ns.read(pane_object(live, "C:\\pwsh.exe")) == nil)
check("is_nvim sees a wrapper too", ns.is_nvim(pane_object(live, "/usr/bin/tmux")) == true)
check("is_nvim works on a snapshot", ns.is_nvim(pane_info(live, "nvim")) == true)

-- Mode chips: the control-character modes arrive spelled out.
local function chip(mode)
	local items =
		ns.right_status(ns.read(pane_object({ MUX_NVIM = "1", MUX_STATUS = dataset({ mode = mode }) }, "nvim")))
	for _, item in ipairs(items) do
		if
			type(item) == "table"
			and item.Text
			and item.Text:find("%u")
			and not item.Text:find("[EW]%d")
			and not item.Text:find("main")
		then
			return vim.trim(item.Text)
		end
	end
end
check("n -> NORMAL", chip("n") == "NORMAL", chip("n"))
check("^V -> V-BLOCK", chip("^V") == "V-BLOCK", chip("^V"))
check("^Vs -> V-BLOCK", chip("^Vs") == "V-BLOCK", chip("^Vs"))
check("^S -> SELECT", chip("^S") == "SELECT", chip("^S"))
check("nov -> OP-PEND", chip("nov") == "OP-PEND", chip("nov"))
check("no^V -> OP-PEND", chip("no^V") == "OP-PEND", chip("no^V"))
check("ntT -> TERM-N", chip("ntT") == "TERM-N", chip("ntT"))
check("niI -> NORMAL", chip("niI") == "NORMAL", chip("niI"))
check("Vs -> V-LINE", chip("Vs") == "V-LINE", chip("Vs"))

-- Free text: cut at a character boundary, invalid UTF-8 shows nothing.
-- One ASCII byte in front: the 120-byte limit then falls INSIDE a 3-byte character (without it
-- the limit is a multiple of 3 and the cut is on a boundary whatever the code does).
local euro = "a" .. string.rep("\226\130\172", 100)
local cut = ns.read(pane_object({ MUX_NVIM = "1", MUX_STATUS = dataset({ file = euro }) }, "nvim"))
check(
	"an overlong name is cut without splitting a character",
	cut and utf8.len(cut.file) ~= nil and #cut.file <= 120,
	cut and #cut.file
)
local broken = ns.read(pane_object({ MUX_NVIM = "1", MUX_STATUS = dataset({ file = "a\195" }) }, "nvim"))
check("invalid UTF-8 shows nothing for that field", broken and broken.file == "", broken and broken.file)
local ctl = ns.read(pane_object({ MUX_NVIM = "1", MUX_STATUS = dataset({ file = "x\27[31my" }) }, "nvim"))
check("control characters become ?", ctl and ctl.file == "x?[31my", ctl and ctl.file)

print(failed and "RESULT failed" or "RESULT ok")
os.exit(failed and 1 or 0)
