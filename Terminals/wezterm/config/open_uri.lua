---@module 'config.open_uri'
---@brief Custom URI handler for WezTerm to open files and folders on click.
---@see https://wezfurlong.org/wezterm/config/lua/event-handlers.html#weztermon

require("@types.types")

local wt = require 'wezterm'

--- Helper to detect if the foreground process is a known shell.
---@param foreground_process_name string
---@return boolean
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

--- Set up custom behavior for URI clicks (e.g. file://).
---@return nil
return function(_)
  wt.on('open-uri', function(_, pane, uri)
    local editor = 'nvim' -- set your default editor here

    -- only handle file:// URIs and avoid alternate screens (e.g. less, vim, man)
    if uri:find '^file:' == 1 and not pane:is_alt_screen_active() then
      local url = wt.url.parse(uri)

      if is_shell(pane:get_foreground_process_name()) then
        -- If we are in a shell, use 'file' to determine type
        local success, stdout, _ = wt.run_child_process {
          'file',
          '--brief',
          '--mime-type',
          url.file_path,
        }

        if not success then
          return false -- fallback to default action
        end

        -- Case: It's a directory → cd + ls
        if stdout:find 'directory' then
          pane:send_text(wt.shell_join_args {
            'cd', url.file_path
          } .. '\r')

          pane:send_text(wt.shell_join_args {
            'ls', '-a', '-p', '--group-directories-first'
          } .. '\r')

          return false
        end

        -- Case: It's a text file → open in editor
        if stdout:find 'text' then
          local edit_args = url.fragment and {
            editor, '+' .. url.fragment, url.file_path
          } or {
            editor, url.file_path
          }

          pane:send_text(wt.shell_join_args(edit_args) .. '\r')
          return false
        end
      else
        -- Probably remote shell (e.g. SSH): use shell fallback
        local edit_cmd = url.fragment
            and (editor .. ' +' .. url.fragment .. ' "$_f"')
            or (editor .. ' "$_f"')

        local cmd = table.concat({
          '_f="' .. url.file_path .. '"',
          '{ test -d "$_f" && { cd "$_f"; ls -a -p --hyperlink --group-directories-first; }; }',
          '|| { test "$(file --brief --mime-type "$_f" | cut -d/ -f1 || true)" = "text" && ' .. edit_cmd .. '; };',
          'echo'
        }, ' ; ')

        pane:send_text(cmd .. '\r')
        return false
      end
    end

    -- returning nil allows default behavior for other URIs (e.g. https://)
  end)
end
