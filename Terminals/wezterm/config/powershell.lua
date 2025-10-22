---@module 'config.powershell'
--- Configure WezTerm to prefer a 64-bit PowerShell (PowerShell Core if present).
--- This module sets Config.default_prog to a concrete, architecture-correct executable
--- and falls back gracefully if a preferred binary is not present.
---
--- Rationale:
--- - 64-bit wsl.exe lives in C:\Windows\System32. 32-bit processes are redirected
---   to C:\Windows\SysWOW64 which often does not contain wsl.exe.
--- - To call the 64-bit System32 from a 32-bit process use the Sysnative virtual path.
--- - Prefer pwsh (PowerShell Core) from "Program Files" (x64) when available.
---
---@param Config table
---@return table
local function configure_windows_shell(Config)
  local wezterm = require("wezterm")

  -- Helper: check if a file exists
  local function exists(path)
    local f = io.open(path, "rb")
    if f then f:close(); return true end
    return false
  end

  -- Common absolute paths to try (64-bit locations).
  -- Comments are in English; code & paths are platform-specific.
  local program_files = os.getenv("ProgramFiles") or "C:\\Program Files"
  --local program_files_x86 = os.getenv("ProgramFiles(x86)") or "C:\\Program Files (x86)"
  local windows_dir = os.getenv("WINDIR") or "C:\\Windows"

  -- Preferred: PowerShell Core x64 from Program Files
  local pwsh_x64 = program_files .. "\\PowerShell\\7\\pwsh.exe"                -- typical install for PowerShell 7+
  local pwsh_x64_alt = program_files .. "\\PowerShell\\6\\pwsh.exe"            -- older installs (optional)
  -- Fallback: Windows PowerShell 64-bit in System32
  local powershell_x64 = windows_dir .. "\\System32\\WindowsPowerShell\\v1.0\\powershell.exe"
  -- Special path to reach 64-bit System32 from a 32-bit process:
  local sysnative_wsl = windows_dir .. "\\Sysnative\\wsl.exe"                 -- use when process is 32-bit
  local system32_wsl = windows_dir .. "\\System32\\wsl.exe"                   -- normal 64-bit path

  -- Decision order:
  -- 1) pwsh_x64 if present
  -- 2) powershell_x64 if present
  -- 3) if neither available, try to run pwsh from PATH (pwsh.exe) or direct wsl via Sysnative
  if exists(pwsh_x64) then
    -- Use PowerShell Core x64
    Config.default_prog = { pwsh_x64, "-NoLogo" }
    wezterm.log_info("[config.wsl] Using pwsh x64: " .. pwsh_x64)
    return Config
  elseif exists(pwsh_x64_alt) then
    Config.default_prog = { pwsh_x64_alt, "-NoLogo" }
    wezterm.log_info("[config.wsl] Using pwsh x64 (alt): " .. pwsh_x64_alt)
    return Config
  elseif exists(powershell_x64) then
    -- Use Windows PowerShell 64-bit
    Config.default_prog = { powershell_x64, "-NoLogo" }
    wezterm.log_info("[config.wsl] Using Windows PowerShell x64: " .. powershell_x64)
    return Config
  else
    -- Last resort: WezTerm might be a 32-bit process. To invoke 64-bit wsl.exe from a
    -- 32-bit process, use the Sysnative path. If sysnative exists, set a helper entry so
    -- wsl invocations work reliably.
    if exists(sysnative_wsl) then
      -- set an environment shim so 'wsl.exe' resolves to the correct Sysnative path
      Config.env = Config.env or {}
      -- prepend a small batch wrapper into PATH via a temporary folder is overkill here,
      -- instead expose WSL_EXEC for scripts that use it. Users can call $env:WSL_EXEC
      -- or the following example shows how to call it directly.
      Config.env["WEZTERM_WSL_PATH"] = sysnative_wsl
      wezterm.log_info("[config.wsl] Sysnative wsl available, exporting WEZTERM_WSL_PATH=" .. sysnative_wsl)

      -- Still set default_prog to host PowerShell if any 'powershell.exe' on PATH works:
      Config.default_prog = { "powershell.exe", "-NoLogo" }
      wezterm.log_info("[config.wsl] Falling back to powershell.exe (PATH). Recommend using WEZTERM_WSL_PATH to call wsl.")
     	 return Config
    end

    -- Fallback: try system32 wsl (may work when WezTerm is 64-bit)
    if exists(system32_wsl) then
      Config.env = Config.env or {}
      Config.env["WEZTERM_WSL_PATH"] = system32_wsl
      Config.default_prog = { "powershell.exe", "-NoLogo" }
      wezterm.log_info("[config.wsl] Using System32 wsl and default powershell from PATH.")
      return Config
    end

    -- If nothing found, leave Config.default_prog untouched and log a warning.
    wezterm.log_error("[config.wsl] No suitable PowerShell or wsl executable found; leaving default shell.")
    return Config
  end
end

-- Module export: function(Config) -> Config (expected by repo init loader)
return function(Config)
  local wezterm = require("wezterm")
  local is_windows = (wezterm.target_triple or ""):find("windows", 1, true) ~= nil

  if is_windows then
    Config = configure_windows_shell(Config)
  end

  return Config
end
