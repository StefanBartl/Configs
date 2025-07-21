---@module 'config.wsl'
---@brief WSL domain configuration for WezTerm to enable launch targets via the launcher.

require("@types.types")

---@param Config WezTermConfig
---@return nil
return function(Config)
  --- Define available WSL distributions to appear in the launcher.
  --- Each entry creates a selectable launch domain (e.g. "WSL:Ubuntu").
  Config.wsl_domains = {
    {
      --- Display name in the launcher and internal domain ID
      name = "WSL:Ubuntu",

      --- WSL distribution name (must match `wsl.exe -l`)
      distribution = "Ubuntu",

      --- Default username to log in as
      username = "weltschmerz",

      --- Default working directory when launching
      default_cwd = "~",

      --- Launch command, e.g. bash with login and interactive flags
      default_prog = { "bash", "-i", "-l" },
    },
    {
      name = "WSL:Alpine",
      distribution = "Alpine",
      username = "weltschmerz",
      default_cwd = "/home/weltschmerz",
      -- default_prog not set → fallback to distro default
    },
  }
end
