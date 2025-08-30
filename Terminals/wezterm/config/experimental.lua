---@module 'wezterm.tabline_wez_integration'
--- Integrates michaelbrusegard/tabline.wez using a function(Config) wrapper.
--- Calls tabline.setup() FIRST (to initialize theme), then apply_to_config().
--- Works cross-platform; requires a Nerd Font for powerline separators/icons.

local wezterm = require("wezterm")

---@class WezTermConfig : table
---@field color_scheme string|nil
---@field colors table|nil
---@field tab_bar_at_bottom boolean
---@field use_fancy_tab_bar boolean
---@field hide_tab_bar_if_only_one_tab boolean
---@field show_new_tab_button_in_tab_bar boolean
---@field tab_max_width integer

---@param Config WezTermConfig
---@return nil
return function(Config)
  -- 1) Load plugin
  local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

  -- 2) Choose theme SOURCE for tabline:
  --    Prefer an explicit colors object, else a configured scheme name,
  --    else fall back to a safe builtin.
  --    tabline.wez accepts either a string (scheme name) OR a WezTerm colors table.
  local theme_source = Config.colors or Config.color_scheme or "Catppuccin Mocha"

  -- 3) Setup FIRST: initializes internal theme and component graph.
  --    If Nerd Font glyphs are not desired/available, set separators to ''.
  tabline.setup({
    options = {
      icons_enabled = true,
      theme = "Catppuccin Mocha", -- can be string or Config.colors object
      tabs_enabled = true,
      section_separators = {
        left = wezterm.nerdfonts.pl_left_hard_divider,
        right = wezterm.nerdfonts.pl_right_hard_divider,
      },
      component_separators = {
        left = wezterm.nerdfonts.pl_left_soft_divider,
        right = wezterm.nerdfonts.pl_right_soft_divider,
      },
      tab_separators = {
        left = wezterm.nerdfonts.pl_left_hard_divider,
        right = wezterm.nerdfonts.pl_right_hard_divider,
      },
      theme_overrides = {}, -- optional overrides per mode/keytable
    },
    sections = {
      tabline_a = { " WKD" },
      tabline_b = {},
      tabline_c = {},

      tab_active = {
        {
          'process',
          process_to_icon = {
            ['air'] = { wezterm.nerdfonts.md_language_go },
            ['bacon'] = { wezterm.nerdfonts.dev_rust },
            ['bat'] = { wezterm.nerdfonts.md_bat },
            ['btm'] = { wezterm.nerdfonts.md_chart_donut_variant },
            ['btop'] = { wezterm.nerdfonts.md_chart_areaspline },
            ['bun'] = { wezterm.nerdfonts.md_hamburger },
            ['cargo'] = { wezterm.nerdfonts.dev_rust },
            ['cmd.exe'] = { wezterm.nerdfonts.md_console_line },
            ['curl'] = wezterm.nerdfonts.md_flattr,
            ['debug'] = { wezterm.nerdfonts.cod_debug },
            ['default'] = wezterm.nerdfonts.md_application,
            ['docker'] = { wezterm.nerdfonts.md_docker },
            ['docker-compose'] = { wezterm.nerdfonts.md_docker },
            ['dpkg'] = { wezterm.nerdfonts.dev_debian },
            ['fish'] = { wezterm.nerdfonts.md_fish },
            ['git'] = { wezterm.nerdfonts.dev_git },
            ['go'] = { wezterm.nerdfonts.md_language_go },
            ['kubectl'] = { wezterm.nerdfonts.md_docker },
            ['kuberlr'] = { wezterm.nerdfonts.md_docker },
            ['lazygit'] = { wezterm.nerdfonts.cod_github },
            ['lua'] = { wezterm.nerdfonts.seti_lua },
            ['make'] = wezterm.nerdfonts.seti_makefile,
            ['nix'] = { wezterm.nerdfonts.linux_nixos },
            ['node'] = { wezterm.nerdfonts.md_nodejs },
            ['npm'] = { wezterm.nerdfonts.md_npm },
            ['nvim'] = { wezterm.nerdfonts.custom_neovim },
            -- and more...
          },
          -- process_to_icon is a table that maps process to icons
        },
      },
      tab_inactive = {
      },
      tabline_x = {},
      tabline_y = {},
      tabline_z = { " lavalue" },
    },
    extensions = {},
  })

  tabline.apply_to_config(Config)
  Config.tab_bar_at_bottom = true
  Config.use_fancy_tab_bar = false
  Config.hide_tab_bar_if_only_one_tab = false
  Config.show_new_tab_button_in_tab_bar = false
end
