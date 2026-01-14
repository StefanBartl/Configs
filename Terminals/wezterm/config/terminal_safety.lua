---@module 'config.terminal_safety'
--- WezTerm settings to mitigate terminal / TUI desync issues on Windows.
---
--- Ziel:
--- - Verhindern, dass Fokus-, Paste- oder Mode-Escape-Sequenzen als Text
---   in Neovim landen (klassische CSI/OSC-Leaks).
--- - Reduktion von Win32-IME / Dead-Key / Focus-Notify Problemen.
--- - Stabilisierung beim App-Wechsel (Alt-Tab).

---@param Config table
---@return nil
return function(Config)
  ---------------------------------------------------------------------------
  -- WICHTIG: Ursache des Problems
  --
  -- Die beschriebenen Symptome sind fast immer eine Kombination aus:
  -- - Fokus-Events (CSI ?1004h / ?1004l)
  -- - Bracketed-Paste-Mode (^[[200~)
  -- - Win32 IME / Dead Keys
  -- - Alt / Meta Komposition
  --
  -- Wenn WezTerm oder Windows beim Fokuswechsel eine Sequenz verliert,
  -- interpretiert Neovim rohe Escape-Sequenzen als Text.
  ---------------------------------------------------------------------------

  ---------------------------------------------------------------------------
  -- Fokus-Ereignisse
  --
  -- Das ist der wichtigste Fix.
  -- Deaktiviert CSI focus gained/lost komplett.
  ---------------------------------------------------------------------------
  Config.enable_focus_events = false

  ---------------------------------------------------------------------------
  -- Dead Keys / IME
  --
  -- Verhindert, dass Windows Dead-Key-Kompositionen Escape-States brechen.
  ---------------------------------------------------------------------------
  Config.use_dead_keys = false

  ---------------------------------------------------------------------------
  -- Alt / Meta Verhalten
  --
  -- Wichtig bei NeoVim + Mappings (<A-*>).
  -- Verhindert rohe ESC + Key Sequenzen.
  ---------------------------------------------------------------------------
  Config.send_composed_key_when_left_alt_is_pressed = false

  ---------------------------------------------------------------------------
  -- Standard-Keybindings
  --
  -- Diese sollten NICHT deaktiviert werden.
  -- Clipboard- und Sicherheitsbindings helfen bei Recovery.
  ---------------------------------------------------------------------------
  Config.disable_default_key_bindings = false

  ---------------------------------------------------------------------------
  -- WIN32 INPUT MODE
  --
  -- allow_win32_input_mode EXISTIERT NICHT in WezTerm.
  --
  -- Der korrekte Mechanismus ist:
  --   - IME explizit deaktivieren
  --   - focus events aus
  --   - dead keys aus
  --
  -- WezTerm nutzt intern Win32 input APIs, das ist NICHT konfigurierbar.
  ---------------------------------------------------------------------------

  ---------------------------------------------------------------------------
  -- Optional, aber empfohlen:
  -- Verhindert, dass Anwendungen den Mausmodus aggressiv ändern
  ---------------------------------------------------------------------------
  Config.allow_square_glyphs_to_overflow_width = false
end

