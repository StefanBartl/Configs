# Regeln — Geheimnisse

Dieses Repo ist **public**. Es hat einmal Zugangsdaten öffentlich gemacht;
die Aufarbeitung steht in [RESTRUCTURE.md § 0](../../RESTRUCTURE.md).
Diese Regeln sind das Ergebnis davon.

Prioritäten-Legende: [README.md](../README.md#prioritäten-legende)

---

## 1. Was nie ins Repo darf

| ID | Regel | Beschreibung | Priorität | Beleg |
| -- | ----- | ------------ | --------- | ----- |
| `KEY-01` | Keine API-Schlüssel | Auch nicht „vorübergehend", auch nicht in einer Datei, die gleich wieder gelöscht wird. Ein Commit reicht. | 🔴 KRITISCH | `env/.openai_env` lag ab `b92cb6e` durchgehend in `main` |
| `KEY-02` | Kein privates Schlüsselmaterial | VPN-Configs mit `PrivateKey`/`PresharedKey`, SSH-Keys, Zertifikate mit privatem Teil. | 🔴 KRITISCH | 4 WireGuard-Configs, 7 `.ovpn`-Profile |
| `KEY-03` | Auch keine Screenshots davon | Ein Bild eines Schlüssels ist ein Schlüssel. Grep findet es nicht. | 🔴 KRITISCH | `VPN/RemotePlay/WG-keys.png` |
| `KEY-04` | Zur Laufzeit laden | Muster aus `my-zsh`: `secrets.zsh` liest aus `~/personel_env/`, außerhalb des Repos. Das ist die Zielvorgabe für **alle** Plattformen. | 🔴 KRITISCH | `my-zsh` war bei der Prüfung sauber, weil es das schon so machte |
| `KEY-05` | `.gitignore` als Netz, nicht als Lösung | Die Pfade sind ignoriert, damit sie nicht versehentlich zurückkommen. Das ersetzt keine der Regeln darüber. | 🟡 EMPFOHLEN | — |

## 2. Privates, das kein Geheimnis ist

Nicht alles Persönliche ist ein Schlüssel. Die Unterscheidung ist bewusst
getroffen worden und gehört zur Regel dazu:

| ID | Regel | Beschreibung | Priorität | Beleg |
| -- | ----- | ------------ | --------- | ----- |
| `KEY-10` | Privacy getrennt bewerten | Bookmarks, Software-Inventare, Geräteprofile sind kein Sicherheitsvorfall, gehören aber trotzdem nicht in ein öffentliches Repo — sie wandern nach `machine-assets` (privat). | 🟡 EMPFOHLEN | `Settings_Profiles/`, `docker-cred/` — bewusst *nicht* als Secret eingestuft, dennoch ausgelagert |

## 3. Wenn es doch passiert ist

| ID | Regel | Beschreibung | Priorität | Beleg |
| -- | ----- | ------------ | --------- | ----- |
| `KEY-20` | Erst rotieren, dann purgen | Der Schlüssel ist ab Veröffentlichung kompromittiert. Die History zu putzen macht ihn nicht wieder gültig — ungültig machen ist Schritt eins. | 🔴 KRITISCH | Reihenfolge in [RESTRUCTURE § 0](../../RESTRUCTURE.md) |
| `KEY-21` | Alle Refs purgen | `git filter-repo` über **jeden** Branch, nicht nur `main`. Tags und offene PRs halten alte Blobs sonst am Leben. | 🔴 KRITISCH | `main` und `main-unix`; PRs/Tags wurden vorher geprüft |
| `KEY-22` | Purge verifizieren | Nach dem Rewrite alle Blobs scannen, nicht nur den Worktree. Ergebnis dokumentieren. | 🔴 KRITISCH | Scan auf `sk-proj-`, `PrivateKey =`, `PresharedKey =` über alle Objekte: 0 Treffer |
| `KEY-23` | Andere Worktrees mitziehen | Ein stehengebliebener Worktree auf einem Vor-Purge-Commit hält die alten Objekte lokal am Leben und macht `git gc` wirkungslos. | 🟡 EMPFOHLEN | Genau das passierte beim Größen-Purge; `.git` schrumpfte erst nach dem Reset des dritten Worktrees |
