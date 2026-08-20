---@module 'wezterm.entry'
--- Single-source loader that dispatches to a repo-managed init.lua

local wezterm = require("wezterm")

-- OS-agnostic join helper
--- @param ... string
--- @return string path
local function join(...)
  local sep = package.config:sub(1, 1)
  local parts = { ... }
  for i = 1, #parts do parts[i] = tostring(parts[i]):gsub("[/\\]+$", "") end
  return table.concat(parts, sep)
end

-- 1) Resolve repo path from environment
--- 1a) $REPOS_DIR (if exported via environment.d)
local REPOS_DIR = os.getenv("REPOS_DIR")
--- 1b) ~/repos (common local default)
if not REPOS_DIR or REPOS_DIR == "" then
  REPOS_DIR = join(os.getenv("HOME") or "~", "repos")  -- fallback
  wezterm.log_error("[wezterm.entry] REPOS_DIR not set; falling back to " .. REPOS_DIR)
end

local candidates = {
  join(REPOS_DIR, "Configs", "Terminals", "wezterm"),
}

-- 2) Compute directory of the repo-based wezterm config
-- Pick first existing init.lua
local repo_wez_dir
for _, d in ipairs(candidates) do
  local f = io.open(join(d, "init.lua"), "r")
  if f then f:close(); repo_wez_dir = d; break end
end

if not repo_wez_dir then
  wezterm.log_error("[wezterm.entry] Could not locate repo init.lua in Config/Configs; using empty config")
  return {}
end

-- 3) Make repo modules resolvable for Lua
--  Prepend both "<dir>/?.lua" and "<dir>/?/init.lua" to package.path.
package.path = table.concat({
  repo_wez_dir .. "/?.lua",
  repo_wez_dir .. "/?/init.lua",
  package.path,
}, ";")

-- 4) Load repo entry chunk from absolute path to ensure we get exactly that file
local entry_file = join(repo_wez_dir, "init.lua")
wezterm.log_error("[wezterm.entry] Using repo init: " .. entry_file)
local ok, entry_or_err = pcall(dofile, entry_file)
if not ok then
  wezterm.log_error("[wezterm.entry] Failed to load repo init: " .. tostring(entry_or_err))
  return {}
end

-- Build config and run the entry
local config = (wezterm.config_builder and wezterm.config_builder()) or {}
local ok_run, result_or_err = pcall(entry_or_err, config)
if not ok_run then
  wezterm.log_error("[wezterm.entry] Repo init failed: " .. tostring(result_or_err))
  return {}
end
return result_or_err

