## Tastenbelegung in WezTerm – Standard-Keymaps nach Themen (mit deutscher Erklärung)

Diese Tabelle fasst die [Standard-Keybindings](https://wezterm.org/config/default-keys.html) von WezTerm zusammen – übersichtlich sortiert nach Funktionsgruppe, inklusive deutscher Beschreibung und Besonderheiten zur Taste `SUPER`.

---

### Was ist `SUPER`?

* **Unter Linux**: Meist die **Windows-Taste**
* **Unter macOS**: Die **Command-Taste (⌘)**
* **Unter Windows**: WezTerm verwendet **nicht automatisch die Windows-Taste** – das funktioniert **nur**, wenn `wezterm-gui` im "elevated mode" läuft, oder man mappt `SUPER` manuell (nicht empfohlen).
  → Auf Windows daher besser mit `CTRL+SHIFT` arbeiten.

---

### Spezialfunktionen kurz erklärt

| Funktion                 | Bedeutung                                                              |
| ------------------------ | ---------------------------------------------------------------------- |
| `ShowDebugOverlay`       | Zeigt ein Overlay mit Performance-Daten, Framezeit, Zeichenzähler etc. |
| `ActivateCommandPalette` | Öffnet eine Eingabezeile für WezTerm-Befehle (ähnlich wie bei VS Code) |
| `CharSelect`             | Ein UI-Fenster zum Einfügen von Unicode-Zeichen über Auswahl           |

---

## Übersicht nach Funktionsthemen

### Tabs verwalten

| Tastenkombination      | Aktion                        | Beschreibung (Deutsch)                           |
| ---------------------- | ----------------------------- | ------------------------------------------------ |
| SUPER+SHIFT+T          | SpawnTab="DefaultDomain"      | Neuen Tab mit Standard-Domain öffnen             |
| SUPER+t                | SpawnTab="CurrentPaneDomain"  | Neuen Tab in der aktuellen Domain starten        |
| CTRL+SHIFT+t           | SpawnTab="CurrentPaneDomain"  | Wie oben, aber mit alternativer Taste            |
| SUPER+w                | CloseCurrentTab{confirm=true} | Aktuellen Tab schließen (mit Bestätigungsdialog) |
| CTRL+SHIFT+w           | CloseCurrentTab{confirm=true} | Alternative zum Schließen                        |
| SUPER+1 / SUPER+2      | ActivateTab=0 / 1             | Aktiviere Tab 1 bzw. Tab 2                       |
| CTRL+SHIFT+1 / +2      | ActivateTab=0 / 1             | Alternative zum Wechseln zu Tab 1/2              |
| SUPER+SHIFT+\[ / ]     | ActivateTabRelative=-1 / +1   | Vorherigen / nächsten Tab aktivieren             |
| CTRL+SHIFT+Tab         | ActivateTabRelative=-1        | Tab zurück                                       |
| CTRL+Tab               | ActivateTabRelative=1         | Tab vor                                          |
| CTRL+PageUp/PageDown   | Tab vor/zurück                | Alternative Navigation                           |
| CTRL+SHIFT+PageUp/Down | MoveTabRelative=-1 / +1       | Tab nach links/rechts verschieben                |

---

### Fenster und Instanzen

| Tastenkombination | Aktion           | Beschreibung (Deutsch)        |
| ----------------- | ---------------- | ----------------------------- |
| SUPER+n           | SpawnWindow      | Neues Terminalfenster starten |
| CTRL+SHIFT+n      | SpawnWindow      | Alternative                   |
| ALT+Enter         | ToggleFullScreen | Vollbildmodus an/aus          |

---

### Pane-Splitting & Navigation

| Tastenkombination         | Aktion                                | Beschreibung (Deutsch)                                    |
| ------------------------- | ------------------------------------- | --------------------------------------------------------- |
| CTRL+SHIFT+ALT+`"`        | SplitVertical={"CurrentPaneDomain"}   | Splitte aktuelles Pane **vertikal**                       |
| CTRL+SHIFT+ALT+`%`        | SplitHorizontal={"CurrentPaneDomain"} | Splitte **horizontal**                                    |
| CTRL+SHIFT+ALT+Pfeiltaste | AdjustPaneSize={"Richtung", 1}        | Verändere Größe des aktuellen Panes in gegebener Richtung |
| CTRL+SHIFT+Pfeiltaste     | ActivatePaneDirection="Richtung"      | Wechsle Fokus zum angrenzenden Pane                       |
| CTRL+SHIFT+Z              | TogglePaneZoomState                   | Aktuelles Pane maximieren / normal anzeigen               |

---

### Suche & Scrollen

| Tastenkombination | Aktion                          | Beschreibung (Deutsch)              |
| ----------------- | ------------------------------- | ----------------------------------- |
| SUPER+f           | Search={CaseSensitiveString=""} | Suche nach String (nicht sensitiv)  |
| CTRL+SHIFT+f      | Wie oben                        | Alternative                         |
| SHIFT+PageUp/Down | ScrollByPage=-1 / 1             | Eine Seite nach oben/unten scrollen |

---

### Interaktive Modi & UI-Features

| Tastenkombination | Aktion                 | Beschreibung (Deutsch)                                        |
| ----------------- | ---------------------- | ------------------------------------------------------------- |
| CTRL+SHIFT+L      | ShowDebugOverlay       | Overlay mit Debug/Performance-Infos einblenden                |
| CTRL+SHIFT+P      | ActivateCommandPalette | Befehlspalette öffnen (z. B. `SplitPane`, `Reload`, `Search`) |
| CTRL+SHIFT+U      | CharSelect             | Unicode-Zeichenauswahl anzeigen                               |
| CTRL+SHIFT+X      | ActivateCopyMode       | Copy-Modus aktivieren (wie in `tmux`)                         |
| CTRL+SHIFT+Space  | QuickSelect            | Selektiere Muster aus der aktuellen Zeile                     |

---

## Hinweis: Verhalten unter Windows

Einige Tastenkombinationen, z. B. mit `SUPER`, können auf **Windows nicht funktionieren**, wenn:

* WezTerm **nicht als Administrator** läuft
* Die Windows-Taste von der Shell abgefangen wird

Alternativen:

* Verwende `CTRL+SHIFT` für zuverlässige Tastenkombinationen
* Oder passe die `key_bindings` manuell an, z. B.:

```lua
-- In deiner wezterm.lua
keys = {
  {
    key = "n",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SpawnWindow,
  },
}
```

---