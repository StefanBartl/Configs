---@module 'config.features'
---@brief features configuration for WezTerm

require("@types.types")

---@param Config WezTermConfig
---@return nil
return function(Config)
  Config.mouse_bindings = {
    {
      event = { Up = { streak = 1, button = "Left" } },
      mods = "NONE",
      action = require("wezterm").action.CompleteSelection 'Clipboard',
    },
  }
end

