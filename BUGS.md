# BUGS.md — known issues in this Neovim setup

Issues found while porting this config, with enough detail (minimal repro,
evidence, and current workaround) to file upstream or revisit later.

---

## 1. `guicursor` `t:` (terminal mode) is ignored — terminal buffers keep the NORMAL mode shape

**Status:** open upstream bug, reproducible with `nvim --clean`.
**Affects:** Neovim 0.12.4 / 0.12.6.
**Impact here:** the cursor in a `:terminal` buffer cannot be given a distinct
shape; it always uses the `n` (normal) entry's shape.

### Summary

`'guicursor'` documents a `t` mode-list entry for **Terminal mode**
(`:h 'guicursor'`). Setting `t:ver25` (a bar) has **no effect** in a terminal
buffer: Neovim keeps emitting the shape from the `n` entry and never requests
the bar.

### Minimal reproduction (`nvim --clean`, no plugins, no user config)

```vim
:set guicursor=n-v-c:block,i-ci:ver25,t:ver25
:terminal
```

**Expected:** inside the terminal buffer, Neovim emits a bar code
(`ESC[5 q` blinking bar or `ESC[6 q` steady bar).

**Actual:** Neovim emits only block codes. Captured by running Neovim inside a
pty (`script -qfec "nvim --clean ..."`) and scanning its raw output for
DECSCUSR sequences (`ESC[N q`):

```
DECSCUSR emitted: ['\x1b[1 q', '\x1b[2 q', '\x1b[2 q', '\x1b[2 q', '\x1b[0 q']
observed block(1/2): 4
observed bar(5/6):   0
```

For contrast, `i-ci:ver25` **does** work — insert mode correctly emits the bar.
Only the `t:` entry is ignored.

### Why the code *looks* correct

`src/nvim/cursor_shape.c`, `cursor_get_mode_idx()`, checks `MODE_TERMINAL`
**first**:

```c
int cursor_get_mode_idx(void)
{
  if (State == MODE_SHOWMATCH) {
    return SHAPE_IDX_SM;
  } else if (State == MODE_TERMINAL) {   /* <-- t: should win here */
    return SHAPE_IDX_TERM;
  } else if (State & VREPLACE_FLAG) {
  ...
```

So the intent is for `t:` to take precedence. In practice the terminal buffer
resolves to `SHAPE_IDX_N`, i.e. it behaves as if `MODE_TERMINAL` were not set.

Note also `src/nvim/cursor_shape.c`'s `shape_table[]` entry for terminal has all
blink timings zeroed, unlike every other entry:

```c
{ "terminal", 0, 0, 0, 0, 0, 0, 0, 0, "t", SHAPE_CURSOR },
```

### Possibly related mechanism

`src/nvim/terminal.c` reads the terminal shape **once, at terminal-job
creation**, and pushes it into libvterm as a property:

```c
switch (shape_table[SHAPE_IDX_TERM].shape) {
case SHAPE_BLOCK: cursor_shape.number = VTERM_PROP_CURSORSHAPE_BLOCK; break;
case SHAPE_HOR:   cursor_shape.number = VTERM_PROP_CURSORSHAPE_UNDERLINE; break;
case SHAPE_VER:   cursor_shape.number = VTERM_PROP_CURSORSHAPE_BAR_LEFT; break;
}
vterm_state_set_termprop(state, VTERM_PROP_CURSORSHAPE, &cursor_shape);
```

If this runs before `'guicursor'` is applied, or if libvterm's later cursor
updates take precedence over the TUI's `SHAPE_IDX_N` handling, the `t:` value
would be discarded — consistent with what we observe.

### Secondary symptom: the TUI re-asserts its shape constantly

Even if the correct shape *is* sent manually, Neovim overrides it on the next
redraw. Sending `ESC[6 q` via `nvim_ui_send()` and capturing the pty output
shows our sequence immediately followed by Neovim's own block sequence:

```
ESC]12;#d3d3d3  ESC[5 q     <- ours (bar)
ESC]12;#d3d3d3  ESC[5 q     <- ours
ESC[?25l  ESC[1 q           <- nvim redraw: overrides with block
```

Over a full session: our bar was sent 4 times, Neovim's block 10 times.

`set t_Ss= t_Se=` (blanking the terminfo cursor-shape capabilities) does **not**
suppress this in 0.12 — Neovim's TUI manages the cursor shape internally rather
than exclusively through those capabilities, so there is no supported way to opt
the TUI out of shape management.

### Not a terminal-emulator problem (verified)

The terminal in use (Ghostty) handles DECSCUSR correctly. Running this in a
plain shell, outside Neovim, cycles the cursor shape as expected:

```bash
printf '\033[6 q'; sleep 3; printf '\033[4 q'; sleep 3; printf '\033[0 q'
```

So the fault is on the Neovim side, not the emulator's.

### Workaround in this config (current design)

**Neovim no longer drives the cursor shape at all.** `'guicursor'` is set to the
empty string in `lua/config/options.lua`:

```lua
vim.opt.guicursor = ""
```

With that, Neovim emits **no** DECSCUSR sequences, so there is nothing to be
overridden and nothing to race. `config/cursor.lua` is then the sole writer of
both cursor dimensions, via `vim.api.nvim_ui_send()`:

| mode | colour (OSC 12) | shape (DECSCUSR) |
|---|---|---|
| normal / visual | `#ff4400` / `#1bfd9c` | `ESC[2 q` steady block |
| insert / replace / terminal | `#d3d3d3` | `ESC[6 q` steady bar |

Because `t:` is never exercised, this bug is **bypassed rather than fixed** —
terminal-mode shape works here purely because Neovim is not consulted.

**Historical note:** before the empty `'guicursor'`, this config tried two
approaches that both lost the race against Neovim's own shape emission —
omitting `t:` (Neovim fell back to the `n` entry) and re-sending DECSCUSR on a
timer (needed ~8 writes/second to stay ahead, since Neovim re-emits on every
redraw). Both were removed.

**Upstream status:** still relevant if Neovim is ever asked to manage shapes
again. A fix to `cursor_get_mode_idx()` / the libvterm property push would make
`t:` work natively and remove the need for `cursor.lua`'s DECSCUSR writing.

### Reproduce the pty capture yourself

```bash
script -qfec "nvim --clean -c 'set guicursor=n-v-c:block,i-ci:ver25,t:ver25' \
  -c 'lua vim.defer_fn(function() vim.cmd(\"terminal\")
      vim.defer_fn(function() vim.cmd(\"qa!\") end,2000) end,800)'" /dev/null \
  > /tmp/repro.bin 2>&1
sleep 5
python3 -c "import re;d=open('/tmp/repro.bin','rb').read();\
print(re.findall(rb'\x1b\[\d q', d))"
```

---

## 2. Visible cursor / text flicker under Ghostty (unresolved — suspected Ghostty side)

**Status:** open, **not yet filed upstream**. Suspected to be a Ghostty issue.
**Affects:** Ghostty 1.4.0 under Hyprland.

### Symptom

The text under the cursor appears to blink/flicker. Observed **outside Neovim**
too — in a plain shell inside a Ghostty window — which is what points at Ghostty
rather than Neovim.

### Ruled out

Each of these was tested and did **not** stop the flicker:

| Ruled out | Evidence |
|---|---|
| Neovim `guicursor` blink specs | `'guicursor'` is `""`; Neovim emits no shape/blink escapes |
| Neovim DEC mode 12 (`CSI ? 12 h/l`) | pty capture: mode-12 never sent |
| Neovim blinking DECSCUSR codes | pty capture: only steady `ESC[2 q` / `ESC[6 q` |
| `cursor-style-blink = false` | present and loaded (`ghostty +show-config` confirms) |
| `cursor-opacity = 0.0` | changed to 1.0, still flickers |
| `cursor-text` colour | changed repeatedly, still flickers |
| `custom-shader = cursor_blaze.glsl` | commented out, still flickers |
| Shell integration injecting blink | `GHOSTTY_SHELL_FEATURES=path,title` — no `cursor`; `shell-integration-features = no-cursor` is set |
| Config not being loaded | `ghostty +show-config` matches the file |

### Relevant Ghostty behaviour (from its source)

`src/terminal/Terminal.zig`, `setCursorStyle()`:

```zig
self.cursor.is_default = value == .default;
self.modes.set(.cursor_blinking, switch (value) {
    .default => self.cursor.default_blink orelse true,
    ...
```

Two consequences:

1. Any **explicit** DECSCUSR from a program sets `is_default = false`, after
   which `cursor-style-blink` is deliberately **ignored** until the program
   sends `ESC[0 q`. Ghostty's shell integration sends `ESC[5 q` at prompts,
   which is the mechanism behind ghostty-org/ghostty#2812 / #10643.
2. `ESC[0 q` resolves blink to `default_blink orelse true` — i.e. **true** when
   `default_blink` is unset.

Ghostty's blink timer is also a **compile-time constant**, with no config
option (`src/renderer/Thread.zig`):

```zig
const CURSOR_BLINK_INTERVAL = 600;   // hardcoded
```

### Next step

File upstream against ghostty-org/ghostty with the table above, noting that the
flicker reproduces in a plain shell with shell-integration cursor features
disabled and no custom shader.
