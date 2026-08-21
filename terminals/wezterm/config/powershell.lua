---@module 'config.powershell'
--- Waehlt die Standard-Shell auf Windows: PowerShell 7 (pwsh), sonst
--- Windows PowerShell 5.1 als Notnagel.
---
--- Wichtig: pwsh 7 kann auf mehrere Arten installiert sein und liegt je nach
--- Variante woanders. Wird nur der MSI-Pfad geprueft, faellt WezTerm still auf
--- powershell.exe (5.1) zurueck — und Profil sowie MyCliHelpers dieses Repos
--- nutzen PS7-Syntax (`??`), scheitern dort also mit Parser-Fehlern.
---
---   MSI / winget : %ProgramFiles%/PowerShell/7/pwsh.exe
---   Store / MSIX : %LOCALAPPDATA%/Microsoft/WindowsApps/pwsh.exe  (App-Alias)
---   PATH         : pwsh.exe
---
--- Pfade sind bewusst mit "/" geschrieben: Windows akzeptiert das in io.open,
--- CreateProcess und wezterm.glob, und Lua braucht kein Escaping.
---
---@param Config table
---@return table
local function configure_windows_shell(Config)
  local wezterm = require("wezterm")

  --- Existiert die Datei? Der MSIX-App-Alias ist ein 0-Byte-Reparse-Point,
  --- der sich nicht oeffnen laesst — darum zusaetzlich ueber glob pruefen.
  ---@param path string
  ---@return boolean
  local function exists(path)
    local f = io.open(path, "rb")
    if f then
      f:close()
      return true
    end
    local matches = wezterm.glob(path)
    return matches ~= nil and #matches > 0
  end

  local program_files = (os.getenv("ProgramFiles") or "C:/Program Files"):gsub("\\", "/")
  local local_appdata = (os.getenv("LOCALAPPDATA") or ""):gsub("\\", "/")
  local windows_dir = (os.getenv("WINDIR") or "C:/Windows"):gsub("\\", "/")

  -- Reihenfolge = Vorzug. Erster Treffer gewinnt.
  local candidates = {
    { label = "pwsh 7 (MSI)", path = program_files .. "/PowerShell/7/pwsh.exe" },
    { label = "pwsh 7 (Preview)", path = program_files .. "/PowerShell/7-preview/pwsh.exe" },
    { label = "pwsh 6 (MSI)", path = program_files .. "/PowerShell/6/pwsh.exe" },
    {
      label = "pwsh 7 (Store/MSIX App-Alias)",
      path = local_appdata ~= "" and (local_appdata .. "/Microsoft/WindowsApps/pwsh.exe") or nil,
    },
    {
      label = "pwsh 7 (WindowsApps)",
      path = program_files .. "/WindowsApps/Microsoft.PowerShell_*_x64__8wekyb3d8bbwe/pwsh.exe",
      glob = true,
    },
    {
      label = "Windows PowerShell 5.1",
      path = windows_dir .. "/System32/WindowsPowerShell/v1.0/powershell.exe",
      legacy = true,
    },
  }

  -- wsl.exe: aus einem 32-Bit-Prozess erreicht man das 64-Bit-System32 nur ueber
  -- den virtuellen Sysnative-Pfad. Fuer Skripte als $env:WEZTERM_WSL_PATH.
  -- Feldname ist set_environment_variables — ein `Config.env` laesst WezTerm die
  -- GESAMTE Config verwerfen und still auf die Defaults zurueckfallen.
  for _, wsl in ipairs({ windows_dir .. "/System32/wsl.exe", windows_dir .. "/Sysnative/wsl.exe" }) do
    if exists(wsl) then
      Config.set_environment_variables = Config.set_environment_variables or {}
      Config.set_environment_variables["WEZTERM_WSL_PATH"] = wsl
      break
    end
  end

  for _, candidate in ipairs(candidates) do
    if candidate.path then
      local resolved = nil
      if candidate.glob then
        local matches = wezterm.glob(candidate.path)
        -- glob liefert sortiert; die letzte Uebereinstimmung ist die neueste Version.
        resolved = (matches and #matches > 0) and matches[#matches] or nil
      elseif exists(candidate.path) then
        resolved = candidate.path
      end

      if resolved then
        Config.default_prog = { resolved, "-NoLogo" }
        if candidate.legacy then
          wezterm.log_warn(
            "[config.powershell] Kein pwsh 7 gefunden — nutze "
              .. candidate.label
              .. ". Profil und MyCliHelpers setzen PS7 voraus."
          )
        else
          wezterm.log_info("[config.powershell] " .. candidate.label .. ": " .. resolved)
        end
        return Config
      end
    end
  end

  -- Nichts gefunden: pwsh ueber den PATH versuchen, den Rest macht WezTerm.
  Config.default_prog = { "pwsh.exe", "-NoLogo" }
  wezterm.log_error("[config.powershell] Keine PowerShell an bekannten Pfaden — versuche pwsh.exe aus dem PATH.")
  return Config
end

-- Modul-Export: function(Config) -> Config (vom Repo-Loader erwartet)
return function(Config)
  local wezterm = require("wezterm")
  local is_windows = (wezterm.target_triple or ""):find("windows", 1, true) ~= nil

  if is_windows then
    Config = configure_windows_shell(Config)
  end

  return Config
end
