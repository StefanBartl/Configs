---@module 'config.tabtitle'
--- OS-aware, colored tab title formatter for WezTerm.
--- Forces a non-fancy tab bar so that per-tab colors are respected.
--- Robust in WSL by falling back to pane.title and enabling periodic refresh.

---@alias Env "windows"|"wsl"|"linux"

---@class TabTitlePalette
---@field label string  -- Prefix label (e.g. "[W] ")
---@field fg    string  -- Foreground color hex
---@field bg    string  -- Background color hex
---@field edge  string  -- Edge separator color hex

local wezterm = require("wezterm")

----------------------------------------------------------------
-- Utilities
----------------------------------------------------------------

--- Decode percent-encoded sequences in a URI-like string.
--- @param str string
--- @return string
local function url_decode(str)
  return (tostring(str):gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end))
end

--- Extract a readable filesystem path from pane.current_working_dir (URI).
--- Supports WSL, Unix, and Windows forms.
--- @param uri string|nil
--- @return string
local function extract_path(uri)
  if not uri then
    return "[no cwd]"
  end
  local decoded = url_decode(uri)

  -- WSL variants: file://wsl%2BUbuntu/... or file://wsl.localhost/Ubuntu/...
  local wsl_path = decoded:match("file://wsl[^/]+(/.+)")
  if wsl_path then
    return wsl_path
  end

  -- Generic Unix
  local unix_path = decoded:match("file://[^/]+(/.+)")
  if unix_path then
    return unix_path
  end

  -- Windows drive-letter form
  if decoded:match("file:///[%a]:/.+") then
    return decoded:match("file:///(.+)") or "[unknown cwd]"
  end

  return "[unknown cwd]"
end

----------------------------------------------------------------
-- Environment/OS detection
----------------------------------------------------------------

--- Decide whether the pane runs in Windows, WSL, or Linux.
--- @param pane any
--- @return Env
local function detect_env(pane)
  local tt = wezterm.target_triple or ""
  local domain = (pane and pane.domain_name or ""):lower()
  local cwd = pane and tostring(pane.current_working_dir or "") or ""

  if domain:find("wsl", 1, true) or cwd:match("^file://wsl") then
    return "wsl"
  end
  if tt:find("windows", 1, true) then
    return "windows"
  end
  return "linux"
end

--- Palette per environment and active state.
--- @param env Env
--- @param is_active boolean
--- @return TabTitlePalette
local function env_palette(env, is_active)
  if env == "windows" then
    if is_active then
      return { label = "[W] ", fg = "#0b1021", bg = "#5aa9ff", edge = "#3c7bd1" }
    else
      return { label = "[W] ", fg = "#0b1021", bg = "#9fc9ff", edge = "#7aa8e6" }
    end
  elseif env == "wsl" then
    if is_active then
      return { label = "[WSL] ", fg = "#0b1021", bg = "#98f5a5", edge = "#62d66f" }
    else
      return { label = "[WSL] ", fg = "#0b1021", bg = "#c9f7cf", edge = "#9de6a5" }
    end
  else
    if is_active then
      return { label = "[Linux] ", fg = "#0b1021", bg = "#ffd166", edge = "#e0b24e" }
    else
      return { label = "[Linux] ", fg = "#0b1021", bg = "#ffe4a8", edge = "#d8c38a" }
    end
  end
end

----------------------------------------------------------------
-- Title building
----------------------------------------------------------------

--- Build the core title from foreground process or cwd.
--- In WSL and shells that don't emit OSC 7, fall back to pane.title.
--- @param pane any
--- @return string
local function build_core_title(pane)
  -- Try to detect nvim first
  local process = ""
  if pane and pane.get_foreground_process_name then
    local ok, name = pcall(pane.get_foreground_process_name, pane)
    process = ok and (name or "") or ""
  else
    process = pane and (pane.foreground_process_name or "") or ""
  end

  if process:find("n?vim") then
    local t = (pane and pane.title) or "nvim"
    return " " .. t
  end

  -- Prefer cwd from OSC 7, else fall back to pane.title (commonly set via OSC 2)
  local cwd = extract_path(pane and pane.current_working_dir or nil)
  if cwd == "[no cwd]" or cwd == "[unknown cwd]" then
    local t = (pane and pane.title) or ""
    if t ~= "" then
      return t
    end
  end

  -- Replace $HOME prefix with "~" if possible
  local home = os.getenv("HOME") or ""
  if cwd:find("^/home/") and (home == "" or not home:find("^/")) then
    local user = (os.getenv("USERNAME") or ""):lower()
    if user ~= "" then
      home = "/home/" .. user
    end
  end
  if home ~= "" then
    cwd = cwd:gsub("^" .. home, "~")
  end

  return cwd
end

----------------------------------------------------------------
-- Events
----------------------------------------------------------------

-- Regularly refresh right status to ensure tabs are reformatted periodically.
wezterm.on("update-right-status", function(window, _)
  -- Keep it minimal; an empty status string is sufficient to trigger a refresh.
  window:set_right_status("")
end)

-- Render colored prefix + title + edge.
---@diagnostic disable-next-line
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local pane = tab.active_pane
  local env = detect_env(pane)
  local pal = env_palette(env, tab.is_active)

  local title = build_core_title(pane)
  if #title > 80 then
    title = title:sub(1, 77) .. "…"
  end

  return {
    { Background = { Color = pal.bg } },
    { Foreground = { Color = pal.fg } },
    { Text = " " .. pal.label },

    { Background = { Color = pal.bg } },
    { Foreground = { Color = pal.fg } },
    { Text = title .. " " },

    { Background = { Color = pal.edge } },
    { Foreground = { Color = pal.edge } },
    { Text = " " },
  }
end)

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Mutate passed-in Config: disable fancy tab bar for reliable per-tab coloring.
--- @param Config table
--- @return table
return function(Config)
  Config.use_fancy_tab_bar = false -- override appearance.lua
  Config.hide_tab_bar_if_only_one_tab = false
  Config.tab_max_width = 48        -- a bit wider than the default for paths
  return Config
end
