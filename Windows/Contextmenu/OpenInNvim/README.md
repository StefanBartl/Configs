# README.md für OpenInNvim

Einfacher Windows-Explorer-Kontextmenüeintrag „Open with Neovim (new instance)“.
Architektur: Explorer → VBS (unsichtbar) → PowerShell → nvim (immer neue Instanz).
Getestet für Windows PowerShell 5.1.

## Link setzen

```powershell
New-Item -ItemType Junction -Path 'C:\tools\OpenInNvim' -Target 'E:\repos\Configs\Windows\Contextmenu\OpenInNvim'
```

## Ziele

- Nur ein Menüeintrag: „Open with Neovim (new instance)“
- Zentrale Konfiguration der Binärpfade (nvim, optional wezterm)
- Robustes Pfad- und Quoting-Handling (Leerzeichen, neue Dateien)
- Kein nvr/Remote-Attach (kommt später)

## Verzeichnisstruktur

Physische Ablage (Empfehlung für Repos):
E:\repos\Configs\Windows\Contextmenu\OpenInNvim

Kompatibilitätslink für Registry (Junction):
C:\tools\OpenInNvim  →  E:\repos\Configs\Windows\Contextmenu\OpenInNvim

Inhalt:
C:\tools\OpenInNvim\
  open-in-nvim.vbs
  open-in-nvim.ps1
  open-in-nvim.config.ps1
  install-context.ps1
  add-new.reg
  remove-old.reg
  verify.ps1

## Installation

1) Dateien ablegen
   Dateien unter E:\repos\Configs\Windows\Contextmenu\OpenInNvim verwalten.

2) Junction anlegen (empfohlen)
   cmd.exe:
   rmdir /S /Q C:\tools\OpenInNvim
   mklink /J C:\tools\OpenInNvim E:\repos\Configs\Windows\Contextmenu\OpenInNvim

   PowerShell:
   Remove-Item -LiteralPath 'C:\tools\OpenInNvim' -Recurse -Force -ErrorAction SilentlyContinue
   New-Item -ItemType Junction -Path 'C:\tools\OpenInNvim' -Target 'E:\repos\Configs\Windows\Contextmenu\OpenInNvim'

3) Kontextmenü einrichten
   Variante A (.reg):
   - remove-old.reg importieren
   - add-new.reg importieren

   Variante B (Skript):
   - PowerShell (User reicht):
     powershell -ExecutionPolicy Bypass -File "C:\tools\OpenInNvim\install-context.ps1"

1) Explorer neu starten
   taskkill /F /IM explorer.exe
   explorer.exe

## Konfiguration

Datei: open-in-nvim.config.ps1

```powershell
# Central configuration for "Open with Neovim (new instance)".
$Cfg = [ordered]@{
  # Absolute path to Neovim; if not present, script tries "nvim" from PATH.
  NVIM_BIN    = 'C:\Program Files\Neovim\bin\nvim.exe'

  # Optional terminal preference; launch order:
  # 1) WezTerm GUI exe  2) Windows Terminal "wt"  3) plain cmd.exe "start"
  WEZTERM_BIN = "$env:LOCALAPPDATA\wezterm\wezterm-gui.exe"
}
````

Bei Scoop/Winget/Portable ggf. NVIM_BIN auf den realen Pfad setzen.

## Funktionsweise

* open-in-nvim.vbs startet Windows PowerShell versteckt mit:
  C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\tools\OpenInNvim\open-in-nvim.ps1" "%1"
* open-in-nvim.ps1 ermittelt Ziel (Datei/Ordner/Hintergrund), setzt korrektes Working Directory, baut Argumente und startet nvim:

  1. WezTerm (wenn vorhanden)
  2. Windows Terminal (`wt`)
  3. Fallback: `cmd.exe /c start` (detached)
* Es wird stets eine neue Neovim-Instanz gestartet.

## Schneller Test

PowerShell direkt (prüft nur die PS1):
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\tools\OpenInNvim\open-in-nvim.ps1" "$env:USERPROFILE\Desktop\test.txt"

VBS-Kette (entspricht Explorer):
wscript //nologo "C:\tools\OpenInNvim\open-in-nvim.vbs" "%USERPROFILE%\Desktop\test.txt"

## Troubleshooting

* Beim Klick „passiert nichts“:

  * Teste direkt:
    powershell -NoProfile -ExecutionPolicy Bypass -File "C:\tools\OpenInNvim\open-in-nvim.ps1" "$env:USERPROFILE\Desktop\test.txt"
  * NVIM_BIN in open-in-nvim.config.ps1 prüfen/anpassen.
  * WezTerm/Windows Terminal vorhanden? Sonst greift der `cmd.exe /c start`-Fallback.
  * Optional Debug:
    setx OPEN_IN_NVIM_DEBUG 1
    (zeigt kurze Hinweise per cmd-Fenster)

## Deinstallation

* Kontextmenü löschen:
  * remove-old.reg importieren
  * oder install-context.ps1 anpassen/ausführen (nur Remove-Key-Pfad)
* Junction entfernen:
  Remove-Item -LiteralPath 'C:\tools\OpenInNvim' -Recurse -Force

## Roadmap

* Optionaler Modus „current instance via nvr / remote session“
* Selektierbares Terminal (wezterm/wt/cmd) per Config-Flag
* Optionales Logging in %TEMP%\open-in-nvim.log
* Wenn Klick auf Verzeichnis im Kontextmenu: im Neotree öffnen

---
