# Fonts-Varianten

## moderne humanistische monospace-fonts

### Inter Mono

ruhiger, sehr gut lesbarer font mit wenig „coding-klischees“, wirkt modern und neutral.

```lua
-- Modern humanistic style with excellent readability
Config.font = wezterm.font_with_fallback {
  {
    family = "Inter Mono",
    weight = "Regular",
    harfbuzz_features = {
      -- Stylistic alternates for clarity
      "cv01", -- alternate a
      "cv02", -- alternate l
      "cv03", -- slashed zero
    },
  },
  { family = "Noto Color Emoji" },
}
```

geeignet, wenn man lange liest oder viel prose + code mischt.

---

### IBM Plex Mono

technisch, aber warm, sehr gute unterscheidbarkeit von ähnlichen zeichen.

```lua
-- Technical but friendly corporate-style monospace
Config.font = wezterm.font_with_fallback {
  {
    family = "IBM Plex Mono",
    weight = "Regular",
    harfbuzz_features = {
      "cv01", -- alternate a
      "cv02", -- alternate g
      "cv03", -- slashed zero
    },
  },
  { family = "Noto Color Emoji" },
}
```

passt sehr gut zu go, rust, typescript und klar strukturiertem code.

---

## geometrisch / minimalistisch

### Iosevka (Custom Build empfohlen)

sehr flexibel, extrem konsistent, ideal wenn man typografie exakt steuern möchte.

```lua
-- Highly configurable geometric monospace
Config.font = wezterm.font_with_fallback {
  {
    family = "Iosevka",
    weight = "Regular",
    harfbuzz_features = {
      "cv01", -- alternate a
      "cv05", -- alternate g
      "cv08", -- i with serif
      "cv10", -- slashed zero
      "ss08", -- distinct equals/colon
    },
  },
  { family = "Noto Color Emoji" },
}
```

ideal für neovim power-user, besonders mit eigenem iosevka-build.

---

### Recursive Mono

variabler font, modern, leicht futuristisch, trotzdem gut lesbar.

```lua
-- Variable font with modern, slightly futuristic feel
Config.font = wezterm.font_with_fallback {
  {
    family = "Recursive Mono",
    weight = "Regular",
    harfbuzz_features = {
      "ss01", -- simplified shapes
      "ss02", -- alternate numerals
    },
  },
  { family = "Noto Color Emoji" },
}
```

gut für experimentelle setups oder dunkle farbschemata.

---

## klassisch / „unix-terminal“-ästhetik

### Source Code Pro

konservativ, stabil, extrem bewährt.

```lua
-- Classic, conservative programming font
Config.font = wezterm.font_with_fallback {
  {
    family = "Source Code Pro",
    weight = "Regular",
    harfbuzz_features = {
      "zero", -- slashed zero
    },
  },
  { family = "Noto Color Emoji" },
}
```

wenn man etwas möchte, das nie „im weg“ ist.

---

### Hack

robust, etwas breiter, sehr gut für terminals und tmux-lastige workspaces.

```lua
-- Wide, robust terminal-oriented font
Config.font = wezterm.font_with_fallback {
  {
    family = "Hack Nerd Font",
    weight = "Regular",
    harfbuzz_features = {
      "zero", -- slashed zero
    },
  },
  { family = "Noto Color Emoji" },
}
```

passt gut zu dichten layouts und statuslines.

---

## retro / low-level-ästhetik

### Fira Mono

weniger verspielt als Fira Code, klar und technisch.

```lua
-- Clean technical mono without heavy ligatures
Config.font = wezterm.font_with_fallback {
  {
    family = "Fira Mono",
    weight = "Regular",
    harfbuzz_features = {
      "cv01", -- alternate a
      "cv02", -- alternate g
    },
  },
  { family = "Noto Color Emoji" },
}
```

gut, wenn man ligaturen bewusst vermeiden möchte.

---

## empfehlung zur auswahl

| stil                   | empfohlener font |
| ---------------------- | ---------------- |
| modern & ruhig         | Inter Mono       |
| präzise & technisch    | IBM Plex Mono    |
| maximal konfigurierbar | Iosevka          |
| experimentell          | Recursive Mono   |
| klassisch              | Source Code Pro  |
| terminal-heavy         | Hack             |
| retro-technisch        | Fira Mono        |

---

wenn gewünscht, kann man auch:

* eine iosevka-build-konfiguration erzeugen (private build mit festen glyphen),
* eine fallback-kette für powerline + nerd-icons optimieren,
* oder font-features speziell für lua, typescript oder go abstimmen.

