# Gate — vor jedem Merge

Jede Regel steht hier **genau einmal** in Kurzform. Vollständige Fassung und
Beleg stehen in [`regeln/`](../regeln/).

Betrifft der Change Lua-Code (`terminals/wezterm/**`), zusätzlich die
kanonische Sammlung: `WKDBooks/Development/wkdbook-Lua/Checklists/gates/REVIEW.md`,
Abschnitte Code-Stil, Annotationen, Fehlerbehandlung, Sicherheit.

---

## Schnell-Check

| Status | Prüfschritt | Kurzbeschreibung | Priorität | Regel |
| ------ | ----------- | ---------------- | --------- | ----- |
| `[ ]` | Keine Geheimnisse | Diff auf Schlüssel, Tokens, private Configs, Screenshots geprüft | 🔴 KRITISCH | `KEY-01` `KEY-02` `KEY-03` |
| `[ ]` | Gehört es hierher? | Layer A — kein Asset, kein Build-Output, kein eigenständiges Projekt | 🔴 KRITISCH | `DOT-01` `DOT-02` `DOT-04` |
| `[ ]` | Keine Binaries | Nichts Heruntergeladenes einchecken | 🔴 KRITISCH | `DOT-03` |
| `[ ]` | Keine Benutzerpfade | Kein `C:\Users\<name>`, kein hartes `/home/<name>` | 🔴 KRITISCH | `SH-01` |
| `[ ]` | Neue Verknüpfung im Manifest | Nicht in einem der beiden Installer-Skripte | 🔴 KRITISCH | `DOT-10` |
| `[ ]` | Beide Plattformen bedacht | Betrifft die Änderung nur eine, ist die Zeile plattformmarkiert | 🟡 EMPFOHLEN | `DOT-05` |
| `[ ]` | Zeilenenden | Neue Dateitypen in `.gitattributes` eingetragen | 🔴 KRITISCH | `SH-06` |
| `[ ]` | Trockenlauf gelaufen | Beide Installer mit `--dry-run`/`-DryRun` geprüft | 🟡 EMPFOHLEN | `DOT-15` |
| `[ ]` | Fehler brechen nichts ab | Neue Profil-/Modul-Logik ist gekapselt | 🔴 KRITISCH | `SH-10` `SH-12` |
| `[ ]` | Globale Zustände zurückgegeben | `$ErrorActionPreference`, `$PATH`, `IFS` wiederhergestellt | 🔴 KRITISCH | `SH-11` |
| `[ ]` | Nichts läuft ungefragt | Keine Tastenbelegung mit Nebenwirkung, keine blockierende Abfrage | 🔴 KRITISCH | `SH-20` `SH-21` |
| `[ ]` | Optimierung belegt | Performance-Änderung hat eine Zahl davor | 🟡 EMPFOHLEN | `SH-33` |
| `[ ]` | Fehlermeldungen nennen die Reparatur | Nicht nur, was fehlt | 🟡 EMPFOHLEN | `SH-13` |
| `[ ]` | Doku nachgezogen | Betroffene README/ROADMAP/RESTRUCTURE aktualisiert, keine toten Links | 🟡 EMPFOHLEN | — |
| `[ ]` | Diagnose grün | `Test-ProfileHealth` nach dem Change | 🟡 EMPFOHLEN | `DOT-21` |

---

## Detailprüfung

### Wenn Pfade im Repo verschoben wurden

Dann ist der Merge nicht das Ende. Jede Maschine, auf der das Repo installiert
ist, hat jetzt Verknüpfungen ins Leere (`DOT-20`). In die PR-/Commit-Beschreibung
gehört der Reparaturbefehl:

```bash
pwsh -File .\install\install.ps1 -Force
```

Und die Prüfung, ob `Test-ProfileHealth` die kaputte Verknüpfung tatsächlich
meldet — ein Umbau, den die Diagnose nicht sieht, fällt sonst erst Wochen
später auf.

### Wenn eine Datei außerhalb des Repos auf das Repo zeigt

Dann gehört sie ins Repo und wird von dort verlinkt (`DOT-11`). Ein Snippet
zum Einkopieren ist keine Lösung, sondern eine Kopie pro Maschine, die beim
nächsten Umbau still veraltet.

### Wenn ein Skript neu ist

* Shebang und Zeilenenden geprüft (`SH-06`)
* Läuft es aus jedem Arbeitsverzeichnis? (`SH-05`)
* Läuft es ohne TTY, ohne zu blockieren? (`SH-21`)
* Läuft es ohne Adminrechte? (`DOT-14`)
