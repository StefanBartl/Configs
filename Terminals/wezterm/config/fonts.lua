---@module 'config.fonts'
---@brief Font configuration for WezTerm using fallback and typographic ligatures

require("@types.types")

local wezterm = require("wezterm")

---Detect the operating system
---@return "windows"|"macos"|"linux"
local function detect_os()
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
local function command_exists(cmd)
  local os_type = detect_os()
  local check_cmd

  if os_type == "windows" then
    check_cmd = string.format('where %s >nul 2>&1', cmd)
  else
    check_cmd = string.format('command -v %s >/dev/null 2>&1', cmd)
  end

  local result = os.execute(check_cmd)
  return result == 0 or result == true
end

---Detect package manager on Linux
---@return string|nil Package manager command or nil if none found
local function detect_package_manager()
  local managers = {
    { cmd = "apt-get", install = "apt-get install -y" },
    { cmd = "dnf",     install = "dnf install -y" },
    { cmd = "yum",     install = "yum install -y" },
    { cmd = "pacman",  install = "pacman -S --noconfirm" },
    { cmd = "zypper",  install = "zypper install -y" },
    { cmd = "apk",     install = "apk add" },
  }

  for _, manager in ipairs(managers) do
    if command_exists(manager.cmd) then
      return manager.install
    end
  end

  return nil
end

---Install required dependencies (curl and unzip)
---@return boolean success True if dependencies are available or were installed successfully
local function ensure_dependencies()
  local os_type = detect_os()
  local missing = {}

  -- Check for curl
  if not command_exists("curl") then
    table.insert(missing, "curl")
  end

  -- Check for unzip (not needed on Windows with PowerShell)
  if os_type ~= "windows" and not command_exists("unzip") then
    table.insert(missing, "unzip")
  end

  -- All dependencies present
  if #missing == 0 then
    return true
  end

  wezterm.log_info(string.format("Missing dependencies: %s", table.concat(missing, ", ")))

  -- Install missing dependencies based on OS
  if os_type == "linux" then
    local pkg_manager = detect_package_manager()

    if not pkg_manager then
      wezterm.log_error("Could not detect package manager. Please install: " .. table.concat(missing, ", "))
      return false
    end

    wezterm.log_info("Installing dependencies with package manager...")
    local install_cmd = string.format("sudo %s %s", pkg_manager, table.concat(missing, " "))
    local result = os.execute(install_cmd)

    if result ~= 0 and result ~= true then
      wezterm.log_error("Failed to install dependencies. Please run manually: " .. install_cmd)
      return false
    end
  elseif os_type == "macos" then
    -- Check if Homebrew is available
    if not command_exists("brew") then
      wezterm.log_error("Homebrew not found. Please install Homebrew first: https://brew.sh")
      return false
    end

    wezterm.log_info("Installing dependencies with Homebrew...")
    for _, dep in ipairs(missing) do
      local install_cmd = string.format("brew install %s", dep)
      local result = os.execute(install_cmd)

      if result ~= 0 and result ~= true then
        wezterm.log_error(string.format("Failed to install %s with Homebrew", dep))
        return false
      end
    end
  elseif os_type == "windows" then
    -- Windows: try to install via winget or chocolatey
    if command_exists("winget") then
      wezterm.log_info("Installing dependencies with winget...")
      for _, dep in ipairs(missing) do
        local install_cmd = string.format("winget install -e --id %s",
          dep == "curl" and "cURL.cURL" or "GnuWin32.UnZip")
        local result = os.execute(install_cmd)

        if result ~= 0 and result ~= true then
          wezterm.log_warn(string.format("Failed to install %s with winget", dep))
        end
      end
    elseif command_exists("choco") then
      wezterm.log_info("Installing dependencies with Chocolatey...")
      for _, dep in ipairs(missing) do
        local install_cmd = string.format("choco install %s -y", dep)
        local result = os.execute(install_cmd)

        if result ~= 0 and result ~= true then
          wezterm.log_warn(string.format("Failed to install %s with Chocolatey", dep))
        end
      end
    else
      wezterm.log_error("No package manager found. Please install curl manually or install winget/chocolatey")
      return false
    end
  end

  -- Verify installation
  for _, dep in ipairs(missing) do
    if not command_exists(dep) then
      wezterm.log_error(string.format("%s is still not available after installation attempt", dep))
      return false
    end
  end

  wezterm.log_info("All dependencies installed successfully")
  return true
end

---Get the user font directory based on OS
---@return string
local function get_font_dir()
  local os_type = detect_os()
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
local function is_jetbrains_font_installed()
  -- Try to create a font with the specific family
  local success, _ = pcall(function()
    return wezterm.font("JetBrainsMono Nerd Font")
  end)

  return success
end

---Download and install JetBrainsMono Nerd Font
---@return boolean success True if installation succeeded or font already exists
local function ensure_jetbrains_font()
  if is_jetbrains_font_installed() then
    wezterm.log_info("JetBrainsMono Nerd Font is already installed")
    return true
  end

  wezterm.log_info("JetBrainsMono Nerd Font not found, attempting to install...")

  -- Ensure dependencies are available
  if not ensure_dependencies() then
    wezterm.log_error("Cannot install font: required dependencies are missing")
    return false
  end

  local font_dir = get_font_dir()
  local os_type = detect_os()
  local font_url = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  local temp_dir = os.getenv("TEMP") or os.getenv("TMPDIR") or "/tmp"
  local zip_path = temp_dir .. "/JetBrainsMono.zip"

  -- Create font directory if it doesn't exist
  local mkdir_cmd
  if os_type == "windows" then
    mkdir_cmd = string.format('powershell -Command "New-Item -ItemType Directory -Force -Path \'%s\'"', font_dir)
  else
    mkdir_cmd = string.format("mkdir -p '%s'", font_dir)
  end
  os.execute(mkdir_cmd)

  -- Download the font
  local download_cmd
  if os_type == "windows" then
    download_cmd = string.format(
      'powershell -Command "Invoke-WebRequest -Uri \'%s\' -OutFile \'%s\'"',
      font_url,
      zip_path
    )
  else
    download_cmd = string.format("curl -L '%s' -o '%s'", font_url, zip_path)
  end

  local download_result = os.execute(download_cmd)
  if download_result ~= 0 and download_result ~= true then
    wezterm.log_error("Failed to download JetBrainsMono Nerd Font")
    return false
  end

  -- Extract the font
  local extract_cmd
  if os_type == "windows" then
    extract_cmd = string.format(
      'powershell -Command "Expand-Archive -Path \'%s\' -DestinationPath \'%s\' -Force"',
      zip_path,
      font_dir
    )
  else
    extract_cmd = string.format("unzip -o '%s' -d '%s'", zip_path, font_dir)
  end

  local extract_result = os.execute(extract_cmd)
  if extract_result ~= 0 and extract_result ~= true then
    wezterm.log_error("Failed to extract JetBrainsMono Nerd Font")
    return false
  end

  -- Clean up zip file
  local cleanup_cmd
  if os_type == "windows" then
    cleanup_cmd = string.format('del "%s"', zip_path)
  else
    cleanup_cmd = string.format("rm '%s'", zip_path)
  end
  os.execute(cleanup_cmd)

  -- Update font cache on Linux
  if os_type == "linux" then
    os.execute("fc-cache -f")
  end

  wezterm.log_info("JetBrainsMono Nerd Font installed successfully")
  wezterm.log_warn("Please restart WezTerm for the font changes to take effect")

  return true
end

---Configure font settings for WezTerm including size, family, and OpenType features
---@param Config WezTermConfig The WezTerm configuration table
---@return nil
return function(Config)
  -- Ensure JetBrainsMono Nerd Font is available
  ensure_jetbrains_font()

  ---Base font size in points
  Config.font_size = 12

  ---Font fallback list with typographic options
  Config.font = wezterm.font_with_fallback {
    -- Primary programming font
    {
      family = "JetBrainsMono Nerd Font",
      weight = "Regular",
      harfbuzz_features = {
        -- Character variants for better developer ergonomics:
        "cv06", -- i: alternate glyph
        "cv12", -- 0: slashed zero
        "cv14", -- 3: alternate 3
        "cv16", -- *: alternate asterisk
        "cv25", -- .-: dotted minus
        "cv26", -- :-: alternate colon-dash
        "cv28", -- {. .}: open/close brace variant
        "cv29", -- { }: normal brace variant
        "cv31", -- (): alternate parentheses
        "cv32", -- .=: dotted equals
        -- Stylistic sets for operators and symbols:
        "ss03", -- &: alternate ampersand
        "ss04", -- $: alternate dollar sign
        "ss05", -- @: alternate at symbol
        "ss07", -- =~ !~: tilde variations
        "ss09", -- >>= <<= ||= |= etc.
      },
    },

    -- Emoji font fallback (required for color emoji support)
    { family = "Noto Color Emoji" },

    -- Optional retro font for box drawing or legacy code pages
    { family = "LegacyComputing" },
  }
end
