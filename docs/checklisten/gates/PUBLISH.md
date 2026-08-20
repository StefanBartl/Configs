# Gate — vor dem Push in ein öffentliches Repo

Dieses Repo ist public. Ein Push ist unwiderruflich: was einmal auf GitHub
war, kann geklont, gespiegelt und indiziert worden sein — auch nach einem
Force-Push.

Vollständige Fassung der Regeln: [`regeln/SECRETS.md`](../regeln/SECRETS.md).

---

## Schnell-Check

| Status | Prüfschritt | Kurzbeschreibung | Priorität | Regel |
| ------ | ----------- | ---------------- | --------- | ----- |
| `[ ]` | Diff vollständig gelesen | Nicht nur die Dateinamen | 🔴 KRITISCH | `KEY-01` |
| `[ ]` | Keine Schlüssel, keine Tokens | Auch nicht in Beispielen oder Kommentaren | 🔴 KRITISCH | `KEY-01` |
| `[ ]` | Kein privates Schlüsselmaterial | VPN, SSH, Zertifikate | 🔴 KRITISCH | `KEY-02` |
| `[ ]` | Keine Bilder mit Schlüsseln | Screenshots werden von keinem Scanner gefunden | 🔴 KRITISCH | `KEY-03` |
| `[ ]` | Nichts bloß Privates | Bookmarks, Inventare, Geräteprofile gehören nach `machine-assets` | 🟡 EMPFOHLEN | `KEY-10` |
| `[ ]` | Keine neuen Binaries | Repo-Größe bleibt klein | 🔴 KRITISCH | `DOT-03` |
| `[ ]` | Kein History-Rewrite ohne Not | Force-Push nur mit Grund und mit Ansage | 🟡 EMPFOHLEN | `KEY-21` |

---

## Prüfbefehle

Staged-Diff auf die üblichen Muster:

```bash
git diff --cached -U0 | grep -nEi "sk-[a-z]+-|PrivateKey *=|PresharedKey *=|BEGIN [A-Z ]*PRIVATE KEY|password *=|token *="
```

Was tatsächlich neu ins Repo kommt, nach Größe:

```bash
git diff --cached --stat
```

---

## Wenn doch etwas durchgerutscht ist

Reihenfolge, nicht verhandelbar (`KEY-20`):

1. **Rotieren.** Schlüssel ungültig machen, Peers entfernen, Token widerrufen.
   Ab Veröffentlichung ist er kompromittiert — der Purge ändert daran nichts.
2. **Purgen.** `git filter-repo` über **alle** Branches, nicht nur den
   betroffenen (`KEY-21`).
3. **Verifizieren.** Alle Blobs scannen, nicht nur den Worktree (`KEY-22`).
4. **Andere Worktrees zurücksetzen**, sonst bleiben die alten Objekte lokal
   erreichbar und `git gc` bringt nichts (`KEY-23`).
5. **Dokumentieren.** Was betroffen war, was getan wurde, in welcher
   Reihenfolge — nach dem Muster von [RESTRUCTURE.md § 0](../../RESTRUCTURE.md).

Vorher prüfen, ob offene PRs, Forks oder Tags die alten Objekte am Leben
halten. GitHub gibt gepurgte Blobs nicht zwingend sofort frei.
