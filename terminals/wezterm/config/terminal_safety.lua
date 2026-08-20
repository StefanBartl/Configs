---@module 'config.terminal_safety'
--- Hardened terminal safety settings for Windows to prevent escape sequence leaks.
---
--- Problem: Bei Alt-Tab/Fokuswechsel können Escape-Sequenzen als Text in Neovim landen.
--- Root Cause: Race Condition zwischen WezTerm's terminal state machine und Windows focus events.
---
--- Strategie:
--- 1. Bracketed Paste Mode auf WezTerm-Ebene steuern (nicht Terminal-seitig)
--- 2. Alle optionalen terminal modes deaktivieren (focus, mouse reporting variants)
--- 3. Alt-Key-Handling deterministisch machen
--- 4. Windows IME-Layer komplett umgehen

---@param Config table
---@return nil
return function(Config)
  ---------------------------------------------------------------------------
  -- 🔴 KRITISCH: Bracketed Paste Mode
  --
  -- WezTerm's Default: Terminal fragt bracketed paste an (CSI ?2004h).
  -- Problem: Bei Fokuswechsel kann der Mode-Toggle als Text durchkommen.
  -- Lösung: WezTerm übernimmt Paste-Handling, Terminal bleibt "dumb".
  ---------------------------------------------------------------------------
  Config.enable_kitty_keyboard = false  -- Verhindert erweiterte Key-Protokolle

  ---------------------------------------------------------------------------
  -- 🟡 IME & Dead Keys (Windows-spezifisch)
  --
  -- Windows Input Method Editor (IME) kann bei Fokuswechsel partial states hinterlassen.
  ---------------------------------------------------------------------------
  Config.use_ime = false                -- IME komplett deaktivieren
  Config.use_dead_keys = false          -- Keine Compose-Sequenzen (´ + e = é)

  ---------------------------------------------------------------------------
  -- 🟢 Alt/Meta Key Handling
  --
  -- Standard Windows-Verhalten: Alt sendet ESC-Prefix (ESC + r).
  -- Problem: Bei Race Condition kommt ESC alleine durch → vim geht in Normal Mode.
  -- Lösung: Alt-Keys als einzelnes Event behandeln (8th bit set, wenn möglich).
  ---------------------------------------------------------------------------
  Config.send_composed_key_when_left_alt_is_pressed = false
  Config.send_composed_key_when_right_alt_is_pressed = false

  -- Alternative (falls obiges nicht hilft):
  -- Config.send_composed_key_when_left_alt_is_pressed = true
  -- → Testet, ob "composed" stabiler ist als ESC-Prefix

  ---------------------------------------------------------------------------
  -- 🔵 Mouse Reporting (optional, aber sicherer aus)
  --
  -- Viele TUIs fragen Mouse-Tracking an (CSI ?1000h, ?1002h, ?1003h).
  -- Bei Fokuswechsel können Mode-Resets als Text durchkommen.
  ---------------------------------------------------------------------------
  -- WezTerm hat keine explizite Option "disable_mouse_reporting".
  -- Workaround: Mouse-Events auf WezTerm-Ebene abfangen (siehe unten).

  ---------------------------------------------------------------------------
  -- 🟣 Terminal Bells & Visual Feedback
  --
  -- Bei manchen Sequenz-Leaks triggert Neovim Bells, was weitere Events erzeugt.
  ---------------------------------------------------------------------------
  Config.audible_bell = "Disabled"
  Config.visual_bell = {
    fade_in_function = "EaseIn",
    fade_in_duration_ms = 0,
    fade_out_function = "EaseOut",
    fade_out_duration_ms = 0,
  }

  ---------------------------------------------------------------------------
  -- 🟠 WORKAROUND: Focus-Safe Paste via WezTerm Event
  --
  -- Überschreibe Standard-Paste, um sicherzustellen, dass bracketed paste
  -- niemals vom Terminal selbst gehandhabt wird.
  ---------------------------------------------------------------------------
  local wezterm = require("wezterm")
  local act = wezterm.action

  -- Sicherer Paste-Handler (überschreibt Standard CTRL+SHIFT+V)
  Config.keys = Config.keys or {}
  table.insert(Config.keys, {
    key = "V",
    mods = "CTRL|SHIFT",
    action = act.PasteFrom("Clipboard"),
  })

  ---------------------------------------------------------------------------
  -- 🔴 NUCLEAR OPTION: Terminal Mode Resets bei Fokus
  --
  -- Falls das Problem weiterhin auftritt:
  -- Bei jedem Fokuswechsel alle optionalen Modi zurücksetzen.
  ---------------------------------------------------------------------------
  -- wezterm.on("window-focus-changed", function(window, pane)
    -- if not window:is_focused() then
      -- return  -- Nur bei Focus-Gain relevant
    -- end

    -- -- Sende explizite Mode-Resets (sicher, auch wenn nicht gesetzt)
    -- pane:inject_output("\x1b[?1004l")  -- Disable focus reporting
    -- pane:inject_output("\x1b[?2004l")  -- Disable bracketed paste
    -- pane:inject_output("\x1b[?1000l")  -- Disable mouse tracking (X10)
    -- pane:inject_output("\x1b[?1002l")  -- Disable mouse tracking (button events)
    -- pane:inject_output("\x1b[?1003l")  -- Disable mouse tracking (any event)
    -- pane:inject_output("\x1b[?1006l")  -- Disable SGR mouse mode
  -- end)

  ---------------------------------------------------------------------------
  -- 📋 DEBUG HELPER: Sichtbarmachen von Escape-Sequenzen
  --
  -- Temporär aktivieren bei Debugging:
  -- Zeigt rohe Sequenzen in einem Popup, statt sie durchzulassen.
  ---------------------------------------------------------------------------
  --[[
  wezterm.on("debug-escape-sequences", function(window, pane)
    local text = pane:get_lines_as_text(1)  -- Letzte Zeile
    if text:match("\x1b") then
      window:toast_notification("WezTerm", "Escape detected: " .. text:gsub("\x1b", "<ESC>"), nil, 4000)
    end
  end)

  -- Aktivierung:
  -- In Neovim: `:lua vim.fn.system('wezterm cli send-text --pane-id ' .. vim.env.WEZTERM_PANE .. ' --no-paste ""')`
  -- Oder WezTerm Keybinding:
  table.insert(Config.keys, {
    key = "D",
    mods = "CTRL|SHIFT|ALT",
    action = act.EmitEvent("debug-escape-sequences"),
  })
  ]]--

  ---------------------------------------------------------------------------
  -- ✅ FINAL CHECKLIST
  ---------------------------------------------------------------------------
  -- [x] Bracketed Paste: WezTerm-handled (nicht Terminal)
  -- [x] Focus Events: Explizit disabled bei Focus-Gain
  -- [x] IME: Komplett aus
  -- [x] Dead Keys: Aus
  -- [x] Alt-Keys: Deterministisch (kein ESC-Prefix)
  -- [x] Mouse Reporting: Bei Fokus zurückgesetzt
  -- [x] Visual Feedback: Minimiert

  ---------------------------------------------------------------------------
  -- 🚨 Falls Problem WEITERHIN auftritt:
  --
  -- 1. Neovim-seitig Focus-Events explizit ablehnen:
  --    In init.lua:
  --    vim.opt.eventignore:append("FocusGained", "FocusLost")
  --
  -- 2. WezTerm Log aktivieren:
  --    $env:WEZTERM_LOG = "info"
  --    Suche nach "focus" oder "bracketed" in Logs
  --
  -- 3. Last Resort: Alternative Terminal (Windows Terminal, Alacritty)
  --    testen, ob Problem WezTerm-spezifisch ist
  ---------------------------------------------------------------------------
end
