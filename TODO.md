# TODO.md — pending work on this Neovim config

Ordered roughly by payoff. Each item lists the concrete steps so it can be
picked up cold.

---

## 1. Set up the AI CLI terminal

**Goal:** run AI coding CLIs (`claude`, `aider`, `opencode`, `pi`, …) inside
Neovim in a scratch terminal, with the current file/selection/diagnostics
forwarded as context.

### Recommended route: `folke/sidekick.nvim`

By the author of `lazy.nvim` / `snacks.nvim`. It is **two independent halves**:

| Half | Needs | Status here |
|---|---|---|
| **NES** (inline edit suggestions w/ diff review) | `copilot-language-server` via `vim.lsp.enable` + a `lsp/copilot.lua` | ❌ **missing** — see below |
| **CLI terminal** (the goal of this item) | only the CLI binary itself | ✅ nothing needed |

The **CLI half needs no API key of its own** — sidekick just spawns the CLI
(`cmd = { "aider" }`) and forwards context. Auth is entirely the CLI's job
(env var or its own config), so **any provider the CLI supports works**,
including DeepSeek.

### Steps

1. **Add the plugin spec** (`lua/plugins/sidekick.lua`):

   ```lua
   return {
     "folke/sidekick.nvim",
     opts = {
       cli = {
         tools = {
           -- Pin a model so we don't have to pass it every time.
           aider = { args = { "--model", "deepseek/deepseek-chat" } },
         },
       },
     },
     keys = {
       { "<leader>aa", function() require("sidekick.cli").toggle() end, desc = "AI CLI toggle" },
       { "<leader>as", function() require("sidekick.cli").send({ msg = "{this}" }) end, mode = { "n", "x" }, desc = "AI send selection" },
       { "<leader>af", function() require("sidekick.cli").send({ msg = "{file}" }) end, desc = "AI send file" },
     },
   }
   ```

2. **Install at least one CLI.** None are currently on `PATH` (`aider` is not
   installed). Pick one:

   - **aider** — native DeepSeek support: `pipx install aider-chat`
     then `export DEEPSEEK_API_KEY=...`
   - **opencode** — also in sidekick's tool list, supports custom
     OpenAI-compatible base URLs
   - **pi** — already in use in this environment; sidekick supports it
     (added in sidekick v2.2.0)

   Add the chosen package to `home/shared.nix` rather than installing ad hoc.

3. **Verify** — `:Sidekick` picks the tool; open it, confirm it receives
   context, confirm `cli.watch = true` reloads files it edits.

### Optional: enable NES (the Copilot half)

Only if a GitHub Copilot subscription is available — it **cannot** use a
DeepSeek key (the LSP server is Copilot-only).

1. Add `lsp/copilot.lua` (currently **absent** — that's the blocker):

   ```lua
   -- lsp/copilot.lua
   return {
     cmd = { "copilot-language-server", "--stdio" },
     root_markers = { ".git" },
     filetypes = { "*" },
     init_options = { editorInfo = { name = "Neovim" } },
   }
   ```

   `copilot.lua` bundles the server, so no separate npm install is needed.

2. Enable it: `vim.lsp.enable("copilot")` (or via `nvim-lspconfig`).

3. Note this **overlaps `blink-cmp-copilot`** in `lua/plugins/blink-cmp.lua`
   (inline ghost text). Decide whether NES replaces that source or coexists.

### Notes

- `lua/plugins/aider.lua.bak` is a **different** plugin (`nvim-aider` by
  GeorgesAlkhouri). If sidekick is adopted, that `.bak` can stay retired —
  sidekick's CLI half supersedes it.
- `pi` in sidekick's tool list matches the `pi` coding agent already used in
  this environment (see terminal-resize commits).

---

## 2. Set up nabla more carefully

**Current state:** `lua/plugins/nabla.lua` is a minimal lazy spec — `<leader>J`
in normal/visual mode calls `require("nabla").popup()`. It works, but it is
bolted on without thought about how it relates to `mdmath`, treesitter, or
filetypes.

### Why revisit it

1. **Two math renderers overlap.** `mdmath.nvim` (automatic, inline images, all
   markdown/tex/julia) and `nabla` (on-demand popup) do the same job two ways.
   Right now they just coexist.
2. **`latex` is installed but NOT in the treesitter `languages` list**
   (`lua/plugins/nvim-treesitter.lua`). `.tex` files therefore get **no
   treesitter highlighting**, even though navla needs the parser and vimtex
   reports *"Syntax highlighting is controlled by Treesitter!"*. This is a real
   gap, not cosmetic.
3. **nabla's parser requirement is silent.** `lua/nabla/utils.lua` calls
   `vim.treesitter.get_parser(buf, "latex")` and only `nvim_echo`s a hint when
   it fails — easy to misread as a plugin bug.

### Suggested work

**a. Fix the treesitter gap first (highest value, 1 line).**

Add `"latex"` to the `languages` list in `lua/plugins/nvim-treesitter.lua`:

```lua
local languages = { "bash", "c", "cpp", "fish", "html", "java", "javascript",
  "latex", "lua", "markdown", "markdown_inline", "python", "sql",
  "vimscript", "vimdoc" }
```

Also audit that list. Installed parsers are:

```
user   (~/.local/share/nvim/site/parser/): bash html javascript latex nix yaml
bundled (nvim lib dir):                    c lua markdown markdown_inline query vim vimdoc
```

So from the current `languages` list, **`cpp`, `fish`, `java`, `python`, `sql`,
`vimscript` have no parser** (6 entries silently no-op via `vim.treesitter.start()`),
while **`latex` and `nix` have parsers but are missing from the list**. Either
`:TSInstall` the missing ones or trim the list to match reality.

**b. Decide the division of labour between mdmath and nabla.**

Two sensible splits:

- **Keep both, divide by intent:** mdmath for *reading* markdown documents
  (always-on inline rendering), nabla for *writing* (`<leader>J` to peek without
  leaving the flow). Costs nothing, no config changes.
- **Keep only nabla:** rename `mdmath.lua` → `.bak`. Lighter, no image backend,
  no `dynamic_scale` tuning to worry about.

**c. Equation sizing (if keeping mdmath).**

`lua/plugins/mdmath.lua` currently has `dynamic_scale = 1.0` (the default) and
`internal_scale = 1.0`:

```lua
dynamic_scale = 1.0,   -- DISPLAYED size multiplier (was 3.0 at one point)
internal_scale = 1.0,  -- PIXEL resolution only — does NOT change display size
```

Lower `dynamic_scale` (e.g. `0.8`) if display (`$$...$$`) equations still feel
too large; `internal_scale` is the wrong knob for size and will only add blur.

**Caveat:** mdmath has an upstream `// FIXME: Invalidate cache when scale
changes` (`mdmath-js/src/processor.js:165`), so after changing `dynamic_scale`
you may still see old images. Clear the cache or `:MdMath toggle` off/on.

**d. Make the keybind discoverable.**

Add `which-key` grouping for `<leader>J` (currently `desc = "Nabla popup"` only),
or consider moving it under a `<leader>m` math group alongside an mdmath toggle
(`:MdMath toggle`), so both renderers are reachable from one place.

**e. Optional: filetype-gate nabla.**

nabla works anywhere treesitter injects `latex`, but it is only useful in
`.tex` / `.md` / `.julia`. If `<leader>J` fires in unrelated buffers it just
prints the parser message. Consider a `cond` on the keymap:

```lua
cond = function()
  return vim.tbl_contains({ "tex", "markdown", "julia", "asciidoc", "rmd", "qmd" }, vim.bo.filetype)
end,
```

---

## 3. Patch nabla core for robust inline (`toggle_virt`) rendering

**Why:** `toggle_virt()` is disabled for now (tried, then removed in
`lua/plugins/nabla.lua`) because on a large generated document
(`principles_of_model_checking.md`) it (a) spewed raw parse errors and (b)
rendered nothing — the loop aborts on the first bad formula. The popup
(`<leader>J`) stays as the only binding until the core is hardened.

**Root causes (confirmed in vendored source `~/.local/share/nvim/lazy/nabla.nvim`):**

1. `enable_virt()` iterates **every** math node in the buffer and runs each
   through the hand-rolled parser (`nabla/latex.lua`) + ASCII generator
   (`nabla/ascii.lua`) **serially**. One unsupported formula aborts the whole
   render via `return 0`. No per-formula isolation.
2. `latex.lua:327` `string.len(sym_str)` crashes when `parse_symbol()`'s
   `string.match(rest, "^%a+")` returns nil (i.e. the token starts with a
   non-letter). Any numeral/brace-led construct triggers it.
3. `ascii.lua:1867` `assert(..., "No matching closing bracket")` throws on an
   unmatched `}`. Throwing (not returning) breaks the `pcall` at the call site
   `nabla.lua:334` — wait, that one IS wrapped; the real leak is the
   unconditional `print(g)` + `return 0` at `nabla.lua:335-336` on `ascii.to_ascii`
   failure, which ignores the `silent` flag.
4. `silent` only gates the `print(exp)` in the `parser.parse_all` failure branch
   (`nabla.lua:560-563`). It does NOT suppress the `ascii.to_ascii` `print(g)`
   path, nor any `assert`/`#len` thrown inside the parse graph.
5. `whitespace` is referenced in three places (`gen_drawing`, `popup`,
   `enable_virt`) but NEVER defined — a dead `nil` global from the ntangle-
   generated source. Those `if whitespace` branches are no-ops. Harmless but
   confusing during any patch.

**Proposed core patch (ordered by payoff / risk):**

**a. Guard every formula, never let one abort the batch (highest value).**
In `enable_virt()`'s per-location loop (`nabla.lua:322` onward), change the
`ascii.to_ascii` failure branch from `print(g); return 0` to an isolated
`goto continue`-style skip (or wrap the whole body in a `pcall` per formula and
`continue` on error). Also wrap `parser.parse_all(line)` **and**
`ascii.to_ascii(...)` together so neither a parse throw nor a gen throw skips
the remaining formulas. This alone turns "renders nothing" into "renders all
formulas it can, skips the broken ones".

**b. Make `silent` actually silent.** Route ALL error surfacing through one
helper that checks `opts.silent` (the `print(g)` at line 335, the `print(exp)`
at line 563, and the `vim.api.nvim_echo` "Empty expression" at line 342).
Today the flag is half-wired.

**c. Harden `parse_symbol()` in `latex.lua`.** Return a fallback / nil-safe
symbol instead of `string.len(nil)`. Minimal change:

```lua
local sym_str = string.match(rest, "^%a+")
if not sym_str then
  -- fall back to a single-char literal rather than crashing
  sym_str = string.sub(rest, 1, 1) or "?"
end
ptr = ptr + string.len(sym_str)
```

Also consider a wrapper `parse_all` that returns `nil, errmsg` on the first
malformed token instead of letting `#len`/`assert` escape.

**d. Replace `assert(..., "No matching closing bracket")` with a returned error.**
Have `to_ascii` (or its caller) return `nil, "unmatched }"` and propagate it up
as a parse failure instead of a hard `assert`, so (a)'s per-formula `pcall` can
catch it clean.

**e. Define or delete `whitespace`.** If indentation of the ASCII art is ever
desired, declare `local whitespace = ""` (or make it an option on
`enable_virt`/`popup`); otherwise delete the three dead `if whitespace` blocks
to reduce confusion for future patches.

**f. (stretch) Add a `max_formulas` guard.** On huge files, even isolated
per-formula rendering is O(n) and slow; optionally bound the number of formulas
rendered per `enable_virt` call (e.g. render only the visible window via the
existing `opts.render_visible` plumbing in `utils.get_all_mathzones`).

**Where to apply the patch:** the plugin is installed at
`~/.local/share/nvim/lazy/nabla.nvim` (managed by lazy.nvim). Editing vendored
source is overwritten on plugin update, so the durable route is either (1) fork
jbyuki/nabla.nvim and point the lazy spec at the fork, or (2) patch via a
`config` function that monkey-patches `require("nabla")` post-load — though the
functions are local and not exposed, so (2) only works for the exported module
surface (`popup`, `enable_virt`, `disable_virt`, `toggle_virt`, `is_virt_enabled`,
`gen_drawing`). A real fix means a fork (1).

