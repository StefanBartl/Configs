---@module 'config.tabtitle'
--- Theme-aware tab titles with:
--- - inner left/right padding per tab
--- - time-based flip (cwd <-> process) independent of user activity
--- - fancy vs retro tab-bar aware rendering (no color override when fancy)
--- - Windows/Unix/WSL-safe CWD extraction and shortening
---
--- IMPORTANT:
--- * WezTerm does not expose libuv; timers are provided via `wezterm.time`.
--- * Avoid multiple returns from gsub() to fix LuaLS "redundant-return-value".
--- * Avoid global `utf8` by doing UTF-8 aware byte-iteration for left-truncation.

local wezterm = require("wezterm")

----------------------------------------------------------------
-- Options
----------------------------------------------------------------

local OPT = {
  -- Flip between modes
  flip_enabled          = true,      -- enable periodic flip
  flip_period_sec       = 5,         -- 7) seconds until toggle
  flip_modes            = { "cwd", "process" },

  -- CWD shortening rules
  cwd_body_len          = 20,        -- 2) ".../last" budget (cells)
  cwd_body_len_parent2  = 25,        -- 2) ".../prev/last" budget (cells)
  max_title_len         = 80,        -- final safety truncation (cells)

  -- Width policy
  fixed_tab_width_enabled = false,   -- 3) false=dyn width; true=fixed width
  fixed_tab_width         = 40,      -- 4) width in cells when fixed
  dynamic_tab_width_max   = 48,      -- 4) max tab width when dynamic

  -- Centering (applies when fixed_tab_width_enabled = true)
  center_cwd             = false,    -- 5) center cwd in fixed-width tabs
  center_process         = false,    -- 6) center process in fixed-width tabs

  -- Spacing
  tab_gap_cells          = 1,        -- gap between tabs (edge width)
  tab_left_pad_cells     = 1,        -- inner left padding
  tab_right_pad_cells    = 1,        -- inner right padding

  -- Optional environment prefix
  show_env_prefix        = false,    -- show [W]/[WSL]/[Linux]

  -- Flip tick for global timer; keeps flip going while idle
  flip_tick_ms           = 1000,
}

----------------------------------------------------------------
-- Utils (single-return safe; UTF-8 aware without global `utf8`)
----------------------------------------------------------------

--- Escape for Lua patterns (single return).
--- @param s string
--- @return string
local function escpat(s)
  return (tostring(s):gsub("([^%w])", "%%%1"))
end

--- Percent-decode without returning substitution count.
--- @param str string|nil
--- @return string
local function url_decode(str)
  if not str then return "" end
  local out = tostring(str)
  out = out:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)
  return out
end

--- Extract display path from file:// URI; supports WSL, Unix, Windows.
--- Never returns "(unknown)"; falls back to the best-effort string.
--- @param uri any
--- @return string
local function extract_path(uri)
  local s = url_decode(uri)
  if s == "" then return "" end
  if not s:match("^file://") then
    return s
  end

  -- WSL: file://wsl%2BNAME/...
  local wsl_path = s:match("^file://wsl[^/]+(/.+)")
  if wsl_path then
    return wsl_path
  end

  -- Unix (hosted / hostless)
  local unix1 = s:match("^file://[^/]+(/.+)")
  if unix1 and not unix1:match("^/[A-Za-z]:/") then
    return unix1
  end
  local unix2 = s:match("^file://(/.+)")
  if unix2 and not unix2:match("^/[A-Za-z]:/") then
    return unix2
  end

  -- Windows: file:///E:/...  or  file://host/E:/...
  local win1 = s:match("^file:///(%a:/.+)")
  if win1 then
    return win1
  end
  local win2 = s:match("^file://[^/]+/(%a:/.+)")
  if win2 then
    return win2
  end

  -- Fallback: strip only the scheme
  local tail = s:gsub("^file://", "")
  return tail
end

--- UTF-8 aware left-truncation by columns without relying on global `utf8`.
--- It iterates bytewise and skips UTF-8 continuation bytes.
--- @param s string
--- @param limit integer  -- target column width
--- @return string
local function truncate_left_cells(s, limit)
  local w = wezterm.column_width(s)
  if w <= limit then
    return s
  end
  local to_remove = w - limit
  local i = 1
  local len = #s
  while i <= len and to_remove > 0 do
    local b = s:byte(i)
    local char_len
    if b < 0x80 then
      char_len = 1
    elseif b < 0xE0 then
      char_len = 2
    elseif b < 0xF0 then
      char_len = 3
    else
      char_len = 4
    end
    local ch = s:sub(i, i + char_len - 1)
    to_remove = to_remove - wezterm.column_width(ch)
    i = i + char_len
  end
  return s:sub(i)
end

--- Fit to exact width cells (truncate right or pad spaces); optional center.
--- @param s string
--- @param width integer
--- @param align "left"|"center"
--- @return string
local function fit_width(s, width, align)
  local w = wezterm.column_width(s)
  if w > width then
    return wezterm.truncate_right(s, width)
  end
  local pad = width - w
  if pad <= 0 then
    return s
  end
  if align == "center" then
    local left = math.floor(pad / 2)
    local right = pad - left
    return string.rep(" ", left) .. s .. string.rep(" ", right)
  else
    return s .. string.rep(" ", pad)
  end
end

--- HOME normalization to "~" (also on Windows via USERPROFILE).
--- @param path string
--- @return string
local function normalize_home(path)
  local home = os.getenv("HOME") or os.getenv("USERPROFILE") or ""
  if home == "" then
    return path
  end
  local nh = home:gsub("\\", "/")
  local np = path:gsub("\\", "/")
  np = np:gsub("^" .. escpat(nh), "~")
  return np
end

--- Split into prefix ("E:/", "~", "/") and parts; slash-normalized.
--- @param path string
--- @return string prefix, string sep, string[] parts
local function split_path(path)
  local p = path:gsub("\\", "/")
  local sep = "/"

  local drive, rest = p:match("^([A-Za-z]:)/(.+)$")
  if drive then
    local parts = {}
    for part in rest:gmatch("[^/]+") do
      parts[#parts + 1] = part
    end
    return (drive .. "/"), sep, parts
  end

  if p:sub(1, 1) == "~" then
    local r = p:sub(2):gsub("^" .. escpat(sep), "")
    local parts = {}
    if r ~= "" then
      for part in r:gmatch("[^/]+") do
        parts[#parts + 1] = part
      end
    end
    return "~", sep, parts
  end

  if p:sub(1, 1) == "/" then
    local r = p:sub(2)
    local parts = {}
    if r ~= "" then
      for part in r:gmatch("[^/]+") do
        parts[#parts + 1] = part
      end
    end
    return "/", sep, parts
  end

  local parts = {}
  for part in p:gmatch("[^/]+") do
    parts[#parts + 1] = part
  end
  return "", sep, parts
end

----------------------------------------------------------------
-- CWD shortening logic
----------------------------------------------------------------

--- Build shortened CWD according to rules:
--- prefix always shown (E:/, ~, /)
--- if ".../prev/last" fits within OPT.cwd_body_len_parent2 -> use that
--- else ".../last" truncated-left to OPT.cwd_body_len
--- @param full_path string
--- @return string
local function shorten_cwd_display(full_path)
  local show = normalize_home(full_path)
  local prefix, sep, parts = split_path(show)
  if #parts == 0 then
    return (prefix ~= "" and prefix) or show
  end

  local last = parts[#parts]
  local prev = parts[#parts - 1]

  if prev then
    local two = "..." .. sep .. prev .. sep .. last
    if wezterm.column_width(two) <= OPT.cwd_body_len_parent2 then
      return prefix .. two
    end
  end

  local one = last
  if wezterm.column_width(one) > OPT.cwd_body_len then
    one = truncate_left_cells(one, OPT.cwd_body_len)
  end
  return prefix .. "..." .. sep .. one
end

----------------------------------------------------------------
-- Safe pane getters (PaneInformation or Pane)
----------------------------------------------------------------

--- @param pane any
--- @return string
local function pane_fg_name(pane)
  if not pane then
    return ""
  end
  local okf, v = pcall(function()
    return pane.foreground_process_name
  end)
  if okf and type(v) == "string" and #v > 0 then
    return v
  end
  local okm, m = pcall(function()
    return pane:get_foreground_process_name()
  end)
  if okm and type(m) == "string" and #m > 0 then
    return m
  end
  return ""
end

--- @param pane any
--- @return string
local function pane_title(pane)
  if not pane then
    return ""
  end
  local okf, v = pcall(function()
    return pane.title
  end)
  if okf and type(v) == "string" and #v > 0 then
    return v
  end
  local okm, m = pcall(function()
    return pane:get_title()
  end)
  if okm and type(m) == "string" and #m > 0 then
    return m
  end
  return ""
end

--- @param pane any
--- @return string|nil
local function pane_cwd_uri(pane)
  if not pane then
    return nil
  end
  local okf, v = pcall(function()
    return pane.current_working_dir
  end)
  if okf and v then
    return tostring(v)
  end
  local okm, m = pcall(function()
    return pane:get_current_working_dir()
  end)
  if okm and m then
    return tostring(m)
  end
  return nil
end

----------------------------------------------------------------
-- Env + builders
----------------------------------------------------------------

--- @param pane any
--- @return "windows"|"wsl"|"linux"
local function detect_env(pane)
  local tt = wezterm.target_triple or ""
  local domain = ""
  pcall(function()
    domain = (pane and pane.domain_name or ""):lower()
  end)
  local cwd = tostring(pane_cwd_uri(pane) or "")
  if domain:find("wsl", 1, true) or cwd:match("^file://wsl") then
    return "wsl"
  end
  if tt:find("windows", 1, true) then
    return "windows"
  end
  return "linux"
end

--- @param pane any
--- @return string
local function build_process_title(pane)
  local proc = pane_fg_name(pane)
  local base = proc:gsub(".+[\\/]","")
  local t = pane_title(pane)
  if base:lower():match("^n?vim") or t:lower():find("n?vim") then
    return " " .. (t ~= "" and t or "nvim")
  end
  return (base ~= "" and base) or (t ~= "" and t) or "shell"
end

--- @param pane any
--- @return string
local function build_cwd_title(pane)
  local uri = pane_cwd_uri(pane)
  local p = extract_path(uri)
  if p == "" then
    local t = pane_title(pane)
    if t ~= "" then
      return t
    end
  end
  return shorten_cwd_display(p ~= "" and p or "/")
end

----------------------------------------------------------------
-- Theme palette
----------------------------------------------------------------

--- Derive tab colors from the active theme (config snapshot).
--- @param config table
--- @param is_active boolean
--- @return {fg:string,bg:string,edge:string}
local function themed_tab_colors(config, is_active)
  local palette = (config and config.resolved_palette) or (config and config.colors) or {}
  local tab_bar = palette.tab_bar or {}

  local active  = tab_bar.active_tab   or {}
  local inact   = tab_bar.inactive_tab or {}
  local edge    = tab_bar.inactive_tab_edge or tab_bar.background or palette.background or "#222222"

  local bg = is_active and (active.bg_color or palette.background or "#333333")
                       or  (inact.bg_color  or tab_bar.background or "#1b1032")
  local fg = is_active and (active.fg_color or palette.foreground or "#c0c0c0")
                       or  (inact.fg_color  or "#808080")
  return { fg = fg, bg = bg, edge = edge }
end

----------------------------------------------------------------
-- Flip: deterministic + timer driven (WezTerm timers; no libuv)
----------------------------------------------------------------

--- Deterministic mode by time; independent of focus/user events.
--- @return string
local function current_mode()
  if not OPT.flip_enabled then
    return OPT.flip_modes[1]
  end
  local n = #OPT.flip_modes
  if n == 0 then
    return "cwd"
  end
  local t = os.time()
  local idx = (math.floor(t / math.max(1, OPT.flip_period_sec)) % n) + 1
  return OPT.flip_modes[idx]
end

-- Global periodic ticker to force re-layout of all windows (idle-safe flip).
local TICKER_STARTED = false
local function ensure_flip_ticker()
  if TICKER_STARTED then
    return
  end
  TICKER_STARTED = true

  local interval = (OPT.flip_tick_ms or 1000)
  if interval <= 0 then
    return
  end

  local function poke_all_windows()
    local gui = wezterm.gui
    if not gui then
      return
    end
    for _, win in ipairs(gui.windows()) do
      -- Cheap redraw trigger
      win:set_right_status("")
    end
  end

  if wezterm.time and wezterm.time.call_every then
    wezterm.time.call_every(interval / 1000.0, function()
      poke_all_windows()
    end)
  else
    local function loop()
      poke_all_windows()
      if wezterm.time and wezterm.time.call_after then
        wezterm.time.call_after(interval / 1000.0, loop)
      end
    end
    if wezterm.time and wezterm.time.call_after then
      wezterm.time.call_after(interval / 1000.0, loop)
    end
  end
end

wezterm.on("gui-startup", function(_)
  ensure_flip_ticker()
end)

wezterm.on("window-config-reloaded", function(window, _)
  ensure_flip_ticker()
  window:set_right_status("")
end)

wezterm.on("update-right-status", function(window, _)
  window:set_right_status("")
end)

----------------------------------------------------------------
-- Main formatter (fancy-aware)
----------------------------------------------------------------

---@diagnostic disable-next-line
wezterm.on("format-tab-title", function(tab, _tabs, _panes, config, _hover, _max_width)
  local pane = tab.active_pane
  local mode = current_mode()

  local title = (mode == "process") and build_process_title(pane) or build_cwd_title(pane)
  if wezterm.column_width(title) > OPT.max_title_len then
    title = wezterm.truncate_right(title, OPT.max_title_len)
  end

  local left_pad  = string.rep(" ", math.max(0, OPT.tab_left_pad_cells or 0))
  local right_pad = string.rep(" ", math.max(0, OPT.tab_right_pad_cells or 0))
  local gap_cells = math.max(0, OPT.tab_gap_cells or 0)
  local gap_text  = string.rep(" ", gap_cells)

  local is_fancy = (config and config.use_fancy_tab_bar) and true or false

  if OPT.fixed_tab_width_enabled then
    local align = "left"
    if mode == "cwd" and OPT.center_cwd then
      align = "center"
    end
    if mode == "process" and OPT.center_process then
      align = "center"
    end
    -- Decoration cost in retro mode: 1 leading + 1 trailing + gap
    -- In fancy mode the theme draws separators; we still budget similarly for stability.
    local deco_cost = 1 + 1 + gap_cells
    local budget = math.max(4, (OPT.fixed_tab_width or 40) - deco_cost)
    title = fit_width(title, budget, align)
  end

  if is_fancy then
    -- Fancy: don't paint backgrounds; separators/colors come from theme/plugin.
    local text = left_pad .. title .. right_pad .. gap_text
    return { { Text = text } }
  else
    -- Retro: color backgrounds and use "edge" gap block
    local pal = themed_tab_colors(config, tab.is_active)

    local prefix = ""
    if OPT.show_env_prefix then
      local env = detect_env(pane)
      if env == "windows" then
        prefix = "[W] "
      elseif env == "wsl" then
        prefix = "[WSL] "
      else
        prefix = "[Linux] "
      end
    end

    return {
      { Background = { Color = pal.bg } },
      { Foreground = { Color = pal.fg } },
      { Text = " " .. prefix .. left_pad },

      { Background = { Color = pal.bg } },
      { Foreground = { Color = pal.fg } },
      { Text = title .. right_pad .. " " },

      { Background = { Color = pal.edge } },
      { Foreground = { Color = pal.edge } },
      { Text = gap_text },
    }
  end
end)

----------------------------------------------------------------
-- Public API: mutate Config
----------------------------------------------------------------

--- @param Config table
--- @return table
return function(Config)
  -- Idle redraws every tick to keep flip in sync even without user activity
  Config.status_update_interval = math.max(100, OPT.flip_tick_ms)

  if OPT.fixed_tab_width_enabled then
    Config.tab_max_width = OPT.fixed_tab_width
  else
    Config.tab_max_width = OPT.dynamic_tab_width_max
  end

  -- Respect fancy/retro choice set elsewhere; do not force it here.
  Config.hide_tab_bar_if_only_one_tab = false
  return Config
end
