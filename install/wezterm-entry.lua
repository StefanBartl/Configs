---@module 'wezterm.entry'
--- Single-source entry loader for WezTerm.
---
--- Installed by install/install.sh bzw. install/install.ps1 als Symlink nach
---   ~/.config/wezterm/wezterm.lua
--- Diese Datei enthaelt bewusst KEINE Konfiguration — sie sucht nur die
--- Repo-Config unter <repo>/terminals/wezterm/init.lua und delegiert dorthin.
---
--- Weil sie als Symlink ins Repo zeigt, wirkt eine Pfadaenderung hier auf
--- allen Maschinen, ohne dass wezterm.lua pro Maschine editiert werden muss.

-- Die wezterm-Typdefinitionen liegen unter terminals/wezterm/@types und sind
-- von hier aus nicht sichtbar; LuaLS kennt das Modul daher nicht.
---@diagnostic disable: undefined-field
local wezterm = require("wezterm")

--- Join path segments using the OS-specific directory separator.
---@param ... string
---@return string
local function join(...)
  local sep = package.config:sub(1, 1)
  local parts = { ... }
  for i = 1, #parts do
    parts[i] = tostring(parts[i]):gsub("[/\\]+$", "")
  end
  return table.concat(parts, sep)
end

--- Does <dir>/init.lua exist and is readable?
---@param dir string
---@return boolean
local function has_init(dir)
  local f = io.open(join(dir, "init.lua"), "r")
  if f then
    f:close()
    return true
  end
  return false
end

-- 1) Kandidaten fuer die Repo-Wurzel: $REPOS_DIR zuerst, dann ueblich Defaults.
local home = os.getenv("HOME") or os.getenv("USERPROFILE") or ""
local roots = {}
local function add_root(p)
  if p and p ~= "" then
    roots[#roots + 1] = p
  end
end
add_root(os.getenv("REPOS_DIR"))
add_root(home ~= "" and join(home, "repos") or nil)

-- 2) Repo-Namen: aktueller Name zuerst, geplanter Zielname als Fallback.
local repo_names = { "Configs", "dotfiles" }

-- 3) Ersten existierenden Kandidaten waehlen.
local repo_wez_dir
for _, root in ipairs(roots) do
  for _, name in ipairs(repo_names) do
    local dir = join(root, name, "terminals", "wezterm")
    if has_init(dir) then
      repo_wez_dir = dir
      break
    end
  end
  if repo_wez_dir then
    break
  end
end

if not repo_wez_dir then
  wezterm.log_error(
    "[wezterm.entry] Repo-Config nicht gefunden. Gesucht unter <root>/{Configs,dotfiles}/terminals/wezterm "
      .. "fuer roots: "
      .. (#roots > 0 and table.concat(roots, ", ") or "(keine)")
      .. " — setze $REPOS_DIR. Nutze leere Config."
  )
  return {}
end

-- 4) Repo-Module aufloesbar machen (config.*, utils.* usw.).
package.path = table.concat({
  repo_wez_dir .. "/?.lua",
  repo_wez_dir .. "/?/init.lua",
  package.path,
}, ";")

-- 5) Entry-Chunk aus absolutem Pfad laden.
local entry_file = join(repo_wez_dir, "init.lua")
local ok, entry_or_err = pcall(dofile, entry_file)
if not ok then
  wezterm.log_error("[wezterm.entry] Laden fehlgeschlagen: " .. entry_file .. ": " .. tostring(entry_or_err))
  return {}
end

-- 6) Config bauen und an die Repo-Entry delegieren.
local config = (wezterm.config_builder and wezterm.config_builder()) or {}
local ok_run, result_or_err = pcall(entry_or_err, config)
if not ok_run then
  wezterm.log_error("[wezterm.entry] Repo-Init fehlgeschlagen: " .. tostring(result_or_err))
  return {}
end

return result_or_err
