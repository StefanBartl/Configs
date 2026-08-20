# Regeln — Shell-Skripte (bash und PowerShell)

Gilt für `install/*.sh`, `install/*.ps1`, `scripts/**` und die Profil-/Modul-
Dateien unter `shells/`. Prioritäten-Legende:
[README.md](../README.md#prioritäten-legende)

---

## 1. Pfade und Plattform

| ID | Regel | Beschreibung | Priorität | Beleg |
| -- | ----- | ------------ | --------- | ----- |
| `SH-01` | Keine Benutzerpfade im Code | Nie `C:\Users\<name>\...`. Immer `$env:LOCALAPPDATA`, `$HOME`, `$env:REPOS_DIR`, `$XDG_CONFIG_HOME`. | 🔴 KRITISCH | pwsh-ROADMAP #8 |
| `SH-02` | Plattformlogik bündeln | Plattformabhängige Pfade stehen in **einer** Funktion, nicht verstreut in jeder aufrufenden Stelle. | 🟡 EMPFOHLEN | `Get-ReposRoot`, `Get-NvimDirectory` in `MyCliHelpers` |
| `SH-03` | `$HOME` statt `$env:USERPROFILE` | In PowerShell ist `$HOME` auf jeder Plattform gesetzt, `$env:USERPROFILE` nur unter Windows. | 🟡 EMPFOHLEN | pwsh-ROADMAP #25 |
| `SH-04` | Windows-only kennzeichnen | Funktionen, die es nur unter Windows gibt, beginnen mit `if (-not $IsWindows) { ...; return }` statt mit einem unverständlichen Folgefehler. | 🟡 EMPFOHLEN | `Open-Explorer`, `Elevate-Shell`, `appdata` |
| `SH-05` | Skriptrelativ arbeiten | Ein Installer bestimmt die Repo-Wurzel aus seinem eigenen Pfad, nicht aus dem aktuellen Arbeitsverzeichnis. | 🟡 EMPFOHLEN | `install.sh`/`install.ps1` laufen aus jedem `cwd` |
| `SH-06` | Zeilenenden festnageln | `.gitattributes` erzwingt LF für alles, was unter Unix ausgeführt wird. | 🔴 KRITISCH | Ein CRLF im Shebang macht `install.sh` unter Linux unbrauchbar — deshalb entstand `.gitattributes` |

## 2. Fehlerverhalten

| ID | Regel | Beschreibung | Priorität | Beleg |
| -- | ----- | ------------ | --------- | ----- |
| `SH-10` | Ein Fehler bricht nicht alles ab | Ein Profil führt viele unabhängige Initialisierungen aus. Eine kaputte darf die anderen nicht verhindern. | 🔴 KRITISCH | pwsh-ROADMAP #22 |
| `SH-11` | Globale Einstellungen zurückgeben | Wer `$ErrorActionPreference` (oder `set -e`, `IFS`, `$PATH`) für die eigene Laufzeit ändert, stellt den vorherigen Wert am Ende wieder her. | 🔴 KRITISCH | Profil-Abschnitte -1 und 99 |
| `SH-12` | `-ErrorAction` reicht nicht immer | Zeigt eine Junction ins Leere, wirft `Import-Module` einen Pfadfehler, den `SilentlyContinue` nicht schluckt. Wo das Ergebnis zählt, gehört `try/catch` hin. | 🟡 EMPFOHLEN | Beim Testen des Profils in einem frischen Prozess aufgefallen |
| `SH-13` | Fehlermeldung nennt die Reparatur | „X fehlt" ist halb so nützlich wie „X fehlt — behebe es mit Y". | 🟡 EMPFOHLEN | Alle Meldungen in `Test-ProfileHealth` und im Profil |
| `SH-14` | `set -euo pipefail` in bash | Und leere Arrays defensiv expandieren, sonst bricht `set -u` bei älteren bash-Versionen. | 🟡 EMPFOHLEN | `install.sh` |

## 3. Nichts ungefragt ausführen

| ID | Regel | Beschreibung | Priorität | Beleg |
| -- | ----- | ------------ | --------- | ----- |
| `SH-20` | Kein Tastendruck mit Nebenwirkung | Eine Tastenbelegung darf keinen Befehl wiederholen. Wiederholung ist immer explizit. | 🔴 KRITISCH | `Alt+c` führte den letzten Befehl via `Invoke-Expression` erneut aus — bei `git push` oder `rm` ein zweites Mal. Jetzt `-Rerun` bzw. `Copy-LastCommand` |
| `SH-21` | Nicht blockierend fragen | Ohne interaktive Konsole (Pipe, CI) wird nicht gefragt, sondern ein sinnvoller Standard genommen. | 🟡 EMPFOHLEN | `[ ! -t 0 ]` / `[Console]::IsInputRedirected` in beiden Installern |
| `SH-22` | Kein Editor, kein Prompt in Automatisierung | Befehle, die einen Editor öffnen (`starship config`, `git rebase -i`), blockieren unbemerkt. Nicht-interaktive Variante nutzen (`starship print-config`). | 🟢 NICE-TO-HAVE | Beim Validieren der starship-Config genau so passiert |

## 4. Startzeit

| ID | Regel | Beschreibung | Priorität | Beleg |
| -- | ----- | ------------ | --------- | ----- |
| `SH-30` | Lookups einmal pro Session | `Get-Command` und Konsorten sind teuer. Ergebnis in einem Dictionary auf Modul-/Skriptebene halten. | 🟡 EMPFOHLEN | pwsh-ROADMAP #6, #7 |
| `SH-31` | Init-Ausgaben cachen | `starship init`, `zoxide init` sind Unterprozesse. Ausgabe cachen und dot-sourcen. | 🟡 EMPFOHLEN | `Update-InitCache` |
| `SH-32` | Cache über Version invalidieren, nicht über Alter | Ein Tool-Update muss sofort greifen; ein unverändertes Tool braucht keinen neuen Cache. Alter ist nur die Rückfallebene. | 🟡 EMPFOHLEN | pwsh-ROADMAP #24 |
| `SH-33` | Erst messen, dann optimieren | Eine Optimierung ohne Zahl davor wird nicht umgesetzt. | 🟡 EMPFOHLEN | Lazy-Loading (#16/#17) verworfen, weil der Import 13 ms warm kostet |
| `SH-34` | Cache nur bei Erfolg schreiben | Leere oder fehlgeschlagene Ausgabe darf einen funktionierenden Cache nicht überschreiben. Versionsstempel **nach** dem Inhalt schreiben. | 🟡 EMPFOHLEN | `Update-InitCache` |
