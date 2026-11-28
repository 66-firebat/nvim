-- =============================================================================
--  mru.lua — GLOBAL most-recently-used buffer list (single source of truth)
--
--  Ports the `focusHistory` model from git_repositories/spinner6
--  (`shell.qml` + `lib/spinner6-core.js`): ONE MRU-first ordered array of
--  buffers, where an item's INDEX in that array *is* the number shown in the
--  tab bar and in the <M-i> picker.
--
--  Properties (agreed in the design Q&A — see emacs-to-nvim.md §8b):
--    * Numbers are STRICTLY 1-based array positions.  No gaps.  Removing an
--      entry shifts everything after it up by one.
--    * The list is GLOBAL.  `tabs.lua` only *displays* one group at a time, so
--      a group's visible tabs may show non-contiguous numbers (1, 4, 9) —
--      that is intended: the number is the buffer's global MRU rank.
--    * Membership is a PURE predicate evaluated on demand (never cached).
--    * Every `BufEnter` on a member moves it to the front (index 1).
--    * New buffers are appended to the TAIL; they only reach #1 on entry.
--    * Pruning happens ONLY on `BufWipeout`, synchronously, and does nothing
--      but a pure Lua table removal (no nvim API calls -> cannot recurse).
--
--  API:
--      local mru = require("config.mru")
--      mru.setup()                 -- create autocmds (call once)
--      mru.touch(bufnr)            -- move to front (no-op if not a member)
--      mru.rank(bufnr)             -- 1-based global index, or nil
--      mru.list()                  -- MRU-first bufnr array (filtered)
--      mru.list_excluding(bufnr)   -- list() minus one bufnr
--      mru.is_member(bufnr)        -- boolean
--      mru.refresh()               -- force membership rebuild
--      mru.terminal_prog(bufnr)    -- foreground program name of a terminal
-- =============================================================================

local M = {}

-- =============================================================================
--  State
-- =============================================================================

--- The MRU list.  `order[1]` is the most recently used buffer.
--- Entries are raw bufnrs; validity/metadata is resolved lazily at read time.
---@type integer[]
local order = {}

-- =============================================================================
--  §1  Membership
-- =============================================================================

--- Return true if BUFNR belongs in the global MRU list.
---
--- Membership = listed + has a name + not a `*scratch*`-style buffer
---             + oil directory buffers (which oil creates as `buflisted=false`).
--- Terminals ARE members (their tab label is resolved separately).
---
--- This is a PURE predicate: it reads live buffer state every call and never
--- caches, so a buffer that stops (or starts) qualifying is handled naturally.
---@param bufnr integer
---@return boolean
function M.is_member(bufnr)
  if type(bufnr) ~= "number" or bufnr <= 0 then
    return false
  end
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  -- Terminal buffers are members whenever they have a running job, EVEN while
  -- their name is still the raw `term://...` form (spawn_terminal names them
  -- a moment later).  Without this a freshly spawned terminal reads as a
  -- non-member during its TermOpen/BufEnter, so the winbar renders a "?" rank.
  local is_term = vim.bo[bufnr].buftype == "terminal"

  -- Oil directory buffers are deliberately `buflisted = false`.
  local is_oil = vim.bo[bufnr].filetype == "oil"
  if not (is_oil or is_term) and not vim.bo[bufnr].buflisted then
    return false
  end

  -- Skip unnamed and scratch-style buffers (mirrors Emacs' exclusion list).
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return false
  end
  local bname = vim.fn.bufname(bufnr)
  if bname == "[No Name]" or bname:match("^%*") then
    return false
  end

  return true
end

-- =============================================================================
--  §2  Mutations
-- =============================================================================

--- Return the 1-based index of BUFNR in `order`, or nil.
--- Pure table scan (safe to call from within autocmds).
---@param bufnr integer
---@return integer|nil
local function index_of(bufnr)
  for i, b in ipairs(order) do
    if b == bufnr then
      return i
    end
  end
  return nil
end

--- Append BUFNR to the TAIL if it is a member and not already tracked.
--- Used for buffers that appear WITHOUT being entered (background opens); the
--- `BufEnter` that accompanies a normal open promotes them to #1 right after.
---@param bufnr integer
function M.add_to_tail(bufnr)
  if not bufnr or index_of(bufnr) then
    return
  end
  if M.is_member(bufnr) then
    table.insert(order, bufnr)
  end
end

--- Return true while a Snacks picker is open (any active picker).
--- Used to suppress MRU reordering caused by the picker's PREVIEW: showing a
--- buffer in a preview must not promote it to #1 (it isn't "use").  The tab bar
--- still displays the previewed buffer as current via `M.preview_buffer()`.
---@return boolean
function M.is_picker_active()
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    return false
  end
  local ok2, pickers = pcall(function()
    return snacks.picker.get()
  end)
  return ok2 and type(pickers) == "table" and #pickers > 0
end

--- The TAB window that opened the buffer picker.  Only that window's winbar is
--- allowed to follow the picker's preview; every other window keeps showing its
--- own buffer/group.  Recorded by `M.pick_buffers()`.
---@type integer|nil
local preview_origin_win = nil

--- Return the window that owns the picker's preview, or nil when no picker is
--- open.  `render()` compares this against the window it is drawing for.
---@return integer|nil
function M.preview_origin_window()
  if not M.is_picker_active() then
    return nil
  end
  if preview_origin_win and vim.api.nvim_win_is_valid(preview_origin_win) then
    return preview_origin_win
  end
  return nil
end

--- Return the buffer currently shown in an open picker's PREVIEW window, or nil.
--- render() treats this as the "current" buffer for display purposes only.
---@return integer|nil
function M.preview_buffer()
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    return nil
  end
  local ok2, pickers = pcall(function()
    return snacks.picker.get()
  end)
  if not ok2 or type(pickers) ~= "table" then
    return nil
  end
  for _, pk in ipairs(pickers) do
    local pw = pk.preview and pk.preview.win
    local winid = pw and pw.win
    if winid and vim.api.nvim_win_is_valid(winid) then
      local buf = pw.buf or vim.api.nvim_win_get_buf(winid)
      if buf and vim.api.nvim_buf_is_valid(buf) then
        return buf
      end
    end
  end
  return nil
end

--- Move BUFNR to the front of the MRU list.
--- An untracked member is first appended, then promoted — so the `BufEnter`
--- that accompanies opening a file makes it #1 immediately (design Q7+Q8).
--- Emacs/spinner6 analogue: `moveToFront`.
---@param bufnr integer
function M.touch(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Do NOT reorder while a picker is open: its preview window fires BufEnter on
  -- merely-highlighted buffers, which must not be promoted (design: preview is
  -- not use).  The tab bar shows the previewed buffer via `preview_buffer()`.
  if M.is_picker_active() then
    return
  end

  local i = index_of(bufnr)
  if i == 1 then
    return
  elseif i then
    table.remove(order, i)
    table.insert(order, 1, bufnr)
    return
  end

  -- Not tracked yet: only add if it qualifies, then front it.
  if M.is_member(bufnr) then
    table.insert(order, 1, bufnr)
  end
end

--- Drop BUFNR from the list without reordering anything else.
--- NOTE: this is the body of the `BufWipeout` handler — PURE table removal,
--- no nvim API calls, so it can never recurse or fail mid-wipe.
---@param bufnr integer
local function remove(bufnr)
  local i = index_of(bufnr)
  if i then
    table.remove(order, i)
  end
end

--- Rebuild the membership of the list, preserving existing MRU order where
--- possible: tracked buffers that are still members keep their relative order;
--- any other live member buffers are appended (in bufnr order) at the tail.
function M.refresh()
  local seen = {}
  local rebuilt = {}

  for _, bufnr in ipairs(order) do
    if not seen[bufnr] and M.is_member(bufnr) then
      seen[bufnr] = true
      rebuilt[#rebuilt + 1] = bufnr
    end
  end

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if not seen[bufnr] and M.is_member(bufnr) then
      seen[bufnr] = true
      rebuilt[#rebuilt + 1] = bufnr
    end
  end

  order = rebuilt
end

-- =============================================================================
--  §3  Readers
-- =============================================================================

--- Return the global MRU list (most recent first), filtered to valid members.
--- Dead/vanished buffers are skipped here as a cheap safety net (the primary
--- pruning happens in the `BufWipeout` handler).
---@return integer[]
function M.list()
  local out = {}
  for _, bufnr in ipairs(order) do
    if M.is_member(bufnr) then
      out[#out + 1] = bufnr
    end
  end
  return out
end

--- Like `list()`, but with EXCLUDE omitted (the picker drops the current buf).
---@param exclude integer|nil
---@return integer[]
function M.list_excluding(exclude)
  local out = {}
  for _, bufnr in ipairs(M.list()) do
    if bufnr ~= exclude then
      out[#out + 1] = bufnr
    end
  end
  return out
end

--- Return the 1-based global MRU rank of BUFNR, or nil if it is not listed.
--- @param bufnr integer
--- @return integer|nil
function M.rank(bufnr)
  local n = 0
  for _, b in ipairs(order) do
    if M.is_member(b) then
      n = n + 1
      if b == bufnr then
        return n
      end
    end
  end

  -- Self-heal: the buffer is a legitimate member but was never added to `order`
  -- (a race — e.g. a winbar renders between a terminal being created and its
  -- TermOpen/BufEnter hook running).  Adopt it at the tail and report its rank
  -- instead of returning nil, which surfaced as a "?" in the tab bar.
  if M.is_member(bufnr) then
    table.insert(order, bufnr)
    return n + 1
  end

  return nil
end

-- =============================================================================
--  §3b  Rank label (two-letter aliasing, vai.nvim home-row order)
-- =============================================================================

-- Keys ordered by typing ease (vai.nvim `default_labels`): home row first,
-- then top row, then bottom row.  This makes `aa`/`ss`/`dd`/... land on
-- home-row keys, which are the fastest to double-tap.
local RANK_KEYS = {
  "a", "s", "d", "f", "g", "j", "k", "l", -- home row (8)
  "w", "e", "r", "t", "y", "u", "i", "o", -- top row (8)
  "c", "v", "n",                             -- bottom row (3)
}

-- Pre-built combo list in vai's "ease of typing" order: doubles first
-- (`aa`, `ss`, ...), then the fan-out (`as`, `ad`, ...).  Matches
-- vai.nvim's `build_combo_list(default_labels)` exactly.
local RANK_LABELS = {}
do
  for _, l in ipairs(RANK_KEYS) do
    RANK_LABELS[#RANK_LABELS + 1] = l .. l
  end
  for _, c1 in ipairs(RANK_KEYS) do
    for _, c2 in ipairs(RANK_KEYS) do
      if c1 ~= c2 then
        RANK_LABELS[#RANK_LABELS + 1] = c1 .. c2
      end
    end
  end
end

local RANK_LABEL_COUNT = #RANK_LABELS -- 361 (19 doubles + 342 fan-outs)

--- Map a 1-based MRU rank to a stable two-letter label.
--- 1 -> "aa", 2 -> "ss", ... (vai home-row order).  Beyond the 361 two-letter
--- combos (extremely rare), falls back to `<label><cycle>` so it stays short
--- and never collides (e.g. "aa2" for the 2nd overflow cycle).
---@param rank integer|nil
---@return string
function M.rank_label(rank)
  rank = rank or 0
  if type(rank) ~= "number" or rank < 1 then
    return "?"
  end
  if rank <= RANK_LABEL_COUNT then
    return RANK_LABELS[rank]
  end
  -- Overflow: cycle the labels and suffix a number.
  local cycle = math.floor((rank - 1) / RANK_LABEL_COUNT)
  local rem = ((rank - 1) % RANK_LABEL_COUNT) + 1
  return RANK_LABELS[rem] .. tostring(cycle)
end

-- =============================================================================
--  §4  Terminal foreground-program resolution
-- =============================================================================

--- How often (ms) the focused window's terminal is re-polled for its
--- foreground program.  Configurable.
M.term_poll_interval = 5000

--- bufnr -> program name cache.  Refreshed on TermEnter / BufEnter /
--- FocusGained / TermClose, and by the focused-window poll.
---@type table<integer, string>
local prog_cache = {}

--- Read a field out of /proc/<pid>/stat, working around the comm field being
--- wrapped in parentheses and possibly containing spaces/parens itself.
---@param pid integer
---@return { pgrp: integer, tpgid: integer }|nil
local function proc_stat(pid)
  local f = io.open("/proc/" .. pid .. "/stat", "r")
  if not f then
    return nil
  end
  local line = f:read("*l")
  f:close()
  if not line then
    return nil
  end
  -- Skip "pid (comm) " — comm may itself contain spaces or parens, so anchor
  -- on the LAST ')' in the line's first field group.
  local rest = line:match("^%d+ %b() (.*)$")
  if not rest then
    return nil
  end
  -- rest is space-separated: state ppid pgrp session tty_nr tpgid ...
  local fields = {}
  for w in rest:gmatch("%S+") do
    fields[#fields + 1] = w
  end
  return {
    pgrp = tonumber(fields[3]),
    tpgid = tonumber(fields[6]),
  }
end

--- Read /proc/<pid>/comm (the process' short name).
---@param pid integer
---@return string|nil
local function proc_comm(pid)
  local f = io.open("/proc/" .. pid .. "/comm", "r")
  if not f then
    return nil
  end
  local name = f:read("*l")
  f:close()
  return name ~= "" and name or nil
end

--- Child pids of PID, via /proc/<pid>/task/<pid>/children (cheap; avoids
--- scanning all of /proc).
---@param pid integer
---@return integer[]
local function proc_children(pid)
  local out = {}
  local f = io.open("/proc/" .. pid .. "/task/" .. pid .. "/children", "r")
  if not f then
    return out
  end
  local line = f:read("*l")
  f:close()
  for n in (line or ""):gmatch("%d+") do
    out[#out + 1] = tonumber(n)
  end
  return out
end

--- Resolve the FOREGROUND program of a terminal buffer.
---
--- Algorithm (verified empirically against nvim's pty):
---   1. Read the shell's `tpgid` from /proc/<job_pid>/stat (field 6).
---   2. If tpgid == job_pid (or invalid), the shell itself is in the
---      foreground -> return the shell's `comm` (e.g. "bash").
---   3. Otherwise the foreground job is the process whose `pgrp == tpgid`.
---      Find it among the shell's children (not a full /proc scan).
---@param bufnr integer
---@return string|nil
function M.terminal_fg_program(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "terminal" then
    return nil
  end

  local ok, job_pid = pcall(vim.api.nvim_buf_get_var, bufnr, "terminal_job_pid")
  if not ok or not job_pid or job_pid <= 0 then
    return nil
  end

  local shell_stat = proc_stat(job_pid)
  if not shell_stat then
    return nil
  end

  -- The shell is in the foreground: report the shell itself.
  if not shell_stat.tpgid or shell_stat.tpgid <= 0 or shell_stat.tpgid == job_pid then
    return proc_comm(job_pid) or "sh"
  end

  -- Otherwise look among the shell's children for the foreground pgrp leader.
  for _, child in ipairs(proc_children(job_pid)) do
    local st = proc_stat(child)
    if st and st.pgrp == shell_stat.tpgid then
      return proc_comm(child) or proc_comm(job_pid)
    end
  end

  -- Fallback: the pgrp leader may not be a direct child; if we cannot find it,
  -- report the shell rather than showing something stale/wrong.
  return proc_comm(job_pid)
end

--- Return the cached foreground program of a terminal, resolving on a miss.
--- Non-terminal buffers return nil (callers fall back to their own naming).
---@param bufnr integer
---@return string|nil
function M.terminal_prog(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].buftype ~= "terminal" then
    return nil
  end
  local cached = prog_cache[bufnr]
  if cached then
    return cached
  end
  local prog = M.terminal_fg_program(bufnr)
  if prog then
    prog_cache[bufnr] = prog
  end
  return prog
end

--- Re-resolve the foreground program of BUFNR, updating the cache.
--- Returns true if the value CHANGED (caller can then force a redraw).
---@param bufnr integer
---@return boolean changed
function M.refresh_terminal_prog(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  if vim.bo[bufnr].buftype ~= "terminal" then
    return false
  end
  local old = prog_cache[bufnr]
  local new = M.terminal_fg_program(bufnr)
  if new == nil then
    return false
  end
  if new == old then
    return false
  end
  prog_cache[bufnr] = new
  return true
end

--- Return the live cwd of a terminal buffer via /proc/<pid>/cwd (Linux).
--- Mirrors reusable_functions.terminal_cwd, kept here so mru owns terminal
--- naming without a cross-module dependency cycle.
---@param bufnr integer
---@return string|nil
function M.terminal_cwd(bufnr)
  if vim.bo[bufnr].buftype ~= "terminal" then
    return nil
  end
  local pid = vim.api.nvim_buf_get_var(bufnr, "terminal_job_pid")
  if not pid then
    return nil
  end
  local ok, cwd = pcall(vim.uv.fs_readlink, "/proc/" .. pid .. "/cwd")
  if ok and cwd then
    return cwd
  end
  return nil
end

--- Display name for a terminal buffer: "<prog>:<cwd-basename>"
--- (e.g. "bash:nvim").  Falls back to just the program when the cwd can't be
--- resolved.  Used by BOTH the tabline (tabs.lua) and the <M-i> buffer picker.
---@param bufnr integer
---@return string
function M.terminal_name(bufnr)
  local prog = M.terminal_prog(bufnr) or "terminal"
  local cwd = M.terminal_cwd(bufnr)
  if cwd and cwd ~= "" then
    local base = vim.fn.fnamemodify(cwd, ":t")
    if base ~= "" and base ~= "/" then
      return prog .. ":" .. base
    end
  end
  return prog
end

--- Drop a terminal's cached foreground-program name (called from
--- config/terminal_autocmds.lua on TermOpen/TermClose so the next refresh
--- re-resolves it from /proc).
---@param bufnr integer
function M.invalidate_terminal_prog(bufnr)
  prog_cache[bufnr] = nil
end

-- =============================================================================
--  §5  Setup
-- =============================================================================

--- Create the autocmds that drive the MRU list and the terminal cache.
--- Call once (from init.lua).
function M.setup()
  local group = vim.api.nvim_create_augroup("GlobalMRU", { clear = true })

  -- Every BufEnter on a member moves it to the front.  No filtering: transient
  -- buffers are excluded by `is_member` anyway, and dead ones get pruned.
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(ev)
      M.touch(ev.buf)
    end,
  })

  -- Buffers that appear WITHOUT being entered (background opens) join at the
  -- TAIL.  If the buffer is then actually entered, the BufEnter above promotes
  -- it to #1, which is the usual case (design Q7+Q8).
  vim.api.nvim_create_autocmd({ "BufNew", "BufAdd" }, {
    group = group,
    callback = function(ev)
      M.add_to_tail(ev.buf)
    end,
  })

  -- A terminal becomes a member only once TermOpen fires (its buftype is still
  -- empty during the BufEnter that creates it), so touch there to make the
  -- freshly spawned terminal #1 immediately.  This now lives in
  -- config/terminal_autocmds.lua (TerminalMRUTrack augroup).

  -- PRUNE: the only removal event we listen to.  Body is a pure table removal
  -- (no nvim API calls), so it is safe to run synchronously while nvim is
  -- tearing the buffer down -> the picker's refresh() never sees stale ranks.
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(ev)
      remove(ev.buf)
      M.invalidate_terminal_prog(ev.buf)
    end,
  })

  -- ── Terminal foreground-program cache ────
  -- Moved to config/terminal_autocmds.lua (TerminalMRURefresh augroup + the
  -- focused-window poll timer).  That file uses the public helpers
  -- M.refresh_terminal_prog / M.invalidate_terminal_prog, so `prog_cache` stays
  -- private to this module.

  -- Seed the list with whatever is already open.
  M.refresh()
end

-- =============================================================================
--  §6  Buffer picker (<M-i>) — global MRU order + MRU ranks
-- =============================================================================

--- Short display name for a buffer, mirroring the tab-bar naming rule so the
--- picker and the tab bar agree (design Q18/Q19).
---@param bufnr integer
---@return string
local function buffer_display_name(bufnr)
  if vim.bo[bufnr].buftype == "terminal" then
    return M.terminal_name(bufnr)
  end
  if vim.bo[bufnr].filetype == "oil" then
    local raw = vim.api.nvim_buf_get_name(bufnr)
    local dir = raw:gsub("^oil://", ""):gsub("/+$", "")
    if dir == "" then dir = "/" end
    local base = vim.fn.fnamemodify(dir, ":t")
    if base == "" then base = vim.fn.fnamemodify(dir, ":~") end
    return base ~= "" and base or dir
  end
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
  if name == "" then name = vim.fn.bufname(bufnr) end
  return name
end

--- Open the buffer picker in GLOBAL MRU order, numbered by MRU rank and
--- starting at rank 2 (the current buffer is excluded — design Q5).
---
--- The finder is custom so the list is exactly our MRU order (Snacks' own
--- buffers finder sorts by `lastused` and renders the raw bufnr).  Deletion
--- still works: `dd`/`<c-d>` -> Snacks.bufdelete.delete() -> `BufWipeout` ->
--- mru's synchronous table removal -> picker:refresh() re-renders with correct
--- ranks (zero flicker — design Q21/Q22).
function M.pick_buffers()
  local current = vim.api.nvim_get_current_buf()

  -- Remember WHICH tab window opened the picker.  Only this window's winbar is
  -- allowed to follow the preview; all other windows keep their own buffer.
  -- Captured here because by the time the picker is shown, the picker's float
  -- has focus and the original window is no longer "current".
  preview_origin_win = vim.api.nvim_get_current_win()

  -- Build items lazily via a FINDER (not a frozen `items` snapshot), so the
  -- list re-enumerates on every refresh.  Deleting a buffer (`dd`/`<c-d>`)
  -- re-runs the finder and drops the deleted entry — no stale rows.
  --
  -- The CURRENT buffer (rank 1) IS listed: it is shown for reference.  The
  -- selection starts on rank 2 (see `initial_idx` below), so choosing a
  -- different buffer is one keypress away without hiding the current one.
  local function build_items()
    local live = M.list()
    local rank_at = {}
    for i, b in ipairs(live) do
      rank_at[b] = i
    end
    local out = {}
    for _, bufnr in ipairs(live) do
      local filename = vim.api.nvim_buf_get_name(bufnr)
      local name = buffer_display_name(bufnr)
      local rank = rank_at[bufnr] or 0
      local label = M.rank_label(rank)

      -- Build the searchable `text` so the MRU rank (the visible index) is
      -- searchable.  For terminals, `name` is already the foreground program
      -- (bash/pi/...) which IS the user-visible label — search on that, not the
      -- raw `term://...` buffer name (which may carry paths/IDs unrelated to
      -- what the user sees).  For files/oil, keep the full path so path search
      -- still works.  The rank digit stays FIRST so typing a number filters by
      -- index.
      local searchable_name
      if vim.bo[bufnr].buftype == "terminal" then
        -- `name` is already the foreground program (bash/pi/...).
        searchable_name = name
      else
        -- Files/oil keep their path so path search still works.
        searchable_name = name .. " " .. filename
      end

      out[#out + 1] = {
        buf = bufnr,
        rank = rank_at[bufnr] or 0,
        -- `name` is the raw buffer name (for matching); `file` drives the
        -- icon/display and is our friendly short name.
        name = filename,
        file = name,
        buftype = vim.bo[bufnr].buftype,
        filetype = vim.bo[bufnr].filetype,
        -- rank digit stays FIRST so typing a number filters by index.
        text = label .. " " .. searchable_name,
      }
    end
    return out
  end

  -- Build the list ONCE to seed the initial cursor position.  The picker's
  -- FINDER (below) re-runs `build_items` on every refresh, so deleting a
  -- buffer (`dd`/`<c-d>`) re-enumerates and drops the stale entry.
  local items = build_items()

  -- Row to select on open: the entry whose rank is 2 (i.e. switch to the
  -- previous buffer by default).  Falls back to 1 when there is only one
  -- buffer.
  local initial_row = 1
  for i, it in ipairs(items) do
    if it.rank == 2 then
      initial_row = i
      break
    end
  end

  local picker
  picker = require("snacks").picker.pick({
    -- NOTE: deliberately NO `source = "buffers"` — that would install Snacks'
    -- own buffers finder, which re-enumerates every buffer (sorted by
    -- `lastused`) and discards our `items`.  With a custom FINDER we own the
    -- list AND it re-runs on refresh (so `dd`/`<c-d>` deletions drop the entry).
    title = "Buffers (MRU)",
    -- Re-enumerate the MRU list on every refresh.  The built-in `bufdelete`
    -- action calls `picker:refresh()` after deleting, which re-runs this finder
    -- and rebuilds the list WITHOUT the just-deleted buffer.
    finder = build_items,
    -- Preserve our finder order (ascending MRU rank); Snacks would otherwise
    -- re-sort scored items and destroy the MRU ordering.
    sort = false,
    -- Preview (and commit) in the PANEL that launched the picker, not a fixed
    -- window.  `main = { current = true }` makes Snacks resolve `picker.main`
    -- to `vim.api.nvim_get_current_win()` at picker-creation time — which is
    -- still the origin panel (the picker float is shown later).  This keeps the
    -- preview inside the launching split and leaves the other split untouched.
    main = { current = true },
    -- Render: "<rank>  <icon><name>"  (rank replaces the raw bufnr).
    -- Uses the SNAPSHOT rank so the numbers stay stable while the picker is
    -- open (they re-sync on the next open).
    format = function(item, picker_)
      local SnacksFmt = require("snacks.picker.format")
      local label = M.rank_label(item.rank or 0)
      local ret = {
        { ("%3s"):format(label), "SnacksPickerBufNr" },
        { " " },
      }
      vim.list_extend(ret, SnacksFmt.filename(item, picker_))
      return ret
    end,
    -- Keep the TABLINE in sync with the previewed buffer (design option b).
    -- Snacks calls this whenever the highlighted item changes, BEFORE the
    -- preview window is repainted, so defer one tick and then force every
    -- window's WINBAR to re-evaluate.  `nvim__redraw{winbar=true}` is the only
    -- thing that reliably repaints the winbar of non-current windows (a plain
    -- :redrawstatus! does not).
    on_change = function()
      vim.schedule(function()
        pcall(vim.api.nvim__redraw, { winbar = true, flush = true })
      end)
    end,
    -- Reset the origin tracking when the picker closes.
    on_close = function()
      preview_origin_win = nil
    end,
    -- Confirm: switch to the buffer IN THE PANEL that launched the picker.
    confirm = function(p, item)
      p:close()
      if item and item.buf and vim.api.nvim_buf_is_valid(item.buf) then
        -- Restore focus to the origin window (the picker float just closed) and
        -- swap ITS buffer, leaving every other split untouched.
        local target = preview_origin_win
          and vim.api.nvim_win_is_valid(preview_origin_win)
          and preview_origin_win
          or vim.api.nvim_get_current_win()
        pcall(vim.api.nvim_win_set_buf, target, item.buf)
      end
    end,
    win = {
      input = {
        keys = {
          ["dd"] = "bufdelete",
          ["<c-d>"] = { "bufdelete", mode = { "n", "i" } },
        },
      },
      list = { keys = { ["dd"] = "bufdelete" } },
    },
  })

  -- Seed the cursor row SYNCHRONOUSLY, before the first render.
  --
  -- Doing this in `on_show` (or via vim.schedule) meant the list painted once
  -- with the cursor on rank 1 and only then jumped to rank 2 — a visible
  -- flicker, and it briefly previewed the current buffer.  Setting the target
  -- here records it on the list object before Snacks renders, so the very first
  -- frame already has rank 2 selected (`list:set_target` stores a target that
  -- `list:render` consumes on its first pass).
  if picker and picker.list then
    pcall(function()
      picker.list:set_target(initial_row, 1, { force = true })
    end)
  end

  return picker
end

return M
