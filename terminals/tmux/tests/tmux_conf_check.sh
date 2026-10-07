#!/usr/bin/env bash
#
# Loads terminals/tmux/tmux.conf into a PRIVATE tmux server (own socket, own $HOME, a fake TPM) and
# checks what the file promises:
#   - `source-file` prints nothing and succeeds: tmux reports an unknown command / invalid option /
#     unknown value there, and a single bad line makes tmux discard the WHOLE file at startup. (The
#     check proves itself: three deliberately broken files must be reported.)
#   - TPM runs exactly once
#   - $NVIM is not handed on to the panes (a server started from a Neovim terminal carries it)
#   - allow-passthrough is on (terminal.nvim's status reaches an outer WezTerm)
#   - the terminal.nvim segment of status-right shows for a pane that runs a Vim (nvim, vim, vi,
#     view) and is empty for any other command, even when the pane still holds @terminal_* options
#     -- both when nothing touches status-right and when a theme plugin (the fake TPM sets
#     status-right the way catppuccin-tmux does) replaces it while TPM loads
#
#   bash terminals/tmux/tests/tmux_conf_check.sh
#   MSYS_NO_PATHCONV=1 wsl.exe -d <distro> -e bash /mnt/e/repos/Configs/terminals/tmux/tests/tmux_conf_check.sh
#   TMUX_CONF=/path/to/other.conf bash ...   # check another file (the old one must FAIL)
#
# One line per check, ending in "RESULT ok" / "RESULT failed" (exit code 1). Without tmux: "skip".

set -u

if ! command -v tmux >/dev/null 2>&1; then
  echo "skip (tmux is not installed)"
  echo "RESULT ok"
  exit 0
fi

HERE="$(cd "$(dirname "$0")" && pwd)"
CONF="${TMUX_CONF:-$HERE/../tmux.conf}"
WORK="$(mktemp -d)"
SOCKETS=()
trap 'for s in "${SOCKETS[@]}"; do tmux -S "$s" kill-server 2>/dev/null; done; rm -rf "$WORK"' EXIT

failed=0
check() {
  # check "message" <command...>   -- ok when the command succeeds
  local message="$1"
  shift
  if "$@"; then
    echo "ok   $message"
  else
    echo "FAIL $message"
    failed=1
  fi
}

# The fake TPM: records every call; with FAKE_THEME=1 it also replaces status-right, as a theme does.
export HOME="$WORK/home"
mkdir -p "$HOME/.tmux/plugins/tpm" "$WORK/bin"
cat >"$HOME/.tmux/plugins/tpm/tpm" <<EOF
#!/bin/sh
echo run >> "$WORK/tpm.log"
[ "\${FAKE_THEME:-0}" = 1 ] && tmux set -g status-right "THEME-RIGHT"
exit 0
EOF
chmod +x "$HOME/.tmux/plugins/tpm/tpm"

# "Editors" that are really `sleep`, and non-editors with names that look close.
SLEEP="$(command -v sleep)"
for name in nvim vim vi view nano vite vix less; do
  ln -s "$SLEEP" "$WORK/bin/$name"
done

# wait_command <socket> <window> <command> -- until the pane runs <command> (right after the fork its
# pane_current_command is still `tmux` or the shell; on a busy or single-core machine that lasts
# long enough to fail a check that has nothing to do with the file). Up to 5 s.
wait_command() {
  local i
  for i in $(seq 1 50); do
    [ "$(tmux -S "$1" display -p -t "t:$2" '#{pane_current_command}' 2>/dev/null)" = "$3" ] && return 0
    sleep 0.1
  done
  return 1
}

# start <socket> <fake_theme> -- an empty server with a first window, then the file via source-file
# (its output is what tmux says about every line). $NVIM is in the server's environment, like a
# server that was started from a Neovim terminal.
start() {
  local socket="$1" theme="$2" name
  NVIM=/tmp/confcheck-dead.sock FAKE_THEME="$theme" tmux -S "$socket" -f /dev/null \
    new-session -d -s t -n nano "$WORK/bin/nano 60"
  for name in nvim vim vi view vite vix less; do
    tmux -S "$socket" new-window -d -n "$name" "$WORK/bin/$name 60"
  done
  # an editor pane that never ran terminal.nvim: no @terminal_* options on it
  tmux -S "$socket" new-window -d -n novars "$WORK/bin/vim 60"
  for name in nano nvim vim vi view vite vix less; do
    wait_command "$socket" "$name" "$name" || echo "pane $name did not start" >&2
  done
  wait_command "$socket" novars vim || echo "pane novars did not start" >&2
  FAKE_THEME="$theme" tmux -S "$socket" source-file "$CONF" 2>&1
}

# --- the check itself: broken files must be reported -------------------------------------------
broken_is_reported() {
  local body="$1" file="$WORK/broken.conf" out
  printf '%s\n' "$body" >"$file"
  local socket="$WORK/broken.sock"
  SOCKETS+=("$socket")
  tmux -S "$socket" -f /dev/null new-session -d -s b "$SLEEP 30"
  out="$(tmux -S "$socket" source-file "$file" 2>&1)"
  tmux -S "$socket" kill-server 2>/dev/null
  [ -n "$out" ]
}
check "self-test: an unknown option is reported (TMUX_FZF_LAUNCH_KEY)" broken_is_reported "set -g TMUX_FZF_LAUNCH_KEY 'C-f'"
check "self-test: a shell command is reported (export TERM=...)" broken_is_reported "export TERM=xterm-256color"
check "self-test: an unknown value is reported (status-keys nonsense)" broken_is_reported "set -g status-keys nonsense"

# --- the file, once without and once with a theme that replaces status-right -------------------
suite() {
  local label="$1" theme="$2" socket="$WORK/$1.sock" out
  SOCKETS+=("$socket") # registered HERE: `start` runs in a subshell, an array change there is lost
  rm -f "$WORK/tpm.log" # one count per suite
  out="$(start "$socket" "$theme")"
  loaded() { [ -z "$out" ]; }
  check "[$label] the file loads without a single message ($out)" loaded

  local runs
  runs="$(wc -l <"$WORK/tpm.log" 2>/dev/null || echo 0)"
  check "[$label] TPM has run exactly once for this file (log: $runs)" test "$runs" -eq 1

  local nvim_env
  nvim_env="$(tmux -S "$socket" show-environment -g NVIM 2>&1)"
  no_nvim() { case "$nvim_env" in "-NVIM" | "unknown variable"*) return 0 ;; *) return 1 ;; esac; }
  check "[$label] \$NVIM is not in the server's environment ($nvim_env)" no_nvim

  check "[$label] allow-passthrough is on" test "$(tmux -S "$socket" show -gv allow-passthrough)" = "on"

  local format
  format="$(tmux -S "$socket" show -gv status-right)"
  segment() {
    # segment <window name>: status-right of that window's pane, with terminal.nvim's options set
    local pane
    pane="$(tmux -S "$socket" list-panes -t "t:$1" -F '#{pane_id}' | head -1)"
    [ -n "$pane" ] || return 1
    tmux -S "$socket" set-option -p -t "$pane" @terminal_mode n
    tmux -S "$socket" set-option -p -t "$pane" @terminal_branch main
    tmux -S "$socket" display -p -t "$pane" "$format"
  }
  shown() { local text; text="$(segment "$1")" && printf '%s' "$text" | grep -q 'n main'; }
  hidden() { local text; text="$(segment "$1")" && [ -n "$text" ] && ! printf '%s' "$text" | grep -q 'n main'; }
  for editor in nvim vim vi view; do
    check "[$label] status-right shows the segment for a pane running $editor" shown "$editor"
  done
  # an editor pane that holds no @terminal_* options shows nothing (not even the " | " separator)
  bare() {
    local text
    text="$(tmux -S "$socket" display -p -t t:novars "$format")" && [ -n "$text" ] && ! printf '%s' "$text" | grep -q '|'
  }
  check "[$label] status-right is empty in an editor pane without terminal.nvim options" bare
  once() { [ "$(printf '%s' "$format" | grep -o '#{E:@terminal_status_segment}' | wc -l)" -eq 1 ]; }
  check "[$label] status-right references the segment exactly once" once
  for other in nano vite vix less; do
    check "[$label] status-right hides a stale segment in a pane running $other" hidden "$other"
  done
  if [ "$theme" = 1 ]; then
    themed() { printf '%s' "$(segment nvim)" | grep -q 'THEME-RIGHT'; }
    check "[$label] the theme's own status-right is kept" themed
    in_front() { [ "$format" = '#{E:@terminal_status_segment}THEME-RIGHT' ]; }
    check "[$label] the segment sits IN FRONT of the theme's status-right ($format)" in_front
  fi
  # a reload (the file sourced a second time) leaves status-right as it was
  reloaded() {
    local again
    FAKE_THEME="$theme" tmux -S "$socket" source-file "$CONF" >/dev/null 2>&1
    again="$(tmux -S "$socket" show -gv status-right)"
    [ "$again" = "$format" ]
  }
  check "[$label] sourcing the file again changes nothing (no second copy of the segment)" reloaded
}
suite plain 0
suite theme 1

echo "$([ "$failed" -eq 0 ] && echo 'RESULT ok' || echo 'RESULT failed')"
exit "$failed"
