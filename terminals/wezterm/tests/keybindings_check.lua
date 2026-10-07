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

--- Load keybindings.lua (optionally with `shell_panes` changed) and return the CTRL+j callback.
---@param shell_panes string|nil
---@return fun(window: table, pane: table)
---@return table calls { is_nvim = integer }
local function load_callback(shell_panes)
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
	for _, key in ipairs(Config.keys) do
		if key.key == "j" and key.mods == "CTRL" and key.action.callback then
			return key.action.callback, calls
		end
	end
	error("no CTRL+j navigation callback found")
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

-- Default ("send"): every pane gets the key; the pane is not even looked at.
local callback, calls = load_callback()
local act = perform(callback, { nvim = true })
check("send mode: a Neovim pane gets the key", act and act.action == "SendKey" and act.arg.key == "j")
act = perform(callback, { nvim = false })
check("send mode: a shell pane gets the key too", act and act.action == "SendKey")
check("send mode: is_nvim (user vars + foreground process) is never evaluated", calls.is_nvim == 0, calls.is_nvim)

-- "navigate": a shell pane moves between WezTerm panes, a Neovim pane still gets the key.
callback, calls = load_callback("navigate")
act = perform(callback, { nvim = true })
check("navigate mode: a Neovim pane gets the key", act and act.action == "SendKey")
act = perform(callback, { nvim = false })
check(
	"navigate mode: a shell pane moves to the pane below",
	act and act.action == "ActivatePaneDirection" and act.arg == "Down",
	act
)
check("navigate mode: is_nvim decides (asked twice)", calls.is_nvim == 2, calls.is_nvim)

print(failed and "RESULT failed" or "RESULT ok")
os.exit(failed and 1 or 0)
