# Gate — neue Maschine einrichten

Einmal pro Maschine. Danach genügt `Test-ProfileHealth` bzw. ein erneuter
Installer-Lauf.

Die Spalte **Regel** verweist auf `regeln/` — dort steht die vollständige
Fassung samt Beleg. Hier steht nur die Kurzform zum Abhaken.

---

## Schnell-Check

| Status | Schritt | Kurzbeschreibung | Priorität | Regel |
| ------ | ------- | ---------------- | --------- | ----- |
| `[ ]` | `REPOS_DIR` gesetzt | Zeigt auf das Verzeichnis, das die Repos enthält — dauerhaft, nicht nur in der laufenden Shell | 🔴 KRITISCH | `SH-01` |
| `[ ]` | Repo geklont | nach `$REPOS_DIR/Configs` | 🔴 KRITISCH | — |
| `[ ]` | Trockenlauf gelesen | `--dry-run` zeigt, was passieren würde | 🟡 EMPFOHLEN | `DOT-15` |
| `[ ]` | Komponenten gewählt | Nur was diese Maschine wirklich braucht | 🟡 EMPFOHLEN | `DOT-16` |
| `[ ]` | Installer gelaufen | ohne Adminrechte, ohne Fehler | 🔴 KRITISCH | `DOT-14` |
| `[ ]` | Keine `KOPIE`-Warnung | Kopien folgen dem Repo nicht — Ursache klären | 🔴 KRITISCH | `DOT-12` |
| `[ ]` | Programme installiert | Der Installer verlinkt nur Config; fehlende Tools nennt er | 🟡 EMPFOHLEN | `DOT-16` |
| `[ ]` | Diagnose grün | `Test-ProfileHealth` ohne `fail` | 🔴 KRITISCH | `DOT-21` |
| `[ ]` | Secrets außerhalb angelegt | `~/personel_env/` — nie im Repo | 🔴 KRITISCH | `KEY-04` |

---

## Ablauf

### 1. Umgebung

`REPOS_DIR` muss auch in der GUI-Session gesetzt sein, nicht nur in der
Login-Shell — sonst findet der WezTerm-Loader das Repo nicht.

* Linux/WSL: `~/.zshenv` oder `environment.d`
* Windows: Benutzer-Umgebungsvariable

### 2. Klonen und installieren

```bash
git clone https://github.com/StefanBartl/Configs.git "$REPOS_DIR/Configs"
```

```bash
cd "$REPOS_DIR/Configs" && ./install/install.sh --dry-run
```

```bash
cd "$REPOS_DIR/Configs" && ./install/install.sh
```

Unter Windows dasselbe mit `install\install.ps1` (`-DryRun`, dann ohne).
Aufrufarten und Komponentenliste: [`install/README.md`](../../../install/README.md).

### 3. Prüfen

```bash
pwsh -Command "Test-ProfileHealth"
```

`warn` ist zulässig, wenn ein Tool auf dieser Maschine bewusst fehlt.
`fail` nicht — dort steht der Reparaturbefehl dabei.

### 4. Geheimnisse

Nichts davon kommt aus dem Repo. Anlegen nach dem Muster aus `my-zsh`:
`~/personel_env/<datei>` mit den nötigen Variablen, geladen zur Laufzeit.
