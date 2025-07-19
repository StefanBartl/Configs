```lua
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Linux-Pfad zu deinem gemeinsamen Repo
package.path = package.path .. ";/mnt/e/MyGithub/Configs/Terminal/wezterm/?.lua"

-- Weiterleitung an Repo-Config
require("init")(config)

return config
```