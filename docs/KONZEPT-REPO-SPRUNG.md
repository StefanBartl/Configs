# Konzept — Repo-Sprung aus `$REPOS_DIR` (pwsh + zsh)

Status: **Entwurf, nicht implementiert.** Entscheidungen aus §8 eingearbeitet.
Betrifft `Configs/shells/pwsh` und `my-zsh`.

---

## 1. Ziel

In jeder Shell soll ein Repo-Ordner unter `$REPOS_DIR` erreichbar sein, ohne
ihn vorher besucht oder von Hand eingetragen zu haben:

```
wkdbooks          → cd $REPOS_DIR/WKDBooks       (bloßer Name als Kommando)
spotlight         → cd $REPOS_DIR/spotlight.nvim
spotlight-nvim    → dito
z wkdbooks        → dito, über zoxide
repo wkdb         → explizit, mit Completion und Auswahl bei Mehrdeutigkeit
```

Die Liste entsteht **dynamisch** aus dem Inhalt von `$REPOS_DIR`, ohne dass
irgendwo 38 Namen gepflegt werden. Semantik in pwsh und zsh identisch.

---

## 2. Was zoxide leisten kann — und was nicht

zoxide löst **nur auf, was in seiner Datenbank steht** (Frecency-Ranking über
tatsächlich besuchte Pfade). Ein frisch geklontes Repo kennt `z` nicht. zoxide
hat außerdem **keinen Provider-/Plugin-Hook**, mit dem man eine externe
Verzeichnisquelle anmelden könnte.

Daraus folgt: zoxide kann **nicht** die gemeinsame Schicht sein, über die das
Feature in beiden Shells landet. Die Annahme aus der Aufgabenstellung trägt
nicht. Was bleibt, ist zoxide von außen zu **befüllen** (`zoxide add`) — das ist
ein Teil der Lösung, nicht die Lösung.

Zwei weitere Gründe gegen zoxide als gemeinsamen Nenner:

* Die DB ist maschinen-/plattformlokal. `C:\repos\x` und `/mnt/steve/repos/x`
  sind verschiedene Einträge; ein geteilter Zustand entsteht ohnehin nie.
* Ein zoxide-Treffer ist Ranking, kein Vertrag. Ein häufig besuchtes fremdes
  Verzeichnis kann `wkdbooks` gewinnen. Für "Name → genau dieses Repo" braucht
  es eine deterministische Schicht daneben.

Nutzbar ist dagegen: `zoxide add <PATHS>...` nimmt **mehrere Pfade in einem
Aufruf** und kennt `--score` (verifiziert mit zoxide 0.9.9). Ein Subprozess
genügt also für alle Repos.

---

## 3. Architektur — zwei Schichten, kein Cache

Entscheidend ist die Festlegung, dass ein neu angelegtes Repo **erst in der
nächsten Shell-Session** erreichbar sein muss. Zusammen mit dem
Command-not-found-Hook fällt damit die gesamte Index- und Cache-Schicht weg:
Die Auflösung passiert **beim Tippen, nicht beim Shellstart**. Es gibt nichts
zu cachen, weil es nichts vorzuberechnen gibt — und weil der Lookup zur
Laufzeit läuft, ist er sogar frischer als gefordert: ein in derselben Session
angelegtes Repo funktioniert nebenbei mit.

### Schicht 1 — Auflösung zur Laufzeit

Eine Funktion je Shell (`Resolve-Repo` / `__repo_resolve`), die aus einem
Suchbegriff einen Pfad macht. Plattformlogik bleibt an dieser einen Stelle
(`SH-02`), alles andere ruft nur sie auf.

Ablauf in dieser Reihenfolge:

1. **Direkter Treffer** — existiert `$REPOS_DIR/<begriff>` oder
   `$REPOS_DIR/<begriff>.nvim` als Verzeichnis mit `.git`? Dann fertig. Das ist
   der Normalfall und kostet zwei `stat`-Aufrufe, keinen Verzeichnis-Scan.
2. **Scan** — nur wenn 1 nichts liefert: Direktkinder von `$REPOS_DIR` mit
   `.git` auflisten und nach §4 matchen.

Ein Verzeichnis-Scan findet also nur statt, wenn tatsächlich unscharf gesucht
wird — nie beim Start, nie im Normalfall.

### Schicht 2 — zoxide-Seeding

Das Einzige, was beim Shellstart passiert. `zoxide add <PATHS>...` nimmt alle
Pfade in einem Aufruf (verifiziert mit zoxide 0.9.9), aber ein Subprozess pro
Shellstart ist trotzdem zu viel (`SH-31`).

Deshalb eine **Stempeldatei** statt eines Caches: sie hält die
`LastWriteTime` von `$REPOS_DIR` vom letzten Seeding fest. Diese Zeit ändert
sich beim Anlegen oder Löschen eines Kindordners — also genau dann, wenn neu
geseedet werden muss. Normaler Start: ein `stat` plus ein Dateilesevorgang,
kein Scan, kein Subprozess. Nach einem `git clone`: einmalig Scan plus ein
`zoxide add`.

Das ist bewusst keine Cache-Invalidierung: es wird kein Ergebnis aufbewahrt,
nur die Frage beantwortet, ob seit der letzten Änderung geseedet wurde. Ist der
Stempel kaputt oder weg, wird einmal zu viel geseedet — `zoxide add` ist
idempotent.

Ablage: `$env:LOCALAPPDATA\pwsh\cache\repos_seed.stamp` bzw.
`${XDG_CACHE_HOME:-$HOME/.cache}/my-zsh/repos_seed.stamp`.

### Schicht 3 — Einstiegspunkte

**Bloßer Name.** Hier gehen die beiden Shells auseinander — der ursprüngliche
Entwurf sah für beide denselben Command-not-found-Hook vor, das trägt nur in
PowerShell.

*pwsh:* `$ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction`.
Der Handler setzt `$eventArgs.CommandScriptBlock` und `StopSearch = $true`,
läuft im aktuellen Prozess, `Set-Location` wirkt. Greift nur, wenn nichts
anderes matcht → kein Shadowing, keine Startkosten.

*zsh:* `command_not_found_handler` ist dafür **unbrauchbar**. zsh forkt, bevor
es ihn aufruft — `$ZSH_SUBSHELL` ist darin `1`. Ein `cd` wirkt nur in der
Subshell und ist nach der Rückkehr weg; der Handler wäre ein stiller No-op, der
zudem die reguläre Fehlermeldung schluckt. Nachgemessen, nicht vermutet.
Stattdessen zwei Mechanismen, die im Elternprozess laufen:

* **`cdpath` + `AUTO_CD`** (in `behavior.zsh` ohnehin schon gesetzt) deckt den
  exakten Verzeichnisnamen nativ ab — ohne eine Zeile Auflösungscode und mit
  Completion. `WKDBooks` und `takt` erledigt zsh damit selbst.
* **Ein `accept-line`-Widget** deckt den Rest ab: Groß-/Kleinschreibung
  (`wkdbooks`) und die verkürzten Formen (`spotlight`, `spotlight-nvim`).
  Besteht die Zeile aus genau einem Wort, das kein Kommando, kein lokales
  Verzeichnis und kein exakter Repo-Name ist, wird sie zu `repo <name>`
  umgeschrieben — die Historie zeigt danach, was tatsächlich passiert ist.
  Überschrieben wird das Widget `accept-line` selbst, nicht die Tastenbindung:
  so greift es auch, wenn `fishify.zsh` oder `zsh-vi-mode` `^M` auf ein eigenes
  Widget legen, das seinerseits `zle accept-line` aufruft.

Beide zsh-Wege können ein echtes Kommando genauso wenig verdecken wie der
pwsh-Hook: `cdpath` greift erst, wenn kein Kommando gefunden wurde, und das
Widget prüft `command -v` explizit, bevor es etwas umschreibt.

**`repo <name>`** — explizit, mit Tab-Completion (pwsh
`Register-ArgumentCompleter`, zsh `compdef`). Nötig für alles, was der Hook
nicht erreichen kann: mehrdeutige Begriffe und Namen, die echte Kommandos sind
(§7). `r` scheidet aus, das ist in PowerShell der Alias für `Invoke-History`.

**`z <name>`** — unverändert zoxide, durch Schicht 2 auch für frisch geklonte
Repos.

---

## 4. Namensformen und Matching

### Namensformen

Für ein Repo `spotlight.nvim` werden drei Schreibweisen akzeptiert:

| Form | Beispiel | Anmerkung |
| ---- | -------- | --------- |
| Voller Name | `spotlight.nvim` | funktioniert in beiden Shells als Kommando |
| Punkt → Bindestrich | `spotlight-nvim` | die tippfreundliche Schreibweise |
| Stamm ohne Suffix | `spotlight` | nur wenn eindeutig |

Der Stamm ist alles vor dem ersten Punkt. Teilen sich zwei Repos einen Stamm,
löst der Stamm **nicht** auf, sondern führt in die Mehrdeutigkeitsbehandlung.
Bei den aktuellen 38 Repos ist kein Stamm doppelt.

### Matching-Regel (in beiden Shells identisch)

1. exakter Match, **case-insensitiv**, über alle drei Namensformen —
   `wkdbooks` findet `WKDBooks`. Auf Linux ist Case-Insensitivität nicht der
   Dateisystem-Default, muss also explizit sein.
2. eindeutiger Präfix-Match. `wkdb` ist bei dir **mehrdeutig**
   (`WKDBooks`, `WKDBook-Tricentis`) und geht damit nach 4.
3. eindeutiger Substring-Match — **nur** in `repo`, nicht beim bloßen Namen.
4. mehrdeutig → Auswahl nach §5, nie raten.
5. kein Treffer → normaler "command not found".

Beim bloßen Namen (pwsh-Hook, zsh-Widget) bewusst nur Stufe 1 und 2: ein
Tippfehler soll ein Fehler bleiben und nicht in einem überraschenden `cd`
enden. `repo` darf großzügiger sein, weil der Aufruf dort explizit ist.

Nach jedem erfolgreichen Sprung ein `zoxide add <ziel>`, damit die Frecency
lernt und `z` mit der Zeit von selbst richtig liegt.

---

## 5. Mehrdeutigkeit

Steuerbar über `$env:REPO_JUMP_PICKER` bzw. `$REPO_JUMP_PICKER`:

* nicht gesetzt → `fzf`, wenn vorhanden, sonst nummerierte Liste
* `fzf` → erzwingt fzf
* `list` → erzwingt die Liste
* `none` → nur Fehlermeldung mit den Kandidaten

Ohne interaktive Konsole (`[Console]::IsInputRedirected` bzw. `[[ ! -t 0 ]]`)
gilt immer `none` — kein blockierender Prompt ohne Terminal (`SH-21`).

---

## 6. Was das für den Installer heißt

Der Installer richtet die Dateien **einmal** ein, wie bisher: `install.ps1
-Only pwsh` bzw. `install.sh`. Ein neu geklontes Repo erfordert **keinen**
erneuten Lauf — weil nichts generiert wird, das veralten könnte. Die Auflösung
liest `$REPOS_DIR` zur Laufzeit, das Seeding hängt an der Stempeldatei. Die
Anforderung wird damit strukturell erfüllt, nicht durch einen
Nachpflege-Mechanismus.

Ablage:

* `Configs/shells/pwsh/Modules/MyCliHelpers` — neben `Get-ReposRoot`, `repos`,
  `Configs`, die schon dieselbe Wurzel benutzen. Der Hook selbst gehört ins
  Profil, weil er Session-State verändert und nicht Modul-Scope.
* `my-zsh/repos.zsh` — neu, eingehängt aus `init.zsh`. `REPOS_DIR` ist dort
  bereits Pflicht (`paths.zsh`).

Kein geteilter Code — die Shells haben keine gemeinsame Ausführungsebene, und
zoxide taugt laut §2 nicht als Brücke. Geteilt wird dieses Dokument als Spec.

Regeln aus `docs/checklisten/regeln/SHELL.md`: `SH-01` (keine Benutzerpfade),
`SH-02` (Plattformlogik gebündelt), `SH-10` (ein Fehler bricht den Profillauf
nicht ab), `SH-13` (Fehlermeldung nennt die Reparatur), `SH-21` (nicht
blockierend fragen).

---

## 7. Kollisionen mit echten Kommandos

Alle 38 Repo-Namen und ihre Stämme wurden gegen die vorhandenen Kommandos
geprüft. Zwei Treffer:

| Name | Kollidiert mit | Verhalten |
| ---- | -------------- | --------- |
| `Configs` | `Configs` aus MyCliHelpers | unkritisch — die Funktion springt bereits genau dorthin |
| `diff` (aus `diff.nvim`) | `diff`-Wrapper in MyCliHelpers; `diff(1)` unter Linux | echtes Kommando gewinnt; Repo bleibt über `diff-nvim`, `diff.nvim` und `repo diff` erreichbar |

Das ist das gewünschte Verhalten und der Grund, warum der Hook der generierten
Alias-Variante vorgezogen wurde: hier kann eine Kollision nie ein echtes
Kommando verdecken. Künftige Kollisionen sind selbstheilend — sie äußern sich
darin, dass eine Kurzform nichts tut, nicht darin, dass ein Kommando kaputtgeht.

---

## 8. Getroffene Entscheidungen

| # | Frage | Entscheidung |
| - | ----- | ------------ |
| 1 | Was gilt als Repo? | Nur Ordner mit `.git`. Trifft aktuell alle 38. |
| 2 | Rekursionstiefe | Nur Tiefe 1. |
| 3 | Bloßer Name als cd | Ja, restriktiv: exakt + eindeutiger Präfix. pwsh über den Command-not-found-Hook, zsh über `cdpath` plus ein `accept-line`-Widget (Begründung in §3). |
| 4 | Mehrdeutigkeit | `fzf` wenn vorhanden, sonst Liste; per Env-Variable übersteuerbar. |
| 5 | Befehlsname | `repo <name>`. `r` ist in pwsh belegt. |
| 6 | `.nvim`-Suffix | Drei Namensformen: voll, Punkt→Bindestrich, Stamm. |
| 7 | Cache | Entfällt. Nur eine Stempeldatei fürs Seeding. |

---

## 9. Offene Punkte

* `--score` fürs Seeding niedrig ansetzen, damit reale Besuche gewinnen —
  konkreter Wert beim Einbau.
* Startzeit messen statt schätzen (`SH-33`). Erwartung: unter 1 ms, weil im
  Normalfall nur ein `stat` und ein Dateilesevorgang anfallen.
* `MYZ_REPO_CDPATH=0` schaltet den `cdpath`-Eintrag in zsh ab, falls sich
  herausstellt, dass er `cd` mit relativen Argumenten stört. Bisher kein Fall
  aufgetreten: `cdpath` wird erst nach `./` geprüft, lokale Verzeichnisse
  gewinnen.

---

## 10. Stand

Implementiert und getestet.

| Datei | Inhalt |
| ----- | ------ |
| `Configs/shells/pwsh/Modules/MyCliHelpers/MyCliHelpers.psm1` | `Resolve-Repo`, `repo`, `Update-RepoSeed`, Completer |
| `Configs/shells/pwsh/Microsoft.PowerShell_profile.ps1` | Abschnitt 10: Command-not-found-Hook, Seeding-Aufruf |
| `my-zsh/repos.zsh` | Auflösung, `repo`, `cdpath`, `accept-line`-Widget, Seeding |
| `my-zsh/init.zsh` | sourct `repos.zsh` |

Keine Installer-Änderung nötig: das pwsh-Modul ist als Verzeichnis verknüpft,
`my-zsh` hängt als Submodul — neue Dateien darin greifen von selbst.

Getestet wurde in einer echten interaktiven zsh unter einem Pseudo-Terminal.
Ohne PTY ist ZLE inaktiv und `AUTO_CD` greift beim Lesen aus einer Skriptdatei
nicht — wer das nachstellt, misst sonst das Testgeschirr statt der Konfiguration.
