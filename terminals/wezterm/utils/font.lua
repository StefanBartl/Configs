---@module 'utils.font'

local wezterm = require("wezterm")

local M = {}

local utils = require("utils")
local str_fmt = string.format
local os_execute = os.execute

---Get the user font directory based on OS
---@return string
function M.get_font_dir()
	local os_type = utils.detect_os()
	local home = os.getenv("HOME") or os.getenv("USERPROFILE")

	if os_type == "windows" then
		return os.getenv("LOCALAPPDATA") .. "\\Microsoft\\Windows\\Fonts"
	elseif os_type == "macos" then
		return home .. "/Library/Fonts"
	else -- linux
		return home .. "/.local/share/fonts"
	end
end

---Check if JetBrainsMono Nerd Font is installed
---@return boolean
function M.is_jetbrains_font_installed()
	-- Try to create a font with the specific family
	local success, _ = pcall(function()
		return wezterm.font("JetBrainsMono Nerd Font")
	end)

	return success
end

---Download and install JetBrainsMono Nerd Font
---@return boolean success True if installation succeeded or font already exists
function M.ensure_jetbrains_font()
	if M.is_jetbrains_font_installed() then
		wezterm.log_info("JetBrainsMono Nerd Font is already installed")
		return true
	end

	wezterm.log_info("JetBrainsMono Nerd Font not found, attempting to install...")

	-- Ensure dependencies are available
	if not utils.ensure_dependencies() then
		wezterm.log_error("Cannot install font: required dependencies are missing")
		return false
	end

	local font_dir = M.get_font_dir()
	local os_type = utils.detect_os()
	local font_url = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
	local temp_dir = os.getenv("TEMP") or os.getenv("TMPDIR") or "/tmp"
	local zip_path = temp_dir .. "/JetBrainsMono.zip"

	-- Create font directory if it doesn't exist
	local mkdir_cmd
	if os_type == "windows" then
		mkdir_cmd = str_fmt("powershell -Command \"New-Item -ItemType Directory -Force -Path '%s'\"", font_dir)
	else
		mkdir_cmd = str_fmt("mkdir -p '%s'", font_dir)
	end
	os.execute(mkdir_cmd)

	-- Download the font
	local download_cmd
	if os_type == "windows" then
		download_cmd = str_fmt("powershell -Command \"Invoke-WebRequest -Uri '%s' -OutFile '%s'\"", font_url, zip_path)
	else
		download_cmd = str_fmt("curl -L '%s' -o '%s'", font_url, zip_path)
	end

	local download_result = os.execute(download_cmd)
	if download_result ~= 0 and download_result ~= true then
		wezterm.log_error("Failed to download JetBrainsMono Nerd Font")
		return false
	end

	-- Extract the font
	local extract_cmd
	if os_type == "windows" then
		extract_cmd = str_fmt(
			"powershell -Command \"Expand-Archive -Path '%s' -DestinationPath '%s' -Force\"",
			zip_path,
			font_dir
		)
	else
		extract_cmd = str_fmt("unzip -o '%s' -d '%s'", zip_path, font_dir)
	end

	local extract_result = os_execute(extract_cmd)
	if extract_result ~= 0 and extract_result ~= true then
		wezterm.log_error("Failed to extract JetBrainsMono Nerd Font")
		return false
	end

	-- Clean up zip file
	local cleanup_cmd
	if os_type == "windows" then
		cleanup_cmd = str_fmt('del "%s"', zip_path)
	else
		cleanup_cmd = str_fmt("rm '%s'", zip_path)
	end
	os_execute(cleanup_cmd)

	-- Update font cache on Linux
	if os_type == "linux" then
		os_execute("fc-cache -f")
	end

	wezterm.log_info("JetBrainsMono Nerd Font installed successfully")
	wezterm.log_warn("Please restart WezTerm for the font changes to take effect")

	return true
end

return M
