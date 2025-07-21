local wezterm = require 'wezterm'

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local pane = tab.active_pane
  local process_name = pane.foreground_process_name

  if process_name:find("n?vim") then
    local title = pane.title
    return { { Text = " " .. title } }  -- oder einfach { Text = "nvim" }
  else
    local cwd = pane.current_working_dir
    local home = os.getenv("HOME")
    local path = cwd and cwd.file_path:gsub(home, "~") or ""
    return { { Text = path } }
  end
end)


