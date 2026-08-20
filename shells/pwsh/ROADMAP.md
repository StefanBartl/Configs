# Überblick: Powershell Optimierungspotenziale

## 🔴 KRITISCH (messbar, sofort spürbar)

| # | Bereich | Problem | Lösung |
|---|---------|---------|--------|
| 1 | **Modul-Import (OneDrive)** | `Import-Module MyCliHelpers` lädt aus `OneDrive\...\Modules\` — OneDrive-I/O ist langsam durch Sync-Layer, Cloud-Calls, Antivirus-Hooks | Lokalen Junction-Pfad (`$LOCALAPPDATA\PowerShell\Modules`) **vorne** in `$PSModulePath` einhängen; install-Script erstellt dort Junction → kein OneDrive-Kontakt mehr |
| 2 | **Starship: git.exe-Timeout** | `command_timeout = 500ms` (Standard) — auf Windows mit AV/Corporate-Git viel zu knapp | `starship.toml`: `command_timeout = 2000` |
| 3 | **Starship: Directory-Scan-Timeout** | Große Repos (WKDBooks, Notes) lösen `scan_timeout` aus | `scan_timeout = 30000` + `ignore_submodules = true` in `starship.toml` |
| 4 | **Cache-TTL zu kurz** | Starship/Zoxide-Init täglich neu ausgeführt — jeder Neustart ohne frischen Cache kostet 1–3 s extra | TTL auf 7 Tage anheben |
| 5 | **`$env:TEMP` als Cache-Ort** | Wird manchmal automatisch geleert → zwingt zur Neuinitialisierung | Cache nach `$LOCALAPPDATA\pwsh\cache\` verschieben (persistent, lokal, nie OneDrive) |
| 6 | **`ls`-Befehl-Lookup bei jedem Aufruf** | `Get-Command 'ls.exe'` + `Get-Command 'ls'` werden **jedes Mal** bei `ls` aufgerufen — 2× Command-Discovery | Command einmalig beim Modul-Load cachen (`$script:_lsExe`) |
| 7 | **`Test-HasCommand` ohne Cache** | Wird mehrfach für 'starship', 'zoxide' etc. aufgerufen — jedes Mal `Get-Command` + winget-Fallback | Session-Dictionary als Cache (`[Dictionary[string,bool]]`) |

## 🟡 SINNVOLL (Korrektheit & Wartbarkeit)

| # | Bereich | Problem | Lösung |
|---|---------|---------|--------|
| 8 | **Hardcoded Pfade in MyCliHelpers** | `C:\Users\StefanBartl\...` in `nvim-config`, `nvim-data`; `C:\repos` in `repos`, `Configs` | `$env:LOCALAPPDATA`, `$env:REPOS_DIR` |
| 9 | **`Elevate-Shell` öffnet PS5** | `Start-Process powershell.exe` — startet Windows PowerShell 5.x statt die aktuelle pwsh-Version | `(Get-Process -Id $PID).MainModule.FileName` für auto-detektierten Pfad |
| 10 | **`Get-Module PSReadLine` doppelt aufgerufen** | Im Profil zweimal abgefragt (Check + Version) | Einmal cachen in Variable |
| 11 | **`$env:PSModulePath` kein Split-Check** | Pfad wird bei wiederholtem Laden doppelt eingetragen | Bereits vorhanden? `notlike`-Guard |
| 12 | **install-DOTFILES.ps1: nur OneDrive-Pfad** | Modul-Junction landet auf OneDrive — triggert das Performance-Problem bei jedem Import | Lokaler Junction-Pfad als primäres Ziel |
| 13 | ~~**install-DOTFILES.ps1: Datei-Symlink ohne Admin scheitert**~~ ✅ 2026-08-20 | `New-Item -ItemType SymbolicLink` für Dateien braucht Admin oder Developer Mode. `cmd /c mklink` ebenso | Gelöst in `install/install.ps1`: Verzeichnisse als Junction, Dateien Symlink → Hardlink → Kopie (Kopie wird gewarnt) |

## 🟢 DISKUTABEL (Architektur, Tools, Konzepte)

| # | Bereich | Problem / Frage | Option |
|---|---------|----------------|--------|
| 16 | **Lazy-Loading des Moduls** | `Import-Module MyCliHelpers` lädt alle Funktionen beim Start — auch jene, die nur selten genutzt werden | Stub-Funktionen, die das Modul erst beim ersten echten Aufruf laden |
| 17 | **`MyCliHelpers` als PSM1 vs. einzelne PS1-Files** | Großes Modul → alles oder nichts geladen | Aufteilen in Sub-Module (Navigation, Clipboard, FileSystem…) und nur benötigte lazy laden |
| 18 | **`Invoke-CachedInit` als eigene Hilfsfunktion** | Starship- und Zoxide-Init-Logik ist identisch dupliziert | Refaktor in gemeinsame `Update-InitCache`-Funktion |
| 19 | **`gg`-Funktion vs. `rg`** | `Select-String` in `gg` ist langsam bei großen Verzeichnissen; `rg` (ripgrep) ist um Größenordnungen schneller | Wenn `rg` verfügbar: `gg` darauf delegieren |
| 20 | **Kein `checkhealth`-Äquivalent** | Kein Diagnose-Tool um zu sehen welche Abhängigkeiten fehlen | `Test-ProfileHealth`-Funktion: prüft starship, zoxide, rg, nvim, etc. |
| 21 | **PSReadLine `Get-Module -ListAvailable`** | `-ListAvailable` scannt Filesystem (alle PSModulePath-Einträge) — kostspielig | Stattdessen `Get-Module` ohne `-ListAvailable` (nur geladene Module) |
| 22 | **Kein `$ErrorActionPreference = 'Continue'`-Guard** | Profile-Fehler können nachfolgende Initialisierungen abbrechen | `$ErrorActionPreference` zu Beginn sichern, am Ende wiederherstellen |
| 23 | **`Copy-LastOutput` re-evaluiert History** | `Invoke-Expression $last` wertet den letzten Befehl **nochmals aus** | Potentiell gefährlich (idempotenz nicht garantiert); besser: `(Get-History)[-1]` Output direkt cachen |
| 24 | **Cache-Invalidierung durch Tool-Version** | 7-Tage-TTL invalidiert Cache auch wenn sich das Tool nicht geändert hat (und umgekehrt nicht, wenn es sich geändert hat) | Version-Hash als Cache-Key (`starship --version` → Cache-Dateiname) |
| 25 | **Kein Cross-Platform-Guard** | Modul-Funktionen wie `Open-Explorer`, `Elevate-Shell` sind Windows-only — keine Fehlermedlung auf Linux/Mac | `if ($IsWindows)` Guards oder explizite Platform-Checks |

---

