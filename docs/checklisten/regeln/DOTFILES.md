# Regeln — Dotfiles-Repo

Was in dieses Repo gehört, wie es installiert wird und wo die Grenzen liegen.
Prioritäten-Legende: [README.md](../README.md#prioritäten-legende)

---

## 1. Was hier liegen darf

Die Naht verläuft nach **Lebenszyklus**, nicht nach Tool — Begründung in
[RESTRUCTURE.md § 2](../../RESTRUCTURE.md).

| ID | Regel | Beschreibung | Priorität | Beleg |
| -- | ----- | ------------ | --------- | ----- |
| `DOT-01` | Nur Layer A | Hier liegt ausschließlich, was symlinkt und gemeinsam installiert wird. Assets, Backups, Profile, Inventare gehören nach `machine-assets` (privat). | 🔴 KRITISCH | Fonts, VPN-Profile, Bookmarks blähten das Repo auf 89,7 MB — [RESTRUCTURE § 1](../../RESTRUCTURE.md) |
| `DOT-02` | Eigenständige Projekte raus | Was einen eigenen Build, eigenes Deploy und eigene Roadmap hat, ist ein eigenes Repo. | 🔴 KRITISCH | `OpenInNvim` (C#-App mit `.csproj`) lag jahrelang in einem Dotfiles-Repo → `open-in-nvim` |
| `DOT-03` | Keine Binaries, keine Archive | Downloadbares wird nicht versioniert. Ausnahmen brauchen einen Grund in der Datei daneben. | 🔴 KRITISCH | `marksman.exe` (18,9 MB) und sieben Font-ZIPs mussten per `filter-repo` aus der History |
| `DOT-04` | Kein Build-Output | `bin/`, `obj/`, `publish/`, `node_modules/` gehören in `.gitignore`, nicht ins Repo. | 🟡 EMPFOHLEN | 213 MB Build-Output lagen im Arbeitsverzeichnis; nur Glück, dass sie nie getrackt waren |
| `DOT-05` | Ein Ort pro Konfiguration | Was zwei Plattformen nutzen, liegt einmal da. `prompt/starship.toml` wird von zsh **und** pwsh geladen — nicht duplizieren, nicht pro Plattform forken. | 🔴 KRITISCH | Genau diese Datei war der Grund, die Naht *nicht* pro Tool zu legen |
| `DOT-06` | Fremdcode als Submodul | Eigenständig nutzbare Fremd- oder Eigenprojekte werden eingehängt, nicht einkopiert. | 🟡 EMPFOHLEN | `my-zsh` unter `shells/zsh` — bleibt standalone installierbar |

## 2. Installation und Verknüpfung

| ID | Regel | Beschreibung | Priorität | Beleg |
| -- | ----- | ------------ | --------- | ----- |
| `DOT-10` | Manifest statt Skriptlogik | Neue Verknüpfungen werden in [`install/links.conf`](../../../install/links.conf) eingetragen, nicht in eines der Installer-Skripte. Sonst driften die Plattformen auseinander. | 🔴 KRITISCH | Vor Schritt 5 gab es nur `install.ps1`; Linux hatte gar keinen Installer |
| `DOT-11` | Pfade nur einmal kodieren | Zeigt eine Datei außerhalb des Repos auf das Repo, gehört sie **ins** Repo und wird von dort verlinkt. | 🔴 KRITISCH | `~/.config/wezterm/wezterm.lua` war pro Maschine einkopiert und zeigte nach dem Umbau ins Leere → [`install/wezterm-entry.lua`](../../../install/wezterm-entry.lua) |
| `DOT-12` | Verlinken, nicht kopieren | Kopien folgen Repo-Änderungen nicht. Wenn nur eine Kopie geht, muss der Installer das **warnen**. | 🔴 KRITISCH | `install.ps1` meldet den Kopie-Fallback als `KOPIE` |
| `DOT-13` | Nie ungefragt überschreiben | Existiert am Ziel eine echte Datei, wird sie übersprungen. Mit `--force` wandert sie nach `<ziel>.bak-<zeitstempel>`, bevor verlinkt wird. | 🔴 KRITISCH | — |
| `DOT-14` | Ohne Adminrechte lauffähig | Verzeichnisse als Junction, Dateien Symlink → Hardlink → Kopie. Ein Installer, der Adminrechte verlangt, wird nicht ausgeführt. | 🟡 EMPFOHLEN | pwsh-ROADMAP #13 |
| `DOT-15` | Trockenlauf zuerst | Jeder Installer hat `--dry-run`/`-DryRun` und ändert damit garantiert nichts. | 🟡 EMPFOHLEN | — |
| `DOT-16` | Konfiguration ≠ Installation | Die Installer verlinken Config. Programme installiert der Paketmanager. Fehlt ein Programm, ist das ein Hinweis, kein Abbruch. | 🟡 EMPFOHLEN | Grenze in [`install/README.md`](../../../install/README.md) festgeschrieben |
| `DOT-17` | Nie in synchronisierte Ordner | Modulpfade und Caches gehören nach `$LOCALAPPDATA` bzw. `$XDG_*`, nie nach OneDrive und nie nach `$TEMP`. | 🟡 EMPFOHLEN | pwsh-ROADMAP #1, #5, #12 — OneDrive-Sync bei jedem `Import-Module` |

## 3. Nach dem Umbau

| ID | Regel | Beschreibung | Priorität | Beleg |
| -- | ----- | ------------ | --------- | ----- |
| `DOT-20` | Umbenennen heißt neu installieren | Wer Pfade im Repo verschiebt, muss auf jeder Maschine den Installer laufen lassen. Verknüpfungen zeigen sonst ins Leere. | 🔴 KRITISCH | Nach Schritt 4 zeigten `$PROFILE` und die Modul-Junction auf `Configs\Windows\DOTFILES\...` — gefunden erst von `Test-ProfileHealth` |
| `DOT-21` | Diagnose statt Rätselraten | Es gibt ein `checkhealth`-Äquivalent, und es nennt zu jedem Fehlschlag den Reparaturbefehl. | 🟡 EMPFOHLEN | `Test-ProfileHealth` in `MyCliHelpers` |
