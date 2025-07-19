

```lua
---@module 'wezterm'
---@brief OS Entry point configuration for WezTerm
---@version 1.0

local wezterm = require('wezterm')
local Config = wezterm.config_builder()

package.path = package.path .. ';E:/MyGithub/Configs/Terminal/wezterm/?.lua'
require("init")(Config)

return Config
```