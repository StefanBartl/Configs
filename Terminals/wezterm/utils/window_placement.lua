---@module 'config.window_placement'
--- Size/position helpers for spawning and adjusting WezTerm windows.
--- Reuses the same math for gui-startup and custom keybindings.

local wezterm = require("wezterm")

---@class ScreenInfo
---@field x integer
---@field y integer
---@field width integer
---@field height integer

---@class PlacementOpts
---@field width_factor  number?   -- default 0.8
---@field height_factor number?   -- default 0.8
---@field center        boolean?  -- default true
---@field origin        '"ActiveScreen"'|'"MainScreen"'|'"ScreenCoordinateSystem"'|table? -- default "ActiveScreen"

---@param s ScreenInfo
---@param opts PlacementOpts
---@return integer target_w, integer target_h, integer pos_x, integer pos_y, string|table origin
local function compute_geometry(s, opts)
  local wf = tonumber(opts.width_factor) or 0.8
  local hf = tonumber(opts.height_factor) or 0.8
  local center = (opts.center ~= false)
  local target_w = math.floor(s.width * wf)
  local target_h = math.floor(s.height * hf)
  local pos_x, pos_y = s.x, s.y
  if center then
    pos_x = s.x + math.floor((s.width - target_w) / 2)
    pos_y = s.y + math.floor((s.height - target_h) / 2)
  end
  local origin = opts.origin or "ActiveScreen"
  return target_w, target_h, pos_x, pos_y, origin
end

--- Resize + (optional) reposition an existing GUI window.
local function apply_to_window(win, s, opts)
  local target_w, target_h, pos_x, pos_y = compute_geometry(s, opts)
  -- Content size (ohne Deko) exakt setzen
  win:set_inner_size(target_w, target_h)
  pcall(function()
    win:set_position(pos_x, pos_y)
	end)
end

--- Spawn a new window with initial position, then set inner size.
--- @param opts PlacementOpts
local function spawn_sized_window(opts)
  local gui = wezterm.gui
  local mux = wezterm.mux

  -- aktiver Bildschirm als Default
  local screens = gui.screens()
  local s = screens.active

  local _, _, pos_x, pos_y, origin = compute_geometry(s, opts)

  -- 1) Mit Startposition spawnen (Position wird vom WM i. d. R. respektiert; auf Wayland ggf. ignoriert)
  local _, _, mw = mux.spawn_window({
    position = { x = pos_x, y = pos_y, origin = origin },
  })

  -- 2) Danach exakt Inhaltsgröße setzen
  local win = mw:gui_window()
  apply_to_window(win, s, opts)
end

--- Public API
return {
  apply_to_window = apply_to_window,
  spawn_sized_window = spawn_sized_window,
}
