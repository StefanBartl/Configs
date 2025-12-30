---@module 'wezterm.utils'

local wezterm = require("wezterm")

local M = {}

local str_fmt = string.format
local os_execute = os.execute
local log_error, log_warn, log_info = wezterm.log_error, wezterm.log_warn, wezterm.log_info

---Detect the operating system
---@return "windows"|"macos"|"linux"
function M.detect_os()
	local target = wezterm.target_triple
	if target:find("windows") then
		return "windows"
	elseif target:find("darwin") or target:find("apple") then
		return "macos"
	else
		return "linux"
	end
end


---Check if a command is available in PATH
---@param cmd string Command name to check
---@return boolean
function M.command_exists(cmd)
	local os_type = M.detect_os()
	local check_cmd

	if os_type == "windows" then
		check_cmd = str_fmt("where %s >nul 2>&1", cmd)
	else
		check_cmd = str_fmt("command -v %s >/dev/null 2>&1", cmd)
	end

	local result = os_execute(check_cmd)
	return result == 0 or result == true
end

---Detect package manager on Linux
---@return string|nil Package manager command or nil if none found
function M.detect_package_manager()
	local managers = {
		{ cmd = "apt-get", install = "apt-get install -y" },
		{ cmd = "dnf", install = "dnf install -y" },
		{ cmd = "yum", install = "yum install -y" },
		{ cmd = "pacman", install = "pacman -S --noconfirm" },
		{ cmd = "zypper", install = "zypper install -y" },
		{ cmd = "apk", install = "apk add" },
	}

	for _, manager in ipairs(managers) do
		if M.command_exists(manager.cmd) then
			return manager.install
		end
	end

	return nil
end

---Install required dependencies (curl and unzip)
---@return boolean success True if dependencies are available or were installed successfully
function M.ensure_dependencies()
	local os_type = M.detect_os()
	local missing = {}

	-- Check for curl
	if not M.command_exists("curl") then
		table.insert(missing, "curl")
	end

	-- Check for unzip (not needed on Windows with PowerShell)
	if os_type ~= "windows" and not M.command_exists("unzip") then
		table.insert(missing, "unzip")
	end

	-- All dependencies present
	if #missing == 0 then
		return true
	end

	log_info(str_fmt("Missing dependencies: %s", table.concat(missing, ", ")))

	-- Install missing dependencies based on OS
	if os_type == "linux" then
		local pkg_manager = M.detect_package_manager()

		if not pkg_manager then
			log_error("Could not detect package manager. Please install: " .. table.concat(missing, ", "))
			return false
		end

		log_info("Installing dependencies with package manager...")
		local install_cmd = str_fmt("sudo %s %s", pkg_manager, table.concat(missing, " "))
		local result = os_execute(install_cmd)

		if result ~= 0 and result ~= true then
			log_error("Failed to install dependencies. Please run manually: " .. install_cmd)
			return false
		end
	elseif os_type == "macos" then
		-- Check if Homebrew is available
		if not M.command_exists("brew") then
			log_error("Homebrew not found. Please install Homebrew first: https://brew.sh")
			return false
		end

		log_info("Installing dependencies with Homebrew...")
		for _, dep in ipairs(missing) do
			local install_cmd = str_fmt("brew install %s", dep)
			local result = os_execute(install_cmd)

			if result ~= 0 and result ~= true then
				log_error(str_fmt("Failed to install %s with Homebrew", dep))
				return false
			end
		end
	elseif os_type == "windows" then
		-- Windows: try to install via winget or chocolatey
		if M.command_exists("winget") then
			log_info("Installing dependencies with winget...")
			for _, dep in ipairs(missing) do
				local install_cmd =
					str_fmt("winget install -e --id %s", dep == "curl" and "cURL.cURL" or "GnuWin32.UnZip")
				local result = os_execute(install_cmd)

				if result ~= 0 and result ~= true then
					log_warn(str_fmt("Failed to install %s with winget", dep))
				end
			end
		elseif M.command_exists("choco") then
			log_info("Installing dependencies with Chocolatey...")
			for _, dep in ipairs(missing) do
				local install_cmd = str_fmt("choco install %s -y", dep)
				local result = os_execute(install_cmd)

				if result ~= 0 and result ~= true then
					log_warn(str_fmt("Failed to install %s with Chocolatey", dep))
				end
			end
		else
			log_error("No package manager found. Please install curl manually or install winget/chocolatey")
			return false
		end
	end

	-- Verify installation
	for _, dep in ipairs(missing) do
		if not M.command_exists(dep) then
			log_error(str_fmt("%s is still not available after installation attempt", dep))
			return false
		end
	end

	log_info("All dependencies installed successfully")
	return true
end

return M
