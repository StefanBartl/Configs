-- luacheck: globals vim
-- terminals/wezterm/tests/keybindings_check.lua
-- Checks the Neovim-aware navigation keys of config/keybindings.lua without WezTerm (stubbed
-- `wezterm` module). Run from this repo's root:
--
--   nvim --headless -u NONE -l terminals/wezterm/tests/keybindings_check.lua
--
-- Prints one line per check and "RESULT ok" / "RESULT failed" (exit code 1 on failure).

local here = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p"):gsub("\\", "/")
local base = here:match("^(.*)/tests/keybindings_check%.lua$")
package.path = base .. "/?.lua;" .. package.path

local failed = false
local function check(name, cond, detail)
	if cond then
		print("ok   " .. name)
	else
		failed = true
		print("FAIL " .. name .. (detail ~= nil and (" -- " .. vim.inspect(detail)) or ""))
	end
end

-- Every `wezterm.action.X(arg)` becomes a table { action = "X", arg = arg }.
local action = setmetatable({}, {
	__index = function(_, name)
		return function(arg)
			return { action = name, arg = arg }
		end
	end,
})
package.loaded["wezterm"] = {
	action = action,
	action_callback = function(fn)
		return { callback = fn }
	end,
	on = function() end,
}

--- Load keybindings.lua (optionally with `shell_panes` changed) and return the CTRL+<h|j|k> callbacks.
---@param shell_panes string|nil
---@return table<string, fun(window: table, pane: table)> callbacks By key name
---@return table calls { is_nvim = integer }
local function load_callbacks(shell_panes)
	local calls = { is_nvim = 0 }
	package.loaded["config.nvim_status"] = {
		is_nvim = function(pane)
			calls.is_nvim = calls.is_nvim + 1
			return pane.nvim == true
		end,
	}
	local source = table.concat(vim.fn.readfile(base .. "/config/keybindings.lua"), "\n")
	if shell_panes then
		-- the table entry (tab-indented, at a line start), not the same words in a comment
		local replaced, n = source:gsub('\n\tshell_panes = "send",', ('\n\tshell_panes = "%s",'):format(shell_panes))
		assert(n == 1, "shell_panes default not found in keybindings.lua")
		source = replaced
	end
	local configure = assert(load(source, "keybindings.lua"))()
	local Config = {}
	configure(Config)
	local callbacks = {}
	for _, key in ipairs(Config.keys) do
		if key.mods == "CTRL" and type(key.action) == "table" and key.action.callback then
			callbacks[key.key] = key.action.callback
		end
	end
	return callbacks, calls
end

local function perform(callback, pane)
	local performed
	local window = {
		perform_action = function(_, act)
			performed = act
		end,
	}
	callback(window, pane)
	return performed
end

-- The directions each key moves to in "navigate" mode (<C-l> is deliberately not bound).
local DIRECTION = { h = "Left", j = "Down", k = "Up" }

-- Default ("send"): every pane gets the key; the pane is not even looked at.
local callbacks, calls = load_callbacks()
local bound = vim.tbl_keys(callbacks)
table.sort(bound)
check(
	"exactly CTRL+h, CTRL+j and CTRL+k are bound (<C-l> stays the shell's)",
	vim.deep_equal(bound, { "h", "j", "k" }),
	bound
)
for _, key in ipairs({ "h", "j", "k" }) do
	local act = perform(callbacks[key], { nvim = true })
	check(
		("send mode: CTRL+%s in a Neovim pane sends %s"):format(key, key),
		act and act.action == "SendKey" and act.arg.key == key and act.arg.mods == "CTRL",
		act
	)
	act = perform(callbacks[key], { nvim = false })
	check(
		("send mode: CTRL+%s in a shell pane sends it too"):format(key),
		act and act.action == "SendKey" and act.arg.key == key,
		act
	)
end
check("send mode: is_nvim (user vars + foreground process) is never evaluated", calls.is_nvim == 0, calls.is_nvim)

-- "navigate": a shell pane moves between WezTerm panes, a Neovim pane still gets the key.
callbacks, calls = load_callbacks("navigate")
for _, key in ipairs({ "h", "j", "k" }) do
	local act = perform(callbacks[key], { nvim = true })
	check(
		("navigate mode: CTRL+%s in a Neovim pane sends %s"):format(key, key),
		act and act.action == "SendKey" and act.arg.key == key,
		act
	)
	act = perform(callbacks[key], { nvim = false })
	check(
		("navigate mode: CTRL+%s in a shell pane moves %s"):format(key, DIRECTION[key]),
		act and act.action == "ActivatePaneDirection" and act.arg == DIRECTION[key],
		act
	)
end
check("navigate mode: is_nvim decides (asked once per press and key, six times)", calls.is_nvim == 6, calls.is_nvim)

print(failed and "RESULT failed" or "RESULT ok")
os.exit(failed and 1 or 0)
