# open-in-nvim.config.ps1
# Central configuration for "Open with Neovim (new instance)".
# Adjust NVIM_BIN if Neovim is not in the default location.

$Cfg = [ordered]@{
  # Absolute path to Neovim; if missing, script will try "nvim" from PATH.
  NVIM_BIN    = 'C:\Program Files\Neovim\bin\nvim.exe'

  # Optional terminal preference; script tries these in order:
  # 1) WezTerm GUI exe (if exists)  2) Windows Terminal "wt"  3) plain cmd.exe "start"
  WEZTERM_BIN = "$env:LOCALAPPDATA\wezterm\wezterm-gui.exe"
}
