# Neovim status in the tab title and right status

`config/nvim_status.lua` shows what the Neovim in a pane is doing. The data comes from
[terminal.nvim](https://github.com/StefanBartl/terminal.nvim), which publishes it as per-pane
user variables (OSC 1337 `SetUserVar`); nothing here talks to Neovim.

## Variables

| Variable | Value |
|---|---|
| `MUX_NVIM` | `"1"` while a Neovim with terminal.nvim runs in the pane, `""` after it left |
| `MUX_PIPE` | that Neovim's RPC address (not used here; for control from outside) |
| `MUX_STATUS` | JSON: `{ v, pid, mode, file, ft, cwd, branch, e, w, i, h, rec, mod }`; `mode` is Neovim's mode code with CTRL-V / CTRL-S spelled out as `^V` / `^S` |

## What it does

- **Tab title** (`config/tabtitle.lua`): ` <file> +  E2 W1` — the file name, `+` when modified,
  error / warning counts. Without a status (no Neovim, or one without terminal.nvim) the title is
  what it was before.
- **Right status** (`update-right-status`): recording (`REC @q`), diagnostics, branch, and a mode
  chip (`NORMAL`, `INSERT`, ...). It shows the Neovim of the **focused** pane; WezTerm's
  `update-status` event only sees that one.

## Safety

Everything read from the pane is untrusted text. `nvim_status.read` refuses a value over
`max_bytes` (2048), a version newer than `max_version`, malformed JSON, and strips control
characters (a name cut to length is cut at a character boundary; text that is not valid UTF-8
shows nothing). A Neovim that died without clearing its variables is detected by checking that
the pane's foreground process still looks like Neovim (`require_nvim_process`); `process_names`
also lists `tmux`, `ssh`, `wsl` and `mosh`, because a Neovim inside tmux (with
`allow-passthrough on`), over ssh or in WSL is not the pane's foreground process itself.

`format-tab-title` is handed a `PaneInformation` snapshot, not a `Pane`: it has no
`get_user_vars()` but a `user_vars` field (and `foreground_process_name`). `read` and `is_nvim`
accept both, so the tab title works as well as the right status.

`tests/nvim_status_check.lua` checks all of this without WezTerm (stubbed `wezterm` module):
`nvim --headless -u NONE -l terminals/wezterm/tests/nvim_status_check.lua`.

## Options

`require("config.nvim_status").setup({ ... })` — `max_version`, `max_bytes`,
`require_nvim_process`, `process_names`, `modes` (label and ANSI colour per mode),
`show_mode`, `show_branch`, `show_diagnostics`, `show_recording`, `branch_icon`.

## Helper for keys

`nvim_status.is_nvim(pane)` is true when a Neovim with terminal.nvim runs in the pane — the
test a key binding needs to decide "pass this key to Neovim or handle it in WezTerm". It reads
the pane's variables and asks the OS for its foreground process, so `keybindings.lua` calls it only
when `shell_panes = "navigate"` needs the answer.

## Navigation keys

`config/keybindings.lua` binds `<C-h>`, `<C-j>` and `<C-k>` (not `<C-l>`: it stays the shell's
clear-screen, like terminal.nvim's `window_right`). Where a Neovim with terminal.nvim runs
(`is_nvim`), the key is sent to it unchanged: Neovim moves between its own windows and, at its
edge, asks WezTerm itself (`wezterm cli activate-pane-direction`, see terminal.nvim
`docs/navigation.md`). In any other pane the key keeps its shell meaning (`<C-j>` newline,
`<C-k>` kill-line, `<C-h>` backspace). Set `NAVIGATION.shell_panes = "navigate"` to make the
keys move between WezTerm panes there too, like vim-tmux-navigator, at the price of those
shell bindings. `NAVIGATION.enabled = false` removes the bindings.

