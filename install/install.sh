#!/usr/bin/env bash
#
# Configs — Installer fuer Linux/macOS/WSL.
#
# Legt Symlinks gemaess install/links.conf an (Zeilen mit Plattform "unix"
# oder "all"). Gegenstueck: install/install.ps1 fuer Windows, das dieselbe
# Manifestdatei liest.
#
# Nutzung:
#   ./install/install.sh              # installieren
#   ./install/install.sh --dry-run    # nur anzeigen, nichts aendern
#   ./install/install.sh --force      # vorhandene echte Dateien ersetzen
#                                     # (Backup als <ziel>.bak-<zeitstempel>)
#
set -euo pipefail

DRY_RUN=0
FORCE=0

usage() {
  sed -n '3,13p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force)   FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unbekannte Option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# --- Pfade ----------------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$SCRIPT_DIR/links.conf"

if [ ! -f "$MANIFEST" ]; then
  echo "Manifest nicht gefunden: $MANIFEST" >&2
  exit 1
fi

XDG_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

# --- Ausgabe --------------------------------------------------------------

if [ -t 1 ]; then
  C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_ERR=$'\033[31m'
  C_DIM=$'\033[2m'; C_OFF=$'\033[0m'
else
  C_OK=''; C_WARN=''; C_ERR=''; C_DIM=''; C_OFF=''
fi

n_linked=0
n_skipped=0
n_failed=0

info() { printf '%s[info]%s %s\n'  "$C_DIM"  "$C_OFF" "$1"; }
ok()   { printf '%s[ ok ]%s %s\n'  "$C_OK"   "$C_OFF" "$1"; }
warn() { printf '%s[warn]%s %s\n'  "$C_WARN" "$C_OFF" "$1" >&2; }
err()  { printf '%s[fail]%s %s\n'  "$C_ERR"  "$C_OFF" "$1" >&2; }

# --- Submodule (my-zsh unter shells/zsh) ----------------------------------

init_submodules() {
  [ -f "$REPO_ROOT/.gitmodules" ] || return 0
  command -v git >/dev/null 2>&1 || { warn "git nicht gefunden — Submodule uebersprungen"; return 0; }

  # Nur initialisieren, wenn wirklich noch nichts ausgecheckt ist.
  if [ -e "$REPO_ROOT/shells/zsh/.zshrc" ]; then
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    info "(dry-run) git submodule update --init --recursive"
    return 0
  fi

  info "Initialisiere Submodule (shells/zsh -> my-zsh) ..."
  git -C "$REPO_ROOT" submodule update --init --recursive
}

# --- Token-Expansion ------------------------------------------------------

expand_target() {
  local t="$1"
  t="${t//\$XDG_CONFIG/$XDG_CONFIG}"
  t="${t//\$HOME/$HOME}"
  printf '%s' "$t"
}

# --- Eine Verknuepfung anlegen -------------------------------------------

link_one() {
  local kind="$1" src_rel="$2" target="$3"
  local src="$REPO_ROOT/$src_rel"

  if [ ! -e "$src" ]; then
    warn "Quelle fehlt, uebersprungen: $src_rel"
    n_skipped=$((n_skipped + 1))
    return 0
  fi

  # Bereits korrekt verlinkt?
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
    info "bereits verlinkt: $target"
    n_skipped=$((n_skipped + 1))
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '%s[dry ]%s %s -> %s\n' "$C_DIM" "$C_OFF" "$target" "$src_rel"
    n_linked=$((n_linked + 1))
    return 0
  fi

  mkdir -p -- "$(dirname -- "$target")"

  # Existierendes Ziel behandeln: Symlinks duerfen weg, echte Dateien nur
  # mit --force (und dann mit Backup).
  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ -L "$target" ]; then
      rm -f -- "$target"
    elif [ "$FORCE" -eq 1 ]; then
      local backup="$target.bak-$(date +%Y%m%d%H%M%S)"
      mv -- "$target" "$backup"
      warn "vorhandene Datei gesichert: $backup"
    else
      warn "existiert bereits (echte Datei), --force noetig: $target"
      n_skipped=$((n_skipped + 1))
      return 0
    fi
  fi

  if ln -sfn -- "$src" "$target" 2>/dev/null; then
    ok "$target -> $src_rel"
    n_linked=$((n_linked + 1))
  else
    err "Symlink fehlgeschlagen: $target"
    n_failed=$((n_failed + 1))
  fi

  # kind wird auf POSIX nicht unterschieden (ln -s kann beides); das Feld
  # existiert fuer Windows, wo Verzeichnisse als Junction angelegt werden.
  : "$kind"
}

# --- Ablauf ---------------------------------------------------------------

info "Repo:     $REPO_ROOT"
info "Manifest: $MANIFEST"
[ "$DRY_RUN" -eq 1 ] && info "Modus:    dry-run (es wird nichts geaendert)"

init_submodules

while read -r platform kind src target _rest; do
  case "$platform" in
    ''|\#*) continue ;;
    unix|all) ;;
    *) continue ;;
  esac
  [ -n "${target:-}" ] || continue
  link_one "$kind" "$src" "$(expand_target "$target")"
done < <(sed 's/#.*$//' "$MANIFEST")

printf '\n'
info "verlinkt: $n_linked, uebersprungen: $n_skipped, fehlgeschlagen: $n_failed"

if [ "$n_failed" -gt 0 ]; then
  exit 1
fi
