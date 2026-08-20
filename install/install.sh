#!/usr/bin/env bash
#
# Configs — Installer fuer Linux/macOS/WSL.
#
# Legt Symlinks gemaess install/links.conf an. Gegenstueck: install/install.ps1
# fuer Windows, das dieselbe Manifestdatei liest.
#
# Nutzung:
#   ./install/install.sh                    # Komponenten interaktiv auswaehlen
#   ./install/install.sh --all              # alles ohne Rueckfrage
#   ./install/install.sh --only wezterm,zsh # nur diese Komponenten
#   ./install/install.sh --skip glow        # alles ausser diesen
#   ./install/install.sh --list             # Komponenten anzeigen, nichts tun
#   ./install/install.sh --dry-run          # nur anzeigen, nichts aendern
#   ./install/install.sh --force            # vorhandene echte Dateien ersetzen
#                                           # (Backup als <ziel>.bak-<zeitstempel>)
#
# Configs verlinkt Konfiguration — es installiert keine Programme.
#
set -euo pipefail

DRY_RUN=0
FORCE=0
LIST_ONLY=0
SELECT_ALL=0
ONLY=""
SKIP=""

usage() {
  sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force)   FORCE=1 ;;
    --list)    LIST_ONLY=1 ;;
    --all)     SELECT_ALL=1 ;;
    --only)    ONLY="${2:-}"; shift ;;
    --only=*)  ONLY="${1#--only=}" ;;
    --skip)    SKIP="${2:-}"; shift ;;
    --skip=*)  SKIP="${1#--skip=}" ;;
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
PLATFORM="unix"

# --- Ausgabe --------------------------------------------------------------

if [ -t 1 ]; then
  C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_ERR=$'\033[31m'
  C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'; C_OFF=$'\033[0m'
else
  C_OK=''; C_WARN=''; C_ERR=''; C_BOLD=''; C_DIM=''; C_OFF=''
fi

n_linked=0
n_skipped=0
n_failed=0

info() { printf '%s[info]%s %s\n'  "$C_DIM"  "$C_OFF" "$1"; }
ok()   { printf '%s[ ok ]%s %s\n'  "$C_OK"   "$C_OFF" "$1"; }
warn() { printf '%s[warn]%s %s\n'  "$C_WARN" "$C_OFF" "$1" >&2; }
err()  { printf '%s[fail]%s %s\n'  "$C_ERR"  "$C_OFF" "$1" >&2; }

# --- Manifest einlesen ----------------------------------------------------

# Registry: parallele Arrays, damit bash 3.2 (macOS) mitspielt.
comp_names=()
comp_cmds=()
comp_descs=()

read_registry() {
  local first rest name cmd desc
  while read -r first name cmd desc; do
    [ "$first" = "component" ] || continue
    [ -n "$name" ] || continue
    comp_names+=("$name")
    comp_cmds+=("$cmd")
    comp_descs+=("$desc")
  done < <(strip_comments)
}

strip_comments() {
  sed 's/#.*$//' "$MANIFEST"
}

# Hat die Komponente auf DIESER Plattform ueberhaupt Eintraege?
component_applies() {
  local want="$1" platform component _rest
  while read -r platform component _rest; do
    [ "$platform" = "$PLATFORM" ] || [ "$platform" = "all" ] || continue
    [ "$component" = "$want" ] && return 0
  done < <(strip_comments)
  return 1
}

index_of() {
  local needle="$1" i
  for i in "${!comp_names[@]}"; do
    if [ "${comp_names[$i]}" = "$needle" ]; then
      printf '%s' "$i"
      return 0
    fi
  done
  return 1
}

# --- Komponentenauswahl ---------------------------------------------------

available=()     # Komponenten mit Eintraegen fuer diese Plattform
selected=()

collect_available() {
  local name
  for name in "${comp_names[@]}"; do
    if component_applies "$name"; then
      available+=("$name")
    fi
  done
}

cmd_hint() {
  local name="$1" idx cmd
  idx="$(index_of "$name")" || return 0
  cmd="${comp_cmds[$idx]}"
  [ -n "$cmd" ] && [ "$cmd" != "-" ] || return 0
  command -v "$cmd" >/dev/null 2>&1 && return 0
  printf '%s' "$cmd"
}

print_components() {
  local i name idx missing
  printf '%sVerfuegbare Komponenten (Plattform: %s)%s\n\n' "$C_BOLD" "$PLATFORM" "$C_OFF"
  for i in "${!available[@]}"; do
    name="${available[$i]}"
    idx="$(index_of "$name")" || continue
    missing="$(cmd_hint "$name")"
    printf '  %2d) %-10s %s' "$((i + 1))" "$name" "${comp_descs[$idx]}"
    if [ -n "$missing" ]; then
      printf ' %s(%s nicht im PATH)%s' "$C_WARN" "$missing" "$C_OFF"
    fi
    printf '\n'
  done
  printf '\n'
}

# Auswahlstring (Namen und/oder Nummern, komma-/leerzeichengetrennt) -> selected
resolve_selection() {
  local input="$1" token i name found
  input="${input//,/ }"
  for token in $input; do
    found=0
    # Nummer?
    if [ "$token" -eq "$token" ] 2>/dev/null; then
      i=$((token - 1))
      if [ "$i" -ge 0 ] && [ "$i" -lt "${#available[@]}" ]; then
        selected+=("${available[$i]}")
        found=1
      fi
    else
      for name in "${available[@]}"; do
        if [ "$name" = "$token" ]; then
          selected+=("$token")
          found=1
          break
        fi
      done
    fi
    [ "$found" -eq 1 ] || warn "unbekannte Komponente, ignoriert: $token"
  done
}

interactive_select() {
  print_components
  printf 'Auswahl (Nummern oder Namen, Leer = alle, q = abbrechen): '
  local reply=""
  read -r reply || reply=""
  case "$reply" in
    q|Q) info "abgebrochen"; exit 0 ;;
    '') selected=("${available[@]}") ;;
    *) resolve_selection "$reply" ;;
  esac
}

is_selected() {
  local needle="$1" s
  for s in "${selected[@]}"; do
    [ "$s" = "$needle" ] && return 0
  done
  return 1
}

# --- Submodule (my-zsh unter shells/zsh) ----------------------------------

init_submodules() {
  is_selected zsh || return 0
  [ -f "$REPO_ROOT/.gitmodules" ] || return 0
  command -v git >/dev/null 2>&1 || { warn "git nicht gefunden — Submodule uebersprungen"; return 0; }

  # Nur initialisieren, wenn wirklich noch nichts ausgecheckt ist.
  [ -e "$REPO_ROOT/shells/zsh/.zshrc" ] && return 0

  if [ "$DRY_RUN" -eq 1 ]; then
    info "(dry-run) git submodule update --init --recursive"
    return 0
  fi

  info "Initialisiere Submodul (shells/zsh -> my-zsh) ..."
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

read_registry
collect_available

if [ "${#available[@]}" -eq 0 ]; then
  err "Manifest enthaelt keine Komponenten fuer Plattform '$PLATFORM'"
  exit 1
fi

if [ "$LIST_ONLY" -eq 1 ]; then
  print_components
  exit 0
fi

if [ -n "$ONLY" ]; then
  resolve_selection "$ONLY"
elif [ "$SELECT_ALL" -eq 1 ] || [ ! -t 0 ]; then
  # Ohne TTY (Pipe, CI) nicht blockierend nachfragen, sondern alles nehmen.
  selected=("${available[@]}")
else
  interactive_select
fi

if [ -n "$SKIP" ] && [ "${#selected[@]}" -gt 0 ]; then
  skip_list=" ${SKIP//,/ } "
  remaining=()
  for s in "${selected[@]}"; do
    case "$skip_list" in
      *" $s "*) ;;
      *) remaining+=("$s") ;;
    esac
  done
  selected=()
  [ "${#remaining[@]}" -gt 0 ] && selected=("${remaining[@]}")
fi

if [ "${#selected[@]}" -eq 0 ]; then
  info "keine Komponente ausgewaehlt — nichts zu tun"
  exit 0
fi

info "Repo:        $REPO_ROOT"
info "Manifest:    $MANIFEST"
info "Komponenten: ${selected[*]}"
[ "$DRY_RUN" -eq 1 ] && info "Modus:       dry-run (es wird nichts geaendert)"

for s in "${selected[@]}"; do
  missing="$(cmd_hint "$s")"
  [ -n "$missing" ] && info "Hinweis: '$missing' ist nicht im PATH — Config wird trotzdem verlinkt"
done

init_submodules

while read -r platform component kind src target _rest; do
  case "$platform" in
    ''|component) continue ;;
    unix|all) ;;
    *) continue ;;
  esac
  [ -n "${target:-}" ] || continue
  is_selected "$component" || continue
  link_one "$kind" "$src" "$(expand_target "$target")"
done < <(strip_comments)

printf '\n'
info "verlinkt: $n_linked, uebersprungen: $n_skipped, fehlgeschlagen: $n_failed"

[ "$n_failed" -gt 0 ] && exit 1
exit 0
