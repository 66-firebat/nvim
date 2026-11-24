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

### Workaround in this config

Terminal-mode cursor **shape** is currently accepted as a block. Terminal-mode
cursor **colour** works, because colour is sent by this config as an OSC 12
escape (`config/cursor.lua`) and Neovim never emits OSC 12 itself, so there is
no conflict.

`t:` is deliberately omitted from `'guicursor'` in `lua/config/options.lua` —
including it would have Neovim emit a shape that is immediately overridden
anyway, and omitting it avoids a misleading "this is configured" appearance.

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
