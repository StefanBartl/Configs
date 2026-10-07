#!/usr/bin/env bash
#
# Loads terminals/tmux/tmux.conf into a PRIVATE tmux server (own socket, own $HOME, a fake TPM) and
# checks what the file promises:
#   - it loads without tmux reporting an unknown command / invalid option (a single bad line makes
#     tmux discard the WHOLE file)
#   - TPM runs exactly once
#   - $NVIM is not handed on to the panes (a server started from a Neovim terminal carries it)
#   - allow-passthrough is on (terminal.nvim's status reaches an outer WezTerm)
#   - the terminal.nvim segment of status-right shows for a pane that runs a Vim (nvim, vim, vi,
#     view) and is empty for any other command, even when the pane still holds @terminal_* options
#
#   bash terminals/tmux/tests/tmux_conf_check.sh
#   wsl.exe -d <distro> -e bash /mnt/e/repos/Configs/terminals/tmux/tests/tmux_conf_check.sh
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
SOCKET="confcheck-$$"
WORK="$(mktemp -d)"
trap 'tmux -L "$SOCKET" kill-server 2>/dev/null; rm -rf "$WORK"' EXIT

failed=0
check() {
  # check "name" <command...>   -- ok when the command succeeds
  local name="$1"
  shift
  if "$@"; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    failed=1
  fi
}

# A fake TPM that records every invocation, a bin directory of "editors" that are really `sleep`.
export HOME="$WORK/home"
mkdir -p "$HOME/.tmux/plugins/tpm" "$WORK/bin"
printf '#!/bin/sh\necho run >> "%s/tpm.log"\n' "$WORK" >"$HOME/.tmux/plugins/tpm/tpm"
chmod +x "$HOME/.tmux/plugins/tpm/tpm"
SLEEP="$(command -v sleep)"
for name in nvim vim vi view nano; do
  ln -s "$SLEEP" "$WORK/bin/$name"
done

# The server is started with a $NVIM in its environment, like one started from a Neovim terminal.
NVIM=/tmp/confcheck-dead.sock tmux -L "$SOCKET" -f "$CONF" new-session -d -s t "$WORK/bin/nano 60"
for name in nvim vim vi view; do
  tmux -L "$SOCKET" new-window -d -n "$name" "$WORK/bin/$name 60"
done
sleep 1

messages="$(tmux -L "$SOCKET" show-messages 2>&1)"
no_errors() { ! printf '%s' "$messages" | grep -qiE 'unknown command|ambiguous|invalid|unknown option'; }
check "the file loads without tmux reporting an error" no_errors

tpm_runs="$(wc -l <"$WORK/tpm.log" 2>/dev/null || echo 0)"
check "TPM runs exactly once (ran $tpm_runs times)" test "$tpm_runs" -eq 1

nvim_env="$(tmux -L "$SOCKET" show-environment -g NVIM 2>&1)"
no_nvim() { case "$nvim_env" in "-NVIM" | "unknown variable"*) return 0 ;; *) return 1 ;; esac; }
check "\$NVIM is not in the server's environment ($nvim_env)" no_nvim

check "allow-passthrough is on" test "$(tmux -L "$SOCKET" show -gv allow-passthrough)" = "on"

format="$(tmux -L "$SOCKET" show -gv status-right)"
segment() {
  # segment <window>: the status-right text of that window's pane, with terminal.nvim's options set
  local pane
  pane="$(tmux -L "$SOCKET" list-panes -t "t:$1" -F '#{pane_id}' | head -1)"
  tmux -L "$SOCKET" set-option -p -t "$pane" @terminal_mode n
  tmux -L "$SOCKET" set-option -p -t "$pane" @terminal_branch main
  tmux -L "$SOCKET" display -p -t "$pane" "$format"
}
for editor in nvim vim vi view; do
  # (bash scoping is dynamic: `check` has its own `name`, so the loop variable is called differently)
  shown() { segment "$1" | grep -q 'n main'; }
  check "status-right shows the segment for a pane running $editor" shown "$editor"
done
hidden() { ! segment "$1" | grep -q 'n main'; }
check "status-right hides a stale segment in a pane running something else (nano)" hidden 1

echo "$([ "$failed" -eq 0 ] && echo 'RESULT ok' || echo 'RESULT failed')"
exit "$failed"
