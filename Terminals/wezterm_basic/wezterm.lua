local wt = require 'wezterm'
local Config = wt.config_builder()

-- color scheme
-- RosePine v2
local theme = wt.plugin.require('https://github.com/neapsix/wezterm').main
Config.colors = theme.colors()
Config.window_frame = theme.window_frame() -- needed only if using fancy tab bar
-- or
--Config.color_scheme = 'rose-pine'

--Config.initial_cols = 120
--Config.initial_rows = 28
Config.window_background_opacity = 0.75

---window appearance
Config.window_padding = { left = 2, right = 2, top = 2, bottom = 1 }
Config.integrated_title_button_alignment = "Right"
Config.integrated_title_button_style = "Windows"
Config.integrated_title_buttons = { "Hide", "Maximize", "Close" }

-- Tab bar
Config.enable_tab_bar = true
Config.use_fancy_tab_bar = true
Config.tab_bar_at_bottom = true
Config.hide_tab_bar_if_only_one_tab = false
Config.show_new_tab_button_in_tab_bar = true
Config.show_tab_index_in_tab_bar = false
Config.show_tabs_in_tab_bar = true
Config.switch_to_last_active_tab_when_closing_tab = false
Config.tab_and_split_indices_are_zero_based = false
Config.tab_max_width = 25

-- font
Config.font_size = 10
Config.font = wt.font_with_fallback {
  {
    family = "FiraCode Nerd Font",
    weight = "Regular",
    harfbuzz_features = {
      -- "cv01", ---styles: a
      -- "cv02", ---styles: g
      "cv06", ---styles: i (03..06)
      -- "cv09", ---styles: l (07..10)
      "cv12", ---styles: 0 (11..13, zero)
      "cv14", ---styles: 3
      "cv16", ---styles: * (15..16)
      -- "cv17", ---styles: ~
      -- "cv18", ---styles: %
      -- "cv19", ---styles: <= (19..20)
      -- "cv21", ---styles: =< (21..22)
      -- "cv23", ---styles: >=
      -- "cv24", ---styles: /=
      "cv25", ---styles: .-
      "cv26", ---styles: :-
      -- "cv27", ---styles: []
      "cv28", ---styles: {. .}
      "cv29", ---styles: { }
      -- "cv30", ---styles: |
      "cv31", ---styles: ()
      "cv32", ---styles: .=
      -- "ss01", ---styles: r
      -- "ss02", ---styles: <= >=
      "ss03", ---styles: &
      "ss04", ---styles: $
      "ss05", ---styles: @
      -- "ss06", ---styles: \\
      "ss07", ---styles: =~ !~
      -- "ss08", ---styles: == === != !==
      "ss09", ---styles: >>= <<= ||= |=
      -- "ss10", ---styles: Fl Tl fi fj fl ft
      -- "onum", ---styles: 1234567890
    },
  },
  { family = "Noto Color Emoji" },
  { family = "LegacyComputing" },
}


-- WSL
Config.wsl_domains = {
  {
    name = "WSL:Ubuntu",
    distribution = "Ubuntu",
    username = "weltschmerz",
    default_cwd = "~",
    default_prog = { "bash", "-i", "-l" },
  },
  {
    name = "WSL:Alpine",
    distribution = "Alpine",
    username = "weltschmerz",
    default_cwd = "/home/weltschmerz",
  },
}


-- this snippet, you can:
--   - Click on an hyperlinked directory to navigate into that directory and list its contents
--   - Click on an hyperlinked file and if its MIME type is 'text', open it directly in Neovim
--   - Other hyperlinks like URLs remain unchanged and follow WezTerm's default behavior

local act = wt.action

local function is_shell(foreground_process_name)
  local shell_names = { 'bash', 'zsh', 'fish', 'sh', 'ksh', 'dash' }
  local process = string.match(foreground_process_name, '[^/\\]+$')
      or foreground_process_name
  for _, shell in ipairs(shell_names) do
    if process == shell then
      return true
    end
  end
  return false
end

wt.on('open-uri', function(window, pane, uri)
  local editor = 'nvim'

  if uri:find '^file:' == 1 and not pane:is_alt_screen_active() then
    -- We're processing an hyperlink and the uri format should be: file://[HOSTNAME]/PATH[#linenr]
    -- Also the pane is not in an alternate screen (an editor, less, etc)
    local url = wt.url.parse(uri)
    if is_shell(pane:get_foreground_process_name()) then
      -- A shell has been detected. wt can check the file type directly
      -- figure out what kind of file we're dealing with
      local success, stdout, _ = wt.run_child_process {
        'file',
        '--brief',
        '--mime-type',
        url.file_path,
      }
      if success then
        if stdout:find 'directory' then
          pane:send_text(
            wt.shell_join_args { 'cd', url.file_path } .. '\r'
          )
          pane:send_text(wt.shell_join_args {
            'ls',
            '-a',
            '-p',
            '--group-directories-first',
          } .. '\r')
          return false
        end

        if stdout:find 'text' then
          if url.fragment then
            pane:send_text(wt.shell_join_args {
              editor,
              '+' .. url.fragment,
              url.file_path,
            } .. '\r')
          else
            pane:send_text(
              wt.shell_join_args { editor, url.file_path } .. '\r'
            )
          end
          return false
        end
      end
    else
      -- No shell detected, we're probably connected with SSH, use fallback command
      local edit_cmd = url.fragment
          and editor .. ' +' .. url.fragment .. ' "$_f"'
          or editor .. ' "$_f"'
      local cmd = '_f="'
          .. url.file_path
          .. '"; { test -d "$_f" && { cd "$_f" ; ls -a -p --hyperlink --group-directories-first; }; } '
          .. '|| { test "$(file --brief --mime-type "$_f" | cut -d/ -f1 || true)" = "text" && '
          .. edit_cmd
          .. '; }; echo'
      pane:send_text(cmd .. '\r')
      return false
    end
  end

  -- without a return value, we allow default actions
end)

return Config
