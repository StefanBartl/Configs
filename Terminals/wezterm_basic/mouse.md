## Maustastenbelegung in WezTerm – Standardverhalten (mit deutscher Erklärung)

Diese Übersicht fasst das Standardverhalten von Maustasten in [WezTerm](https://wezterm.org/config/mouse.html) zusammen. Die Aktionen sind abhängig von Klickart (einfach, doppelt, dreifach), gedrückten Modifikatoren und der Position des Mauszeigers im Terminal.

---

### Legende der Aktionen

| Aktion                                              | Beschreibung (Deutsch)                                                    |
| --------------------------------------------------- | ------------------------------------------------------------------------- |
| `act.SelectTextAtMouseCursor("X")`                  | Beginnt Auswahl des Textes um den Cursor: `Cell`, `Word`, `Line`, `Block` |
| `act.ExtendSelectionToMouseCursor("X")`             | Erweitert bestehende Auswahl bis zur Mausposition                         |
| `act.CompleteSelection(...)`                        | Beendet die Auswahl und speichert sie in die Zwischenablage               |
| `act.CompleteSelectionOrOpenLinkAtMouseCursor(...)` | Öffnet Link oder speichert Text in die Zwischenablage                     |
| `act.PasteFrom("PrimarySelection")`                 | Fügt Text ein (X11 Primary Selection, v.a. Linux)                         |
| `act.StartWindowDrag`                               | Ermöglicht Drag & Drop des Fensters (ohne Titelleiste)                    |

---

## Auswahlverhalten mit linker Maustaste

| Ereignis             | Modifikator | Aktion                                                |
| -------------------- | ----------- | ----------------------------------------------------- |
| **Single Left Down** | *keiner*    | Beginne Auswahl auf Zelle                             |
|                      | `SHIFT`     | Erweiterung der bestehenden Auswahl ab Cursorposition |
|                      | `ALT`       | Blockauswahl (rechteckig) (seit 20220624)             |
|                      | `ALT+SHIFT` | Erweiterung als Blockauswahl                          |
| **Double Left Down** | *keiner*    | Auswahl eines ganzen Wortes                           |
| **Triple Left Down** | *keiner*    | Auswahl einer ganzen Zeile                            |

---

## Auswahl beenden

| Ereignis           | Modifikator | Aktion                                                      |
| ------------------ | ----------- | ----------------------------------------------------------- |
| **Single Left Up** | *keiner*    | Auswahl beenden oder Link öffnen, Text kopieren             |
|                    | `SHIFT`     | Wie oben, alternativ                                        |
|                    | `ALT`       | Auswahl explizit beenden und kopieren (nur Text, kein Link) |
|                    | `ALT+SHIFT` | Blockauswahl beenden und kopieren                           |
| **Double Left Up** | *keiner*    | Wortauswahl beenden und kopieren                            |
| **Triple Left Up** | *keiner*    | Zeilenauswahl beenden und kopieren                          |

---

## Ziehen mit linker Maustaste

| Ereignis             | Modifikator  | Aktion                                                       |
| -------------------- | ------------ | ------------------------------------------------------------ |
| **Single Left Drag** | *keiner*     | Ziehe Auswahl ab aktueller Zelle                             |
|                      | `ALT`        | Rechteckige Blockauswahl (seit 20220624)                     |
|                      | `ALT+SHIFT`  | Erweiterung rechteckige Auswahl                              |
|                      | `SUPER`      | Fenster verschieben (wenn keine Titelleiste) (seit 20210314) |
|                      | `CTRL+SHIFT` | Fenster verschieben (Alternative für Windows)                |
| **Double Left Drag** | *keiner*     | Ziehe Wortauswahl                                            |
| **Triple Left Drag** | *keiner*     | Ziehe Zeilenauswahl                                          |

---

## Weitere Aktionen

| Ereignis           | Modifikator | Aktion                        | Beschreibung                                        |
| ------------------ | ----------- | ----------------------------- | --------------------------------------------------- |
| Single Middle Down | *keiner*    | PasteFrom("PrimarySelection") | Fügt Text aus Primär-Zwischenablage (Linux/X11) ein |

---

## Hinweise zu Plattformunterschieden

* **SUPER** (Window-Drag) funktioniert nur dann zuverlässig, wenn:

  * Das WezTerm-Fenster **keine native Titelleiste** hat
  * WezTerm mit GUI läuft
* **PrimarySelection** funktioniert **nur auf Linux/X11**, nicht auf Windows/macOS
* **Fenster-Drag via SUPER oder CTRL+SHIFT** ist für Nutzer mit `hide_tab_bar_if_only_one_tab = true` nützlich

---