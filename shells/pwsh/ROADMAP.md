# Überblick: Powershell Optimierungspotenziale

> **Stand: 2026-08-20 — alle Punkte abgearbeitet.** Was umgesetzt wurde, steht
> in der Spalte „Ergebnis"; zwei Punkte wurden nach Messung bewusst verworfen.
> Diagnose zum Nachprüfen: `Test-ProfileHealth` (Alias `checkhealth`).

Dateien: [`Microsoft.PowerShell_profile.ps1`](Microsoft.PowerShell_profile.ps1),
[`Modules/MyCliHelpers/MyCliHelpers.psm1`](Modules/MyCliHelpers/MyCliHelpers.psm1),
[`../../prompt/starship.toml`](../../prompt/starship.toml),
[`../../install/install.ps1`](../../install/install.ps1)

## 🔴 KRITISCH (messbar, sofort spürbar)

| # | Bereich | Problem | Ergebnis |
|---|---------|---------|--------|
| 1 | **Modul-Import (OneDrive)** | `Import-Module MyCliHelpers` lädt aus `OneDrive\...\Modules\` — Sync-Layer, Cloud-Calls, Antivirus-Hooks | ✅ Profil Abschnitt 0 hängt `$LOCALAPPDATA\PowerShell\Modules` vorne in `$PSModulePath`; `install.ps1` legt die Junction dort an (siehe #12) |
| 2 | **Starship: git.exe-Timeout** | `command_timeout = 500ms` (Standard) — auf Windows mit AV/Corporate-Git zu knapp | ✅ `command_timeout = 2000` in `starship.toml` |
| 3 | **Starship: Directory-Scan-Timeout** | Große Repos lösen `scan_timeout` aus | ✅ `scan_timeout = 1000` + `ignore_submodules = true`. **Abweichung:** nicht die notierten `30000` — das wäre eine 30-Sekunden-Obergrenze, in der der Prompt bei hängendem Dateisystem blockiert. 1000 ms lösen das Problem, begrenzen den schlimmsten Fall aber auf eine Sekunde |
| 4 | **Cache-TTL zu kurz** | Starship/Zoxide-Init täglich neu ausgeführt | ✅ Siehe #24 — Invalidierung läuft jetzt primär über die Tool-Version, die TTL (90 Tage) ist nur noch Rückfallebene |
| 5 | **`$env:TEMP` als Cache-Ort** | Wird geleert → zwingt zur Neuinitialisierung | ✅ Cache in `$LOCALAPPDATA\pwsh\cache\` |
| 6 | **`ls`-Befehl-Lookup bei jedem Aufruf** | 2× Command-Discovery pro `ls` | ✅ `$script:_lsExe`, einmalig beim Modul-Load |
| 7 | **`Test-HasCommand` ohne Cache** | Jedes Mal `Get-Command` + winget-Fallback | ✅ `[Dictionary[string,bool]]` als Session-Cache, in Profil und Modul |

## 🟡 SINNVOLL (Korrektheit & Wartbarkeit)

| # | Bereich | Problem | Ergebnis |
|---|---------|---------|--------|
| 8 | **Hardcoded Pfade in MyCliHelpers** | `C:\Users\StefanBartl\...`, `C:\repos` | ✅ Alles aus Umgebungsvariablen. Plattformabhängiges liegt gebündelt in `Get-ReposRoot` und `Get-NvimDirectory` statt verstreut in den Funktionen |
| 9 | **`Elevate-Shell` öffnet PS5** | `Start-Process powershell.exe` startet 5.x statt der laufenden Version | ✅ `(Get-Process -Id $PID).MainModule.FileName` |
| 10 | **`Get-Module PSReadLine` doppelt** | Zweimal abgefragt (Check + Version) | ✅ Einmal in `$_psrl` gecacht |
| 11 | **`$env:PSModulePath` kein Split-Check** | Pfad bei wiederholtem Laden doppelt eingetragen | ✅ `-notlike`-Guard |
| 12 | **install: nur OneDrive-Pfad** | Modul-Junction landet auf OneDrive | ✅ `$LOCALAPPDATA/PowerShell/Modules/MyCliHelpers` ist im Manifest das **erste** Ziel; die Documents-Junctions bleiben als Fallback für Sessions ohne Profil. Die Profil**datei** selbst muss in „Eigene Dokumente" liegen — das gibt Windows vor; ist der Ordner umgeleitet, sagt der Installer das jetzt dazu |
| 13 | **install: Datei-Symlink ohne Admin scheitert** | Braucht Admin oder Developer Mode | ✅ Verzeichnisse als Junction, Dateien Symlink → Hardlink → Kopie (Kopie wird gewarnt) |

## 🟢 DISKUTABEL (Architektur, Tools, Konzepte)

| # | Bereich | Problem / Frage | Ergebnis |
|---|---------|----------------|--------|
| 16 | **Lazy-Loading des Moduls** | Import lädt alle Funktionen beim Start | ❌ **Verworfen, gemessen:** `Import-Module MyCliHelpers` kostet 13 ms warm, 65 ms kalt (Mittel aus 5 Läufen in frischen Prozessen). Stub-Funktionen könnten davon einen Bruchteil sparen und würden jeden Aufruf mit einer Indirektion belasten. Kein Gegenwert |
| 17 | **PSM1 vs. einzelne PS1-Files** | Großes Modul → alles oder nichts | ❌ **Verworfen**, gleiche Messung. Bei 13 ms ist „alles" billig genug; die Aufteilung kostet nur Wartung. Bei deutlichem Wachstum neu bewerten |
| 18 | **`Invoke-CachedInit` als Hilfsfunktion** | Starship-/Zoxide-Init-Logik dupliziert | ✅ Gemeinsame `Update-InitCache` |
| 19 | **`gg` vs. `rg`** | `Select-String` langsam bei großen Bäumen | ✅ `gg` delegiert an `rg`, wenn vorhanden; Select-String bleibt Fallback |
| 20 | **Kein `checkhealth`-Äquivalent** | Kein Diagnose-Tool für fehlende Abhängigkeiten | ✅ `Test-ProfileHealth` (Alias `checkhealth`): prüft Tools, `REPOS_DIR`, PSReadLine, Modulpfad inkl. OneDrive-Herkunft, Profil-Verknüpfung (auch: zeigt sie ins Leere?) und Init-Cache. `-Quiet` liefert Objekte statt Text |
| 21 | **PSReadLine `-ListAvailable`** | Scannt das Dateisystem | ✅ `Get-Module` ohne `-ListAvailable` |
| 22 | **Kein `$ErrorActionPreference`-Guard** | Profil-Fehler brechen nachfolgende Initialisierungen ab | ✅ Abschnitt -1 sichert und setzt `Continue`, Abschnitt 99 stellt wieder her |
| 23 | **`Copy-LastOutput` re-evaluiert History** | `Invoke-Expression` führt den letzten Befehl **nochmals** aus | ✅ Ausführen nur noch mit explizitem `-Rerun`. Alt+c liegt jetzt auf dem neuen `Copy-LastCommand` (kopiert nur die Kommandozeile) — ein Tastendruck darf kein `git push` wiederholen |
| 24 | **Cache-Invalidierung durch Tool-Version** | TTL invalidiert am Bedarf vorbei | ✅ `<cache>.ver`-Sidecar mit `starship --version` / `zoxide --version`. Version geändert → sofort neu; sonst gilt der Cache. Version wird **nach** dem Cache geschrieben, damit ein Abbruch nicht zu einem als frisch markierten Fragment führt |
| 25 | **Kein Cross-Platform-Guard** | `Open-Explorer`, `Elevate-Shell` sind Windows-only | ✅ `$IsWindows`-Guards inkl. `appdata`; `~` nutzt `$HOME` statt `$env:USERPROFILE`; nvim- und Repo-Pfade über die beiden Helfer aus #8 |

## Nachträglich dazugekommen

Beim Testen des Profils in einem frischen Prozess aufgefallen und mit erledigt:

* `Set-PSReadLineOption -PredictionSource` wirft, sobald die Konsolenausgabe
  umgeleitet ist (Skript-Aufruf, VS-Code-Task, CI) — das gab bei jedem solchen
  Start zwei rote Fehlerblöcke. Jetzt in `try/catch`.
* `Import-Module MyCliHelpers -ErrorAction SilentlyContinue` schluckt den Fehler
  **nicht**, wenn eine Junction im Modulpfad ins Leere zeigt (Pfadfehler statt
  „Modul nicht gefunden"). Jetzt in `try/catch`, mit dem Reparaturbefehl in der
  Meldung.

---
