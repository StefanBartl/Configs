# Restrukturierung `Configs` — Analyse & Plan

> **Status:** Schritte 1–6 umgesetzt; offen ist nur noch der nachgelagerte Punkt (Abschnitt 8)
> **Stand:** 2026-08-20
> **Ausgangsfrage:** Eigenes Repo für pwsh/wezterm (analog `my-zsh`), oder alles
> in ein Repo zusammenführen?

---

## 0. Erledigt: Exponierte Zugangsdaten (2026-08-20)

`StefanBartl/Configs` war **public** und enthielt getrackte Zugangsdaten.
Erstmals eingecheckt mit Commit `b92cb6e`, seither durchgehend in `main`.

Betroffen waren:

- `env/` — API-Key-Datei
- `VPN/ProtonVPN/WireGuard/` — 4 Configs mit privatem Schlüsselmaterial
- `VPN/ProtonVPN/` — 7 OpenVPN-Profile
- `VPN/RemotePlay/` — Screenshot mit Schlüsselmaterial
- `docker-cred/` — GPG-**Public**-Keyring-Listing, kein privates Material (geringe Schwere, unverändert im Repo)
- `Settings_Profiles/` — Bookmark-Export und Softwareinventar (Privacy, nicht sicherheitskritisch, unverändert im Repo)

### Durchgeführt, in dieser Reihenfolge

1. ✅ API-Key nur noch als lokale Umgebungsvariable geführt, nicht mehr im Repo
2. ✅ ProtonVPN/WireGuard: alte Konfigurationen ungültig, keine aktiven Peers mehr
3. ✅ History-Purge (`git filter-repo`) + Force-Push auf `main` und `main-unix`

Die betroffenen Dateien sind vollständig aus der Git-History entfernt (verifiziert
per Blob-Scan über alle Objekte, alle Refs). `.gitignore` verhindert versehentliches
erneutes Einchecken. `docker-cred/` und `Settings_Profiles/` blieben unangetastet —
kein privates Schlüsselmaterial bzw. nur Privacy-relevant, nicht sicherheitskritisch.

`my-zsh` löst Secret-Handling bereits korrekt: `secrets.zsh` lädt zur Laufzeit aus
`~/personel_env/` — außerhalb des Repos. Dieses Muster ist die Zielvorgabe
für alle Plattformen.

---

## 1. Ist-Zustand (Stand vor Schritt 1–3, siehe Historie unten für den aktuellen Stand)

|  | `Configs` | `my-zsh` |
|---|---|---|
| Sichtbarkeit | public | public |
| Getrackte Dateien | 115 | ~25 + 5 Submodule |
| **Pack-Größe** | **89,7 MB** → **2,0 MB** nach Schritt 3 (2026-08-20) | klein |
| Commits | 71 | 32 |
| Secret-Handling | im Repo committet | extern (`~/personel_env/`) |
| Install | `install-DOTFILES.ps1` (nur pwsh) | `ln -sf`, in `INSTRUCTIONS.md` dokumentiert |
| Fremdcode | vendored | Submodule |

### Herkunft der 89,7 MB (historisch — per Schritt 3 vollständig gepurgt)

```
 25.72 MB  Fonts/OpenDyslexic.zip
 23.94 MB  Fonts/Noto_Color_Emoji.zip
 23.62 MB  Fonts/IBM_Plex_Mono,Inter,Source_Code_Pro.zip   <- nicht mehr in HEAD
 18.93 MB  Windows/tools/marksman.exe                       <- nicht mehr in HEAD
 15.40 MB  Fonts/Monoid.zip
  5.36 MB  Fonts/JetBrainsMono-2.304.zip
  2.79 MB  Fonts/NerdFontsSymbolsOnly.zip
  1.53 MB  CLITools/TCPView.zip
```

Rund 113 MB der History sind heruntergeladene Fonts und eine Binary. Zwei der
größten Objekte sind aus `HEAD` bereits gelöscht, liegen aber weiterhin in der
History. **115 Textdateien in einem 90-MB-Repo** ist das eigentliche Symptom.

### Strukturbefund

`my-zsh` ist ein Framework: klare Modulgrenzen (`init.zsh`, `paths.zsh`,
`integrations.zsh`, `fishify.zsh`), Fremdcode als Submodul, Secrets außerhalb,
dokumentierter Install.

`Configs` ist kein Dotfiles-Repo, sondern ein Sammelarchiv für alles rund um
die eigenen Maschinen: Dotfiles *und* Font-Downloads *und* VPN-Profile *und*
iCue-Tastaturprofile *und* Browser-Bookmarks *und* eine vollständige
C#-Anwendung (`Windows/Contextmenu/OpenInNvim`, mit eigener `.csproj`,
`README.md`, `docs/ROADMAP.md`, Deploy-Skripten).

Das Problem ist nicht die *Anzahl* der Repos, sondern dass hier vier Dinge mit
grundverschiedenem Lebenszyklus im selben Repo liegen.

---

## 2. Nach welcher Naht schneiden?

### Verworfen: Naht "pro Tool"

Symmetrisch zu `my-zsh`, bricht aber an einem harten Fakt:

```
Linux/macOS installiert:   zsh + wezterm + starship + tmux + fonts
Windows installiert:       pwsh + wezterm + starship + fonts
                                  ^^^^^^^^^^^^^^^^^^^^^^^^^^
                                  in BEIDEN Sets
```

`Terminals/wezterm/config/wsl/`, `Terminals/wezterm/config/powershell.lua` und
`Shells/starship/starship.toml` werden von beiden Plattformen genutzt.
`Windows/DOTFILES/ROADMAP.md` #2–#4 beschreibt Starship-Tuning — dieselbe
`starship.toml`, die auch zsh lädt.

Ein separates `my-pwsh` müsste starship und wezterm **duplizieren** oder per
Submodul einbinden. Beides schlechter als der Status quo. Diese Naht verläuft
quer zur tatsächlichen Abhängigkeitsstruktur.

### Verworfen: Naht "alles in eins"

Zieht `my-zsh` — klein, sauber, mit eigenen Submodulen — in ein 90-MB-Repo mit
Windows-Fonts, VPN-Profilen und einer C#-App. Auf einer Linux-Maschine würden
90 MB geklont, um an eine `.zshrc` zu kommen. Verschachtelte Submodule
(my-zsh-Plugins innerhalb eines Monorepos) sind zusätzlich unangenehm zu warten.

Merge ist die richtige Richtung — aber nicht in diesen Zustand hinein.

### Gewählt: Naht nach Lebenszyklus

| Layer | Inhalt | Deployment | Ziel | Status |
|---|---|---|---|---|
| **A — Dotfiles** | zsh, pwsh, wezterm, kitty, tmux, starship, bash, CLI-Tools | Symlink / Loader | 1 Repo, public, klein | bleibt in `Configs`, Umbau offen (Abschnitt 3–4) |
| **B — Assets & Backups** | Fonts, VPN, iCue, Audio, Bookmarks, Software-Listen, Gaomon | wird nie verlinkt | privates Repo | ✅ migriert nach [`StefanBartl/machine-assets`](https://github.com/StefanBartl/machine-assets) (privat), 2026-08-20 |
| **C — Eigenständige Projekte** | `OpenInNvim` (C#-App) | eigenes Build/Deploy | eigenes Repo | ✅ migriert nach [`StefanBartl/open-in-nvim`](https://github.com/StefanBartl/open-in-nvim) (public), 2026-08-20 |
| **D — Secrets** | API-Keys, VPN-Schlüssel | Runtime-Load | nie in Git (`my-zsh`-Muster) | ✅ erledigt, siehe Abschnitt 0 |

Layer A ist exakt die Menge, die gemeinsam installiert wird und sich
gegenseitig referenziert. Das ist die tragfähige Naht.

### Migration Layer B/C — Details (2026-08-20)

Beide neuen Repos wurden mit **frischer History** angelegt (ein Initial-Commit),
nicht per `git filter-repo`-Subtree-Split — so bewusst entschieden, weil die
alte `Configs`-History für diese Pfade ohnehin nur die (inzwischen entfernten)
Secrets und unnötigen Ballast mitgeschleppt hätte.

Bei der Migration von `Windows/Contextmenu/OpenInNvim/` fiel auf: `bin/`, `obj/`
und `publish/*.exe` (zwei self-contained .NET-Singlefile-Exes, ~66 MB je Datei,
zusammen ~214 MB) lagen zwar im Arbeitsverzeichnis, waren aber **nie
Git-getrackt** (`git ls-files` liefert dafür nichts) — reiner lokaler
Build-Output ohne Auswirkung auf die Repo-Größe. `open-in-nvim` hat jetzt ein
`.gitignore` dafür, damit das so bleibt.

`Configs` selbst wurde per `git rm` von `Fonts/`, `VPN/`, `Settings_Profiles/`,
`docker-cred/` und `Windows/Contextmenu/OpenInNvim/` bereinigt. Die alten Inhalte
bleiben bis Schritt 3 (History-Purge) in der `Configs`-Git-History erhalten —
das ist der noch offene Schritt, der die Repo-Größe tatsächlich reduziert.

---

## 3. Zielstruktur

```
dotfiles/                  (public, wenige MB — heutiges Configs, entkernt)
├── shells/
│   ├── zsh/               <- my-zsh als Submodul
│   ├── pwsh/              <- Windows/DOTFILES/WindowsPowerShell
│   └── bash/
├── terminals/
│   ├── wezterm/           <- Terminals/wezterm (inhaltlich unverändert)
│   ├── kitty/
│   └── tmux/
├── prompt/
│   └── starship.toml      <- von zsh UND pwsh geteilt
├── cli/                   <- lazygit, glow
└── install/
    ├── install.ps1        <- heutiges install-DOTFILES.ps1
    └── install.sh         <- my-zsh INSTRUCTIONS.md, als Skript

machine-assets/            (PRIVAT — Fonts, VPN, iCue, Bookmarks, Audio)
open-in-nvim/              (eigenes Repo — die C#-Anwendung)
```

### Tatsächlich umgesetzt (Schritt 4, 2026-08-20)

Die Skizze oben deckte nicht alle 115 damals getrackten Dateien ab. Reale
Struktur nach dem Umbau, inklusive der drei zusätzlichen Layer-A-Ordner für
Inhalte ohne offensichtlichen Platz in der Skizze:

```
Configs/
├── shells/{pwsh,bash,zsh(Submodul)}/
├── terminals/{wezterm,kitty,tmux,windows-terminal}/
├── prompt/starship.toml
├── cli/{lazygit,glow,TCPView.zip,List.md}
├── install/{links.conf,install.sh,install.ps1,wezterm-entry.lua,README.md}
├── containers/podman/nvim            (Podman-Containerfile)
├── scripts/                          (keepawake*.ps1, install-tools-win.ps1, pdf_zu_bilder.py)
├── editors/{vscodevim,vsvim}/
└── docs/{RESTRUCTURE.md,checklisten/}
```

### Begründung

- Ein `$REPOS_DIR/dotfiles` pro Maschine, ein Install-Skript je Plattform
- `starship.toml` und wezterm-Config haben **einen** Ort, keine Duplikate
- Klein genug für jede frische VM
- Public unbedenklich, weil Layer B und D ausgelagert sind
- Layer B darf versioniert sein — nur eben nicht öffentlich

### `my-zsh`: absorbieren oder Submodul?

|  | Absorbieren | Submodul |
|---|---|---|
| History | verloren (außer via `subtree merge`) | bleibt erhalten |
| Standalone installierbar | nein | ja |
| Wartung | ein Commit ändert alles | Pointer-Commits, Submodul-in-Submodul |

**Entscheidung: Submodul.** `my-zsh` hat mit `INSTRUCTIONS.md`,
`DISCLAIMER.md`, `UNLICENSED` und eigener `ROADMAP.md` bereits eine
eigenständige Identität und bleibt so auf Maschinen installierbar, auf denen
nur zsh gebraucht wird.

---

## 4. Bekannte Bruchstellen

Drei Stellen kodierten Repo-Pfade hart:

1. ~~`~/.config/wezterm/wezterm.lua` — `candidates = { join(REPOS_DIR, "Configs",
   "Terminals", "wezterm") }` auf jeder Maschine, auf der wezterm bereits
   deployed ist~~ → gelöst in Schritt 5: der Loader liegt jetzt als
   `install/wezterm-entry.lua` **im Repo** und wird von beiden Installern als
   Symlink nach `~/.config/wezterm/wezterm.lua` gelegt. Damit ist der Repo-Pfad
   nur noch an einer Stelle kodiert (und dort gleich auf `terminals/wezterm`
   korrigiert, mit `dotfiles` als Zweitkandidat für den geplanten Repo-Namen).
   Auf bereits deployten Maschinen genügt ein Lauf des Installers.
2. ~~`Windows/DOTFILES/install-DOTFILES.ps1`~~ → jetzt `install/install.ps1`,
   Pfad im Skript selbst auf `Configs\shells\pwsh` mitgefixt (Schritt 4).
3. `my-zsh/INSTRUCTIONS.md` — Pfadangaben in der Anleitung. Liegt im
   `my-zsh`-Repo selbst, nicht in `Configs`; unverändert, da `my-zsh` jetzt als
   Submodul unter `shells/zsh/` hängt und seine eigene Anleitung weiterhin für
   den Standalone-Einsatz gilt.

Zusätzlich: `Windows/DOTFILES/OLD_Powershell/` war toter Ballast (alte
Profilstände, redundant zur Git-History) — in Schritt 4 ersatzlos entfernt.

### Umbau durchgeführt (Schritt 4, 2026-08-20)

Vollständige Übernahme der Zielstruktur aus Abschnitt 3: `shells/{pwsh,bash,zsh}`,
`terminals/{wezterm,kitty,tmux,windows-terminal}`, `prompt/starship.toml`,
`cli/{lazygit,glow,TCPView.zip,List.md}`, `install/install.ps1`, plus drei
zusätzliche, in der Zielskizze nicht explizit genannte Ordner für Inhalte ohne
festen Platz in Layer A: `containers/podman/` (Podman-Containerfile),
`scripts/` (keepawake, install-tools-win, pdf_zu_bilder.py), `editors/`
(vscodevim, vsvim). `my-zsh` als Submodul unter `shells/zsh/` eingehängt.
`Windows/DOTFILES/ROADMAP.md` (pwsh-spezifisch, #2–#20) ist mit nach
`shells/pwsh/ROADMAP.md` gewandert, analog zu `my-zsh`s eigener `ROADMAP.md`.

**Windows-Stolperstein:** `git mv Terminals/wezterm terminals/wezterm` schlägt
auf NTFS (case-insensitive) mit `Invalid argument` fehl, weil Quelle und Ziel
sich nur in der Groß-/Kleinschreibung eines Vorfahren-Pfadsegments
unterscheiden und die Datei-Engine das als Rename auf sich selbst wertet.
Workaround: zweistufig über einen Zwischennamen —
`git mv Terminals/wezterm Terminals/wezterm_tmp && git mv Terminals/wezterm_tmp terminals/wezterm`.

---

## 5. Umsetzungsreihenfolge

| # | Schritt | Voraussetzung |
|---|---|---|
| 1 | ~~Zugangsdaten rotieren (API-Key, WireGuard) + History-Purge~~ ✅ erledigt 2026-08-20 (Abschnitt 0) | — |
| 2 | ~~Layer B in privates Repo, Layer C in eigenes Repo auslagern~~ ✅ erledigt 2026-08-20 (Abschnitt 2, Migration-Details) | — |
| 3 | ~~History-Purge (`git filter-repo`): Fonts + `marksman.exe` + Layer-B/C-Pfade + Force-Push~~ ✅ erledigt 2026-08-20 — `.git` 90 MB → 2,0 MB (lokal + `origin/main` + `origin/main-unix`) | 2 |
| 4 | ~~Umbau auf Zielstruktur, `my-zsh` als Submodul einhängen~~ ✅ erledigt 2026-08-20, siehe "Umbau durchgeführt" oben | 3 |
| 5 | ~~`install.sh` + `install.ps1` vereinheitlichen (inkl. Fix für `~/.config/wezterm/wezterm.lua` auf betroffenen Maschinen)~~ ✅ erledigt 2026-08-20, siehe Abschnitt 6 | 4 |
| 6 | ~~Offene Punkte aus `shells/pwsh/ROADMAP.md`~~ ✅ erledigt 2026-08-20 — alle 22 offenen Punkte abgearbeitet, zwei nach Messung verworfen; siehe Abschnitt 7 | 5 |
| 7 | ~~Checklisten-/Gate-Systematik uebertragen~~ ✅ erledigt 2026-08-20 — [`docs/checklisten/`](./checklisten/), siehe Abschnitt 8 | 6 |

Schritt 3 reduziert das Repo zusätzlich von 89,7 MB auf wenige MB (Fonts/Binary,
unabhängig von den bereits gepurgten Zugangsdaten).

---

## 6. Schritt 5 durchgeführt (2026-08-20)

### Ein Manifest, zwei Installer

Statt zwei Skripte mit je eigener, driftender Liste gibt es jetzt
`install/links.conf` als einzige Quelle der Wahrheit — ein Eintrag pro
Verknüpfung, markiert mit Plattform (`unix` / `windows` / `all`) und Komponente
(siehe unten), mit Tokens für die Zielpfade (`$HOME`, `$XDG_CONFIG`,
`$APPDATA`, `$PS5`, `$PS7`).
`install/install.sh` und `install/install.ps1` sind nur noch Ausführungs-
maschinen dafür. Ein neuer Config-Pfad wird an einer Stelle eingetragen und gilt
sofort für beide Plattformen. Details: [`install/README.md`](../install/README.md).

Beide Installer bieten `--dry-run`/`-DryRun` und schützen vorhandene *echte*
Dateien am Ziel (nur mit `--force`/`-Force` ersetzt, dann mit Backup nach
`<ziel>.bak-<zeitstempel>`).

### Komponentenauswahl

Das Manifest hat neben der Plattform eine zweite Dimension: die **Komponente**
(`zsh`, `bash`, `pwsh`, `starship`, `wezterm`, `kitty`, `tmux`, `lazygit`,
`glow`). "Auf dieser Maschine nur wezterm und pwsh" ist damit ein Filter über
dieselbe Liste, kein zweites Skript:

```
./install/install.sh                     # interaktiv auswählen
./install/install.sh --only wezterm,zsh  # für Provisioning
./install/install.sh --list              # nur anzeigen
```

Angezeigt wird nur, was auf der laufenden Plattform überhaupt Einträge hat —
`pwsh` erscheint unter Linux nicht. Ohne interaktive Konsole (Pipe, CI) wird
nicht gefragt, sondern alles gewählt; der Installer blockiert also nie.

Zwei Konsequenzen aus dem Komponentenmodell:

* Das `my-zsh`-Submodul wird nur noch initialisiert, wenn `zsh` gewählt ist.
  Eine Windows-Maschine ohne zsh klont es gar nicht erst.
* Die Registry führt pro Komponente das zugehörige Programm. Fehlt es im PATH,
  gibt es einen Hinweis, aber keinen Abbruch — **Configs verlinkt
  Konfiguration, es installiert keine Programme.** Diese Grenze ist bewusst:
  Paketinstallation ist Sache des jeweiligen Paketmanagers (siehe
  `scripts/install-tools-win.ps1` für den Windows-Teil).

Weiter offen bleibt `shells/pwsh/ROADMAP.md` #12: `install.ps1` bestimmt das
Profilverzeichnis weiterhin über `[Environment]::GetFolderPath('MyDocuments')`
und landet damit auf OneDrive-umgeleiteten Maschinen im OneDrive-Pfad. Das ist
bewusst unverändert übernommen — der Fix gehört zu Schritt 6, nicht in den
Umbau.

Nebenbei erledigt: `shells/pwsh/ROADMAP.md` #13 (Admin-freier Symlink-Fallback).
`install.ps1` legt Verzeichnisse als Junction an (nie erhöhte Rechte nötig) und
versucht für Dateien Symlink → Hardlink → Kopie, wobei nur der letzte Fall
verlustbehaftet ist und deshalb explizit als `KOPIE` gewarnt wird.

### WezTerm-Entry als Symlink statt als Copy-Paste-Snippet

`install/wezterm-entry.lua` ersetzt das bisher pro Maschine einkopierte
`~/.config/wezterm/wezterm.lua`. Der Installer legt es als Symlink — der
Repo-Pfad ist damit nur noch **einmal** kodiert, im Repo, versioniert. Das war
Bruchstelle #1 aus Abschnitt 4 und ist damit strukturell gelöst statt pro
Maschine nachgezogen.

Der Loader sucht `<root>/{Configs,dotfiles}/terminals/wezterm` unter
`$REPOS_DIR` bzw. `~/repos`, `dotfiles` als Vorgriff auf den in Abschnitt 3
skizzierten Zielnamen. Die veraltete Kopie `terminals/wezterm/docs/NewEntryFile.lua`
(zeigte noch auf `Terminals/`) wurde entfernt, `docs/EntryPoint.md` verweist
jetzt auf die eine Datei.

### Geprüft und verworfen: `lib.nvim` in der wezterm-Config

Naheliegende Idee, weil `terminals/wezterm/config/tabtitle.lua` einige Helfer
selbst implementiert, die `lib.nvim` bereits hat. Die technische Voraussetzung
ist sogar erfüllt: der Namespace `lib.lua.*` ist explizit editorunabhängig und
lädt nachweislich in nacktem Lua 5.4 ohne `vim`-Global — `require("lib.lua.strings")`,
`lib.lua.tables` und `lib.lua.strings.utf8` funktionieren dort.

Trotzdem verworfen, weil die tatsächliche Überschneidung zu klein für die
Kopplung ist:

| Helfer in `tabtitle.lua` | `lib.nvim`-Pendant | ersetzbar? |
|---|---|---|
| `escpat` | `lib.lua.strings.escape_lua_magic` | ja (1 Zeile) |
| `url_decode` | `lib.lua.strings.uri_decode` | ja (5 Zeilen) |
| `truncate_left_cells` | — | **nein**, braucht `wezterm.column_width` (Terminal-Zellen inkl. Nerd-Font-Glyphen, nicht Codepoints) |
| `fit_width` | — | **nein**, dito plus `wezterm.truncate_right` |
| `normalize_home`, `split_path` | — | nein, WSL/Windows-`file://`-Spezifika |

Übrig bleiben ~6 Zeilen. Dagegen stünde: ein weiteres Submodul im
Dotfiles-Repo, `package.path`-Verdrahtung bei jedem Config-Reload, und eine
Abhängigkeit auf eine Bibliothek, deren eigenes README "no stability
guarantees … may change, rename, or remove modules at any time" sagt und zum
Pinnen eines Commits rät. Für sechs Zeilen ist das der schlechtere Tausch —
`lib.nvim` bleibt, wofür es gebaut ist: Neovim-Plugins.

---

## 7. Schritt 6 durchgeführt (2026-08-20)

Die Liste in `shells/pwsh/ROADMAP.md` war zum Teil bereits im Code umgesetzt,
aber nicht abgehakt. Erste Arbeit war daher, jeden Punkt gegen den Code zu
prüfen; danach blieben die wirklich offenen übrig. Alle 22 sind jetzt
abgearbeitet, die Roadmap führt pro Punkt das Ergebnis.

**Neu dazugekommen ist ein Diagnosewerkzeug:** `Test-ProfileHealth` (Alias
`checkhealth`, ROADMAP #20) prüft Tools, `REPOS_DIR`, PSReadLine, Modulpfad,
Profil-Verknüpfung und Init-Cache und nennt zu jedem Fehlschlag den
Reparaturbefehl. `-Quiet` liefert Objekte statt Text.

Es hat beim ersten Lauf gleich zwei echte Nachwirkungen von Schritt 4 gefunden:
`$PROFILE` und die Modul-Junction auf dieser Maschine zeigen noch auf
`Configs\Windows\DOTFILES\...`, also ins Leere. Genau die Klasse Fehler, die
sonst erst auffällt, wenn Funktionen unerklärlich fehlen. Behoben wird sie mit
`install\install.ps1 -Only pwsh -Force`.

### Zwei bewusste Abweichungen

* **ROADMAP #3** notierte `scan_timeout = 30000`. Umgesetzt ist `1000`. Der
  Wert ist eine Obergrenze, keine Wartezeit: 30000 hieße, dass der Prompt bei
  einem hängenden Dateisystem (Netzlaufwerk, schlafende Platte) bis zu 30
  Sekunden blockiert. 1000 ms lösen das eigentliche Problem — große Repos —
  und begrenzen den schlimmsten Fall auf eine Sekunde.
* **ROADMAP #16/#17** (Lazy-Loading, Aufteilung in Sub-Module) sind verworfen,
  nicht vergessen. Gemessen kostet `Import-Module MyCliHelpers` 13 ms warm und
  65 ms kalt. Stub-Funktionen könnten davon einen Bruchteil sparen und würden
  jeden Aufruf mit einer Indirektion belasten. Bei deutlichem Wachstum des
  Moduls neu zu bewerten.

### Sicherheitsrelevant: `Copy-LastOutput`

PowerShell speichert in der History nur die Kommandozeile, nie deren Ausgabe.
"Output kopieren" hieß deshalb: den letzten Befehl per `Invoke-Expression`
**nochmal ausführen** — und das lag auf `Alt+c`. Bei `git push`, `rm` oder
einem POST-Request passierte die Wirkung damit ein zweites Mal, auf einen
Tastendruck hin. Jetzt führt die Funktion nur mit explizitem `-Rerun` etwas
aus; `Alt+c` liegt auf dem neuen `Copy-LastCommand`, das ausschließlich Text
kopiert.

---

## 8. Schritt 7 durchgeführt (2026-08-20): Regeln & Gates

Die Checklisten- und Gate-Systematik aus
`WKDBooks/Development/wkdbook-Lua/Checklists` ist auf dieses Repo übertragen —
nach [`docs/checklisten/`](./checklisten/).

### Übertragen, nicht kopiert

Die dortige Sammlung bleibt die kanonische Fassung für Lua- und Neovim-Code.
Hier steht nur, was ein Dotfiles-Repo betrifft und dort nicht vorkommt:
Repo-Zuschnitt, Installer- und Verknüpfungssemantik, Shell-Regeln für bash
**und** PowerShell, Geheimnisse. Der Grundsatz „jede Regel steht genau einmal"
gilt über Repo-Grenzen hinweg; für den Lua-Anteil (`terminals/wezterm/**`)
verweisen die Dateien auf die kanonische Sammlung, statt sie zu duplizieren.
Die ID-Präfixe sind bewusst andere (`DOT-`, `SH-`, `KEY-`, `MACH-`, `REV-`,
`PUB-`), damit nicht zwei verschiedene Regeln denselben Namen tragen.

### Kein `belege/` — die Belege sind die eigene Historie

Die Lua-Sammlung belegt ihre Regeln mit Befunden aus 33 fremden Repos. Hier
war das unnötig: dieses Repo ist der Beleg. Jede Regel trägt in der Spalte
„Beleg" den Vorfall, aus dem sie entstanden ist — die exponierten Zugangsdaten
(§ 0), die 89,7 MB (§ 1), die nach Schritt 4 ins Leere zeigenden Verknüpfungen
(§ 4), das CRLF-Risiko im Shebang (§ 6), `Alt+c` mit `Invoke-Expression` (§ 7).
Eine Regel ohne Vorfall wäre eine Vermutung und steht nicht drin.

### Struktur

| Ordner | Frage | Inhalt |
| ------ | ----- | ------ |
| [`regeln/`](./checklisten/regeln/) | Was gilt? | `DOTFILES.md` (Repo-Zuschnitt, Installer), `SHELL.md` (bash + PowerShell, Pfade, Startzeit), `SECRETS.md` |
| [`gates/`](./checklisten/gates/) | Bin ich fertig? | `NEW_MACHINE.md` (einmal pro Maschine), `REVIEW.md` (vor Merge), `PUBLISH.md` (vor Push ins Public-Repo) |

Die Gates wiederholen die Regeln nicht, sie verweisen per ID auf sie — eine
Änderung an einer Regel muss deshalb an genau einer Stelle passieren.

### `docs/ROADMAP.md` entfällt

Die Datei enthielt drei Punkte, alle erledigt: die wezterm-Modularisierung
(`terminals/wezterm/{config,utils,@types,color_schemes}` plus komponierende
`init.lua`), die Restrukturierung (dieses Dokument) und die Regeln/Gates
(oben). Eine Roadmap ohne offenen Punkt ist keine Roadmap, sondern eine
zweite, schlechtere Zusammenfassung des bereits Dokumentierten — sie ist
deshalb gelöscht statt leer stehengelassen. Tool-spezifische Roadmaps laufen
weiter in ihrem eigenen Ordner ([`shells/pwsh/ROADMAP.md`](../shells/pwsh/ROADMAP.md),
`shells/zsh`). Kommen wieder offene Punkte für das Repo als Ganzes, entsteht
die Datei neu.
