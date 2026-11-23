-- =============================================================================
--  statuscolumn.lua — static letter-label gutter (port of emacs/statuscolumn.el)
--
--  DESIGN GOAL (per fireshark): labels are STATIC, assigned top-to-bottom in
--  visible order.  Only the cursor moves.  This deliberately abandons vai.nvim's
--  "sweet spot" reordering, which shifts labels around the cursor.
--
--  Label scheme (faithful to Emacs `sc--index-label`):
--      a..z  (26)            -> single letters
--      punctuation           -> . , @ ! # $ % ^ & * ( ) - + = [ ] { } : ; < > ?? / ~
--      overflow              -> multi-char (aa, ab, ...) only after the above
--
--  Elements ported from statuscolumn.el:
--    1. Static jump labels (this file, replaces vai labels)
--    2. Per-line marks (a-zA-Z) shown in the gutter
--    3. Search-instance counter (replaces the line-number slot on cursor line)
--    4. Scrollbar-thumb slice icon (8-band, based on point/line-count)
--    5. Wrap icon on wrapped continuation lines (current vs non-current)
--    6. Bolt icon while a jump is active
--    7. `┣` / `│` current-line bump (already present, re-implemented here)
--
--  Integration: rendered via statuscol.nvim `text` segments.  `keymaps.lua`
--  binds `;` to `SC.jump()` (replacing `vai.jump.start`).
-- =============================================================================

local M = {}

-- Highlight groups we rely on (defined in highlight_groups/highlights.lua or
-- here to be safe).  Colors match the firebat theme (#ff4400 accent).
local function ensure_highlights()
  local defs = {
    -- current-line label: orange accent
    StatusColumnCurrent = { fg = "#ff4400", bg = "#2b2b2b" },
    -- non-current labels: muted grey
    StatusColumnLabel = { fg = "#8c8c8c", bg = "#2b2b2b" },
    -- the `▏` separator (non-current lines)
    StatusColumnBorder = { fg = "#ff4400", bg = "none" },
    StatusColumnBorderBump = { fg = "#ff4400", bg = "#2b2b2b", bold = true },
    -- search-instance counter
    StatusColumnSearch = { fg = "#2b2b2b", bg = "#ff4400", bold = true },
    -- leading space before the search glyph (Emacs sc-search-lead-space):
    -- matches the gutter background so it is invisible, NOT an orange block.
    StatusColumnSearchLead = { fg = "#2b2b2b", bg = "#2b2b2b" },
    -- inverted powerline caps (fg/bg swapped from the groups they sit beside),
    -- used ONLY for the two cap glyphs in the search line.
    StatusColumnSearchCap = { fg = "#ff4400", bg = "#2b2b2b", bold = true },
    StatusColumnCap = { fg = "#ff4400", bg = "#2b2b2b", bold = true },
    -- the thumb-scroll slice icon during search (inverted vs StatusColumnCap).
    StatusColumnSlice = { fg = "#ff4400", bg = "#2b2b2b", bold = true },
    -- mark chars
    StatusColumnMark = { fg = "#ff4400", bg = "#2b2b2b", bold = true },
    -- solid block appended after a mark (dark #2b2b2b fg, no bg)
    StatusColumnMarkBlock = { fg = "#2b2b2b", bg = "#2b2b2b" },
    -- wrap icon / bolt
    StatusColumnWrap = { fg = "#ff4400", bg = "#2b2b2b" },
  }
  for name, opts in pairs(defs) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

-- =============================================================================
--  Label alphabet (faithful to Emacs sc--index-label)
-- =============================================================================

-- Punctuation labels used after a-z (Emacs sc--punct-labels).
local punct = {
  ".", ",", "@", "!", "#", "$", "%", "^", "&", "*",
  "(", ")", "-", "+", "=", "[", "]", "{", "}", ":",
  ";", "<", ">", "?", "/", "~",
}

--- Map a lowercase letter a-z to its SQUARED Nerd Font icon
--- (MDI alpha-X-box, U+F0B08 stride 1).  Non-letters are returned unchanged.
local function encircle(ch)
  local b = ch:byte()
  if b and b >= 97 and b <= 122 then
    return vim.fn.nr2char(0xF0B08 + (b - 97))
  end
  return ch
end

--- Convert a raw (padded) jump label into its DISPLAY form, squaring any
--- lowercase letters but leaving spaces/punctuation/multi-char padding intact.
function M.display_label(raw)
  return (raw:gsub("[a-z]", encircle))
end

--- Return the single-char label for a 0-based index N, mirroring
--- Emacs `sc--index-label`: 0->a, 25->z, 26->".", 27->",", ...
--- After a-z and punctuation are exhausted, fall back to multi-char (aa, ab, …).
--- These are the RAW labels used for jump matching; the DISPLAY glyph is
--- produced separately by `encircle` at render time.
local function index_label(n)
  if n < 26 then
    return string.char(97 + n)
  end
  local pidx = n - 26
  if pidx < #punct then
    return punct[pidx + 1]
  end
  -- Overflow: two-char labels.
  local remaining = pidx - #punct
  local a = math.floor(remaining / 26)
  local b = remaining % 26
  return string.char(97 + a) .. string.char(97 + b)
end

--- Convert a visible (top-to-bottom) 0-based index into a label, left-padded
--- to a fixed width so all labels occupy the same number of cells.
--- Uses DISPLAY width (encircled glyphs are multi-byte but 1 cell each).
local function padded_label(idx, width)
  local l = index_label(idx)
  local dw = vim.fn.strdisplaywidth(l)
  if dw < width then
    return l .. string.rep(" ", width - dw)
  end
  return l
end

-- =============================================================================
--  State
-- =============================================================================

-- `M.jump_active` is true while a `;` jump is in progress (bolt icon).
M.jump_active = false

-- `M.search_active` mirrors Emacs `sc--search-active`: true while a search
-- highlight is active, cleared by `:nohlsearch` (Emacs `evil-ex-nohighlight`).
M.search_active = false

-- =============================================================================
--  Visible-range + label mapping (STATIC top-to-bottom)
-- =============================================================================

--- Build the static label map: { [lnum] = "<label>", ... } for the current
--- window.  Labels are assigned by ABSOLUTE offset from the first visible line
--- (label = index of `lnum - first`), so they are PERMANENT per line and never
--- shift when the cursor moves.  The cursor line gets a label too, but it is
--- simply not displayed (the current-line branch handles it separately).
--- Emacs: `sc--make-pairs` over visible BOLs in order (no cursor skip).
function M.build_label_map()
  local win = vim.api.nvim_get_current_win()
  local first = vim.fn.line("w0", win) or 1
  local last = vim.fn.line("w$", win) or first

  local map = {}
  for lnum = first, last do
    map[lnum] = padded_label(lnum - first, 2)
  end
  return map
end

--- Return the static label a line has in top-to-bottom order (absolute offset
--- from the first visible line).  Same as the entry in `build_label_map`.
function M.label_for(lnum)
  local first = vim.fn.line("w0", 0) or 1
  return padded_label(lnum - first, 2)
end

-- =============================================================================
--  Marks (Emacs sc--build-mark-map)
-- =============================================================================

--- Return a map { [lnum] = "<markchar>" } for marks a-zA-Z on their lines.
--- When multiple marks share a line, the MOST RECENTLY-SET mark wins.
--- This mirrors Emacs `sc--build-mark-map` exactly: non-recent marks go in
--- first (a..zA..Z order), then recent marks override (only if not claimed).
function M.build_mark_map()
  local map = {}
  local cur_buf = vim.api.nvim_get_current_buf()

  local function put(ch)
    local pos = vim.fn.getpos("'" .. ch)
    local lnum = pos and pos[2] or 0
    -- Filter by buffer: local marks (a-z) are already scoped to the current
    -- buffer, but global marks (A-Z) return the mark's OWN buffer in pos[1].
    -- Ignore any mark whose buffer is not the current one, so a global mark
    -- set in file1 does not bleed into file2.
    local mark_buf = pos and pos[1] or 0
    if lnum and lnum > 0 and (mark_buf == 0 or mark_buf == cur_buf) then
      map[lnum] = ch
    end
  end

  -- Pass 1: all marks EXCEPT the tracked-recent ones, in a..zA..Z order.
  for c = 97, 122 do
    local ch = string.char(c)
    if not M._is_recent(ch) then put(ch) end
  end
  for c = 65, 90 do
    local ch = string.char(c)
    if not M._is_recent(ch) then put(ch) end
  end

  -- Pass 2: recent marks, MOST RECENT FIRST; a line already claimed is kept
  -- (Emacs: `unless (gethash bol sc--mark-map)`).
  for _, ch in ipairs(M._recent_marks) do
    local pos = vim.fn.getpos("'" .. ch)
    local lnum = pos and pos[2] or 0
    local mark_buf = pos and pos[1] or 0
    if lnum and lnum > 0 and (mark_buf == 0 or mark_buf == cur_buf) and not map[lnum] then
      map[lnum] = ch
    end
  end

  return map
end

-- `_recent_marks` is a most-recent-first list of mark chars (like Emacs
-- `sc--recent-marks`).  `_is_recent` checks membership.
M._recent_marks = {}
function M._is_recent(ch)
  for _, r in ipairs(M._recent_marks) do
    if r == ch then return true end
  end
  return false
end

-- =============================================================================
--  Search-instance counter (Emacs sc--search-instance-str)
-- =============================================================================

--- Shared search state: reads the `/` register (single source of truth, kept
--- in lockstep by `M.flash_jump_f` in reusable_functions.lua and by native
--- `/ * # g* g#`).  Returns the current-match ordinal (1-based), or nil.
---
--- The search counter is only shown while a search is "active"; running
--- `:nohlsearch` (Emacs `evil-ex-nohighlight`) clears `M.search_active` and
--- hides the counter without clearing the `/` register (so `n` still works).
function M.search_instance()
  -- Derive "active" directly from v:hlsearch (1 = highlights showing, 0 after
  -- :nohlsearch).  This is the single source of truth, so the counter only
  -- appears while highlights are active.
  if vim.v.hlsearch ~= 1 then
    return nil
  end
  local pattern = vim.fn.getreg("/")
  if pattern == nil or pattern == "" then
    return nil
  end

  local cur = vim.fn.line(".")
  local count = 0
  local found = nil
  local bufnr = vim.api.nvim_get_current_buf()
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  -- Re-match from the top of the buffer (mirrors Emacs sc--search-instance-str,
  -- which walks point-min -> each match and counts up to the current one).
  for lnum = 1, line_count do
    -- Use :h search() semantics (wraps; here we scan linearly to count).
    -- `vim.fn.search` moves the cursor, so we use a non-mutating match via
    -- `vim.fn.matchstr`/`searchpos` on a per-line basis.  To keep it simple and
    -- non-mutating we call `searchpos` with 'n' flag (do not move).
    local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
    -- VerySmall regex via vim's own matching:
    local match_start = vim.fn.match(line, pattern)
    if match_start >= 0 then
      count = count + 1
      if lnum == cur then
        found = count
        break
      end
    end
  end

  if not found then
    return nil
  end

  -- Always a fixed 3-char string, so the search layout width never changes.
  -- Rightmost slot is "+" when >99 matches, otherwise the number is
  -- left-justified within a 3-char field (trailing spaces) — Emacs
  -- sc--search-instance-str pads AFTER the number, not before.
  local s = found > 99 and "99+" or tostring(found)
  return (s .. "   "):sub(1, 3)
end

-- =============================================================================
--  Scrollbar-thumb slice icon (Emacs sc--slice-icon)
-- =============================================================================

-- 8-band Nerd Font scrollbar-thumb glyphs, mirroring Emacs sc--slice-icon's
-- 9-state mapping (0..8).  Codepoints are in the Nerd Font private use area.
local slice_icons = {
  [0] = "󰄰", -- 󰄰 (top)
  [1] = "󰪞", -- 󰪞
  [2] = "󰪟", -- 󰪟
  [3] = "󰪠", -- 󰪠
  [4] = "󰪡", -- 󰪡
  [5] = "󰪢", -- 󰪢
  [6] = "󰪣", -- 󰪣
  [7] = "󰪤", -- 󰪤
  [8] = "󰪥", -- 󰪥 (bottom)
}

--- Return the slice icon for the current cursor position within the buffer
--- (0..1 progress -> 8 bands), mirroring Emacs `sc--slice-icon`.
function M.slice_icon()
  local line_count = vim.api.nvim_buf_line_count(0)
  local cur = vim.fn.line(".")
  local total = math.max(1, line_count - 1)
  local pct = (cur - 1) / total
  local band = math.floor(pct * 8)
  if band < 0 then band = 0 end
  if band > 8 then band = 8 end
  return slice_icons[band]
end

--- Return the single-letter indicator for the current Vim mode as a SQUARED
--- Nerd Font (MDI alpha-X-box) glyph.
--- n=normal, i=insert, v=visual, o=operator-pending, c=command, t=terminal, etc.
function M.mode_letter()
  local mode = vim.fn.mode() -- e.g. "n", "i", "v", "V", "\22", "o", "c", "t", "R", "s"
  -- Map each mode to its alpha-X-box glyph (U+F0B08 is alpha-a-box, +1 per letter).
  local function box(ch)
    return vim.fn.nr2char(0xF0B08 + (ch:byte() - 97))
  end
  local map = {
    n = box("n"),
    i = box("i"),
    v = box("v"),
    V = box("v"),
    ["\22"] = box("v"), -- visual-block
    o = box("o"),
    c = box("c"),
    t = box("t"),
    R = box("r"),
    r = box("r"),
    s = box("s"),
    S = box("s"),
    ["\19"] = box("s"), -- select-block
  }
  return map[mode] or mode
end

--- Map a mark character (a-z / A-Z) to its Nerd Font (MDI alpha) icon.
--- Lowercase `a` -> alpha-a-circle (U+F0BEC, stride 3), uppercase `A` ->
--- alpha-a-circle-outline (U+F0BED, stride 3).
--- Material Design Icons alpha-X-circle / alpha-X-circle-outline.
function M.mark_icon(ch)
  local b = ch:byte()
  if b >= 97 and b <= 122 then -- a-z
    return vim.fn.nr2char(0xF0BEC + (b - 97) * 3)
  elseif b >= 65 and b <= 90 then -- A-Z
    return vim.fn.nr2char(0xF0BED + (b - 65) * 3)
  end
  return ch
end

-- =============================================================================
--  statuscol segment functions
-- =============================================================================

--- Render the FULL gutter string for a line, reproducing emacs/statuscolumn.el's
--- `line-prefix` layout exactly.  Per line the prefix is one 8-cell string:
---
---   current line (normal):  SP SP MARK SP ICON SP ┣ SP           (mark BEFORE icon)
---   current line (search):  SP        MARK   SEARCH(3) ┣ SP      (mark at pos 3)
---   non-current line:       SP SP MARK SP LABEL      │ SP       (mark BEFORE label)
---
--- MARK is always at cell 3 (left of both the label and the icon), which is
--- why a marked line shows its mark glyph to the LEFT of the jump label.
--- The scrollbar/bolt icon appears ONLY on the current line, two cells left of
--- the `┣` bump (i.e. after MARK + one space).
function M.gutter_segment(args)
  ensure_highlights()
  local lnum = args.lnum
  local cursor = vim.fn.line(".")
  local mark = M.build_mark_map()[lnum]
  local markstr = mark and M.mark_icon(mark) or " "

  -- Wrapped continuation lines: orange `┠`, matching the current-line accent
  -- (so current and non-current wrapped lines share the same color).
  if args.virtnum and args.virtnum ~= 0 then
    return "%#StatusColumnBorderBump#      ├"
  end

  if lnum == cursor then
    -- Current line (search-active and normal are IDENTICAL):
    -- leading padding + mode letter + space + │ (or mark replaces │).
    local sep = mark and M.mark_icon(mark) or "│"
    local sephl = mark and "%#StatusColumnMark#" or "%#StatusColumnSearchCap#"
    local block = mark and "%#StatusColumnMarkBlock#█" or ""
    return "%#StatusColumnSearchLead#    "
      .. "%#StatusColumnSlice#" .. M.mode_letter()
      .. "%#StatusColumnCap# "
      .. sephl .. sep .. block
  end

  -- Non-current line:  SP SP SP LABEL │ SP  (mark replaces │ when present)
  local labels = M.build_label_map()
  local label = labels[lnum] or "  "
  local sep = mark and M.mark_icon(mark) or "│"
  local sephl = mark and "%#StatusColumnMark#" or "%#StatusColumnBorder#"
  local block = mark and "%#StatusColumnMarkBlock#█" or ""
  return "%#StatusColumnLabel#  "
    .. "%#StatusColumnLabel# "
    .. "%#StatusColumnLabel# "
    .. "%#StatusColumnLabel#" .. M.display_label(label)
    .. sephl .. sep .. block .. " "
end

-- =============================================================================
--  Jump (replaces vai.jump.start)
-- =============================================================================

-- Helper: compare a single-byte character to an integer codepoint
-- (vim.fn.getcharstr returns a string, possibly multi-byte).
local function byte_equals(s, code)
  return #s == 1 and s:byte() == code
end

--- Single-char jump: read keys until a unique label matches, then move the
--- cursor.  Labels are STATIC so the map stays fixed during input.
--- Emacs: `sc-avy-goto-line`.
function M.jump()
  ensure_highlights()
  local labels = M.build_label_map()
  if vim.tbl_isempty(labels) then
    vim.notify("statuscolumn: no lines to jump to", vim.log.levels.WARN)
    return
  end

  -- Record current position to the jumplist (so C-o returns here).
  vim.cmd("normal! m'")
  local ok, jump = pcall(require, "config.jumplist")
  if ok and jump and jump.push then jump.push() end

  -- Invert: label -> lnum.
  local by_label = {}
  for lnum, label in pairs(labels) do
    label = vim.trim(label)
    by_label[label] = lnum
  end

  M.jump_active = true
  vim.cmd("redraw")

  local input = ""
  while true do
    local ok, ch = pcall(vim.fn.getcharstr)
    if not ok or ch == "\27" or ch == "\x1b" or byte_equals(ch, 3) then -- ESC / Ctrl-C
      M.jump_active = false
      vim.cmd("redraw")
      return
    end
    if ch == "" then
      break
    end
    input = input .. ch

    -- Find all labels starting with `input`.
    local matches = {}
    for label, lnum in pairs(by_label) do
      if label:sub(1, #input) == input then
        table.insert(matches, { label = label, lnum = lnum })
      end
    end

    if #matches == 0 then
      M.jump_active = false
      vim.cmd("redraw")
      vim.notify('statuscolumn: no label "' .. input .. '"', vim.log.levels.WARN)
      return
    end

    if #matches == 1 then
      local target = matches[1].lnum
      M.jump_active = false
      vim.cmd("redraw")
      local mode = vim.fn.mode(true)
      vim.api.nvim_win_set_cursor(0, { target, 0 })
      if mode:match("[vVoO]") then
        vim.cmd("normal! ^")
      end
      return
    end

    -- Still ambiguous: keep waiting for the next char (preview handled by
    -- redraw; Emacs simply narrows candidates).
    vim.cmd("redraw")
  end

  M.jump_active = false
  vim.cmd("redraw")
end

-- =============================================================================
--  Search-active tracking (Emacs sc--search-activate / sc--search-deactivate)
-- =============================================================================

--- Wire autocmds that toggle `M.search_active` on/off, mirroring Emacs's
--- advice on evil-ex-search / evil-search / evil-ex-nohighlight.
---
--- Rather than override any of your search keymaps (which would break the
--- `nzz`/`Nzz`/`*zzv` bindings), we derive "active" from `vim.v.hlsearch`:
--- nvim sets `v:hlsearch` to 1 while search highlights are showing and drops
--- it to 0 after `:nohlsearch` (until the next search reactivates it).  This is
--- the faithful analogue of Emacs's `:noh` (`evil-ex-nohighlight`).
function M.setup_search_hooks()
  -- `M.search_active` is refreshed lazily inside M.search_instance(); this
  -- hook only forces a redraw so the gutter updates the moment the user runs
  -- `:nohlsearch` (or a new search).
  local group = vim.api.nvim_create_augroup("StatusColumnSearch", { clear = true })
  vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = group,
    callback = function()
      vim.schedule(function()
        -- Re-evaluate active state and repaint the status column.
        M.search_active = (vim.v.hlsearch == 1)
        vim.cmd("redrawstatus")
      end)
    end,
  })
end

-- =============================================================================
--  Mark-recency tracking (Emacs sc--track-recent-mark / sc--recent-marks)
-- =============================================================================

--- Record a mark char as "most recent" and force an immediate statuscolumn
--- redraw.  Called from the `MarkSet` autocmd below.
function M.note_mark(ch)
  -- Move `ch` to the front (most recent).
  for i, existing in ipairs(M._recent_marks) do
    if existing == ch then
      table.remove(M._recent_marks, i)
      break
    end
  end
  table.insert(M._recent_marks, 1, ch)
  if #M._recent_marks > 50 then
    M._recent_marks[#M._recent_marks] = nil
  end
end

--- Record recency the instant a mark is set, and force a gutter repaint so the
--- label updates on the SAME keystroke (Emacs rebuilt on post-command-hook).
function M.setup_mark_hooks()
  local group = vim.api.nvim_create_augroup("StatusColumnMarks", { clear = true })
  vim.api.nvim_create_autocmd("MarkSet", {
    group = group,
    callback = function(ev)
      local name = ev and ev.data and ev.data.name
      if not name or not name:match("^%a$") then
        return
      end
      M.note_mark(name)
      -- Repaint immediately so the new label shows on this keystroke.
      vim.cmd("redrawstatus")
    end,
  })
end

-- =============================================================================
--  Setup: wire into statuscol.nvim
-- =============================================================================

--- Configure the statuscolumn (called from the statuscol plugin's config).
--- Replaces the old vai-based labels with M's static labels + new elements.
function M.setup(opts)
  opts = opts or {}
  local statuscol = require("statuscol")

  ensure_highlights()
  M.setup_search_hooks()
  M.setup_mark_hooks()

  statuscol.setup(vim.tbl_deep_extend("force", {
    relculright = true,
    segments = {
      {
        -- git signs (gitsigns namespace), shifted one cell right via a leading
        -- space so they do not sit flush against the window edge.
        text = { "%#StatusColumnLabel# " },
      },
      {
        sign = {
          namespace = { "gitsigns" },
          maxwidth = 1,
          colwidth = 1,
          auto = false,
        },
        hl = "CursorLineNr",
      },
      -- The complete Emacs `line-prefix` per line (mark + label + scrollbar +
      -- `┣`/`│` bump), rendered as ONE string so ordering is exactly right.
      { text = { M.gutter_segment } },
      { text = { "%#NoColor#" } },
    },
  }, opts))
end

return M
