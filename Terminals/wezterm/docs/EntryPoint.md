´´´lua
---@module 'wezterm.entry'
--- Single-source loader that dispatches to a repo-managed init.lua
--- located at $REPOS_DIR/Config/Terminals/wezterm/init.lua.

-- Always keep comments in English and code portable across OS.

local wezterm = require("wezterm")

--- Join path segments using the OS-specific directory separator.
--- @param ... string
--- @return string path
local function join(...)
  local sep = package.config:sub(1, 1) -- directory separator ('/' or '\')
  local parts = { ... }
  for i = 1, #parts do
    -- Normalize any accidental trailing separators to avoid doubles
    parts[i] = tostring(parts[i]):gsub("[/\\]+$", "")
  end
  return table.concat(parts, sep)
end

-- 1) Resolve repo path from environment
local REPOS_DIR = os.getenv("REPOS_DIR")
if not REPOS_DIR or REPOS_DIR == "" then
  wezterm.log_error(
    "[wezterm.entry] Environment variable REPOS_DIR is not set. " ..
    "Falling back to local config; define REPOS_DIR to use the shared repo."
  )
  return {}
end

-- 2) Compute directory of the repo-based wezterm config
local repo_wez_dir = join(REPOS_DIR, "Config", "Terminals", "wezterm")

-- 3) Make Lua find repo modules (config.* etc.)
--    We prepend both "<dir>/?.lua" and "<dir>/?/init.lua" to package.path.
package.path = table.concat({
  repo_wez_dir .. "/?.lua",
  repo_wez_dir .. "/?/init.lua",
  package.path,
}, ";")

-- 4) Load repo entry chunk from absolute path to ensure we get exactly that file
local entry_file = join(repo_wez_dir, "init.lua")
local ok, entry_or_err = pcall(dofile, entry_file)
if not ok then
  wezterm.log_error("[wezterm.entry] Failed to load " .. entry_file .. ": " .. tostring(entry_or_err))
  return {}
end

-- 5) Build config table (if supported) and delegate to repo entry
local config = (wezterm.config_builder and wezterm.config_builder()) or {}
local ok_run, result_or_err = pcall(entry_or_err, config)
if not ok_run then
  wezterm.log_error("[wezterm.entry] Repo init failed: " .. tostring(result_or_err))
  return {}
end
return result_or_err
```
