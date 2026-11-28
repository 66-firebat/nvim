-- =============================================================================
--  reusable_functions.lua — general-purpose functions for the nvim config
--
--  This module holds every custom Lua function that is bound to a key (or
--  exposed for manual binding).  `keymaps.lua` requires this module and keeps
--  ONLY the `vim.keymap.set(...)` bind lines.
--
--  Usage from keymaps.lua:
--      local M = require("config.reusable_functions")
--      vim.keymap.set("n", "<M-w>", M.smart_other_window, { desc = "..." })
--
--  NOTE: These functions are intentionally UNBOUND.  Any function that you want
--  on a key must be wired by you, manually, in keymaps.lua.
-- =============================================================================

local M = {}

-- =============================================================================
--  §1  Window management (port of emacs/keybinds.el `smart-other-window`
--      and `smart-close-window`)
-- =============================================================================

--- If only one window exists, split right & show the alternate buffer;
--- otherwise focus the other window.
--- Emacs: `my/smart-other-window` (M-w)
function M.smart_other_window()
  local win_count = vim.fn.winnr("$")
  if win_count <= 1 then
    -- Only one window: split right and show the alternate buffer.
    --
    -- Which buffer should the new window show?  Use the MRU list, NOT
    -- `bufnr("#")`.
    --
    -- `#` is unreliable here: after spawning a terminal via
    -- `bash -c 'cd ... && exec bash'`, nvim can leave the discarded wrapper
    -- buffer as the alternate (buftype empty, buflisted false, raw `term://`
    -- name), so `#` pointed at a ghost instead of the "other" real buffer.
    -- The MRU list is the user-visible ordering, so the buffer to show is
    -- simply the highest-ranked entry that isn't the current one.
    local current = vim.api.nvim_get_current_buf()
    local target
    local ok, mru = pcall(require, "config.mru")
    if ok then
      for _, b in ipairs(mru.list()) do
        if b ~= current then
          target = b
          break
        end
      end
    end
    if not target then
      local alt = vim.fn.bufnr("#")
      if alt ~= -1 and alt ~= current and vim.api.nvim_buf_is_valid(alt) then
        target = alt
      end
    end

    vim.cmd("vsplit")

    if target then
      vim.api.nvim_win_set_buf(0, target)
      -- Focusing it makes it the most-recently-used buffer; `touch` moves it to
      -- rank 1 and shifts the one we came from to 2, and the redraw makes both
      -- winbars show the new order immediately.
      if ok then
        mru.touch(target)
      end
      pcall(vim.api.nvim__redraw, { winbar = true, flush = true })
    end
  else
    vim.cmd("wincmd w")
  end
end

--- Close the current window; no-op if it is the last (non-floating) window in
--- the tab.
--- Emacs: `my/smart-close-window` (M-W)
function M.smart_close_window()
  -- Do not touch floating windows (pickers, notifications).
  local cur = vim.api.nvim_get_current_win()
  local cfg = vim.api.nvim_win_get_config(cur)
  if cfg.relative and cfg.relative ~= "" then
    return
  end
  -- Count only NON-floating windows in the current tab: `winnr("$")` includes
  -- floats, which made the guard pass while `:close` still failed with E444.
  local real = 0
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local c = vim.api.nvim_win_get_config(w)
    if not (c.relative and c.relative ~= "") then
      real = real + 1
    end
  end
  if real <= 1 then
    vim.notify("Last window in tab, doing nothing", vim.log.levels.INFO)
    return
  end
  pcall(vim.cmd, "close")
end

--- Jump to a mark (global or local), recording the pre-jump position in the
--- global jump ring so C-o returns here.  `mode` is "`" (exact column) or
--- "'" (line start).
--- Emacs: jumping to a mark records to `evil-jump` list.
function M.jump_to_mark(mode)
  -- Read the target mark character (a-z / A-Z).
  local ch = vim.fn.nr2char(vim.fn.getchar())
  if ch == "\27" or ch == "" then
    return
  end
  -- Record current position before the jump.
  local ok, jump = pcall(require, "config.jumplist")
  if ok and jump and jump.push then jump.push() end
  -- Perform the mark jump: ` for exact column, ' for line start.
  vim.cmd("normal! " .. mode .. ch)
end

-- =============================================================================
--  §3  File managers / terminals
-- =============================================================================

--- Return the directory of the file currently focused in the window.
--- Falls back to the global cwd when the buffer has no file (scratch/terminal).
--- This is the canonical "where am I" for spawning file-manager / terminal tools.
function M.current_file_dir()
  local dir = vim.fn.expand("%:p:h")
  -- NOTE: vim.fn.isdirectory returns a NUMBER (1/0), and Lua treats 0 as
  -- truthy, so compare explicitly (== 0 / == 1), never with `not`.
  if dir == "" or vim.fn.isdirectory(dir) == 0 then
    dir = vim.fn.getcwd()
  end
  return dir
end

-- =============================================================================
--  Broot smart dispatch (port of emacs/broot.el)
-- =============================================================================

-- Buffer-local variables set on a broot terminal buffer:
--   b:broot        = true            -> this buffer is a broot session
--   b:broot_source = <bufnr>         -> the buffer broot was spawned from
local BROOT_VAR = "broot"
local BROOT_SOURCE_VAR = "broot_source"

--- Return true if BUFNR is a broot terminal session (buffer-local flag).
--- This is more reliable than name-matching the term:// buffer name.
function M.is_broot(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  if vim.bo[bufnr].buftype ~= "terminal" then
    return false
  end
  local ok = pcall(vim.api.nvim_buf_get_var, bufnr, BROOT_VAR)
  return ok and vim.api.nvim_buf_get_var(bufnr, BROOT_VAR) == true
end

--- Return the live cwd of a terminal buffer via /proc/<pid>/cwd (Linux).
--- Equivalent of emacs/broot.el `my/broot-current-directory`.
function M.terminal_cwd(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
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

--- Spawn `broot` in a FULL-SIZE terminal buffer rooted at the focused file's
--- directory, recording the origin buffer so `broot_toggle` can return to it.
--- Emacs: `my/broot--open` + `my/broot-source-buffer`.
function M.spawn_broot()
  local source_buf = vim.api.nvim_get_current_buf()
  local dir = M.current_file_dir()

  -- `enew` opens a fresh full-size buffer, then `terminal` runs broot there.
  local cmd = string.format("enew | terminal cd %s && exec broot", vim.fn.shellescape(dir))
  vim.cmd(cmd)

  -- The newly created terminal buffer is now current; tag it as a broot
  -- session and record its origin so the toggle can return to the source.
  local broot_buf = vim.api.nvim_get_current_buf()
  if vim.bo[broot_buf].buftype == "terminal" then
    vim.api.nvim_buf_set_var(broot_buf, BROOT_VAR, true)
    vim.api.nvim_buf_set_var(broot_buf, BROOT_SOURCE_VAR, source_buf)
    vim.bo[broot_buf].filetype = "broot"
  end
end

--- Toggle a broot session (Emacs `my/broot-default-directory`).
--- If already in a broot buffer, close it and return to its source buffer.
--- Otherwise spawn a fresh broot session at the focused file's directory.
function M.broot_toggle()
  local bufnr = vim.api.nvim_get_current_buf()
  if M.is_broot(bufnr) then
    -- Close broot and return to the buffer it was spawned from (Q2).
    local source = nil
    local ok = pcall(vim.api.nvim_buf_get_var, bufnr, BROOT_SOURCE_VAR)
    if ok then
      source = vim.api.nvim_buf_get_var(bufnr, BROOT_SOURCE_VAR)
    end
    -- Kill the broot terminal buffer (its process exits when the job dies).
    vim.api.nvim_buf_delete(bufnr, { force = true })
    if source and vim.api.nvim_buf_is_valid(source) then
      vim.api.nvim_set_current_buf(source)
    end
    return
  end
  M.spawn_broot()
end

-- Kept for backward compat: alias to broot_toggle.
function M.open_broot()
  M.broot_toggle()
end

-- =============================================================================
--  Oil smart dispatch (Emacs `M-e` -> my/broot-default-directory analogue)
-- =============================================================================

-- Global map recording, per window, the buffer oil was spawned from.
--
-- Keyed by window id (NOT buffer) because oil's `bufhidden = "wipe"`
-- destroys the oil buffer whenever you navigate into a subdirectory.  A
-- window-local var would work too, but a GLOBAL map survives window
-- close/re-open and lets us seed from Oil's OWN origin tracking
-- (`vim.w.oil_original_buffer`), which oil.nvim maintains via a BufLeave
-- autocmd.
--
--   g:oil_source = { [winid] = origin_bufnr, ... }
--
local OIL_SOURCE_VAR = "oil_source"

--- Read the origin buffer for the CURRENT window from the global map.
--- Prefers Oil's own `w:oil_original_buffer` when present (it tracks the
--- buffer you were in before Oil opened), falling back to g:oil_source.
local function get_oil_source()
  local winid = vim.api.nvim_get_current_win()
  -- 1) Oil's native origin (set by oil's BufLeave autocmd, restored by oil.close).
  local ok, orig = pcall(vim.api.nvim_win_get_var, winid, "oil_original_buffer")
  if ok and orig and vim.api.nvim_buf_is_valid(orig) then
    return orig
  end
  -- 2) Our own global map (seeded on open, survives oil's buffer wipe).
  local src_ok, src = pcall(vim.g, OIL_SOURCE_VAR)
  if src_ok and type(src) == "table" and src[winid] then
    return src[winid]
  end
  return nil
end

--- Record the origin buffer for the CURRENT window in the global map.
local function set_oil_source(bufnr)
  local winid = vim.api.nvim_get_current_win()
  local src = vim.g[OIL_SOURCE_VAR]
  if type(src) ~= "table" then
    src = {}
    vim.g[OIL_SOURCE_VAR] = src
  end
  src[winid] = bufnr
end

--- Return true if BUFNR is an oil directory buffer.
function M.is_oil(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  return vim.bo[bufnr].filetype == "oil"
end

--- Toggle Oil at the current file's directory (Emacs `M-e`).
---
--- - If the current buffer is an oil buffer: close it, and return to the
---   buffer oil was spawned from (tracked via g:oil_source, seeded from
---   Oil's own w:oil_original_buffer).
--- - Otherwise: open oil rooted at the focused file's directory, recording the
---   current buffer as the origin so the toggle can return to it.
function M.oil_toggle()
  local bufnr = vim.api.nvim_get_current_buf()

  if M.is_oil(bufnr) then
    -- Close the oil buffer and return to the buffer oil was spawned from.
    -- We must switch the CURRENT WINDOW away from the oil buffer BEFORE
    -- deleting it: deleting the current buffer of a split window collapses
    -- the split (closes the pane).  Restore the originating buffer first,
    -- then wipe the oil buffer (it is no longer displayed).
    local source = get_oil_source()
    if source and vim.api.nvim_buf_is_valid(source) and source ~= bufnr then
      pcall(vim.api.nvim_win_set_buf, 0, source)
    else
      -- No valid source (e.g. oil opened directly / no var set): fall back
      -- to the alternate/previous buffer so the window does not close.
      pcall(vim.cmd, "silent! bprevious")
    end
    -- Now safe to wipe the oil buffer; it is no longer current in this window.
    pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    return
  end

  -- Not in oil: open it at the current directory and remember the origin.
  local source = bufnr
  local dir
  if vim.bo[bufnr].buftype == "terminal" then
    -- Spawned from a terminal: use that terminal's LIVE working directory
    -- (read from /proc/<pid>/cwd) rather than nvim's cwd.
    dir = M.terminal_cwd(bufnr)
  end
  if not dir or dir == "" then
    dir = M.current_file_dir()
  end
  -- The file we came from, if it is a legitimate on-disk file.  Used to place
  -- the cursor on that entry inside oil.  Skipped for terminals (no filename),
  -- unnamed/scratch buffers, and files that do not exist on disk yet.
  local source_file = vim.api.nvim_buf_get_name(source)
  local want_entry
  if source_file ~= "" and vim.fn.filereadable(source_file) == 1 then
    want_entry = vim.fn.fnamemodify(source_file, ":t")
  end

  local ok = pcall(vim.cmd, "Oil " .. vim.fn.fnameescape(dir))
  if not ok then
    pcall(vim.cmd, "Oil")
  end
  local oil_buf = vim.api.nvim_get_current_buf()
  if M.is_oil(oil_buf) then
    -- Store the origin in the global per-window map so it survives oil's
    -- `bufhidden = "wipe"` when navigating into a subdirectory.
    set_oil_source(source)

    -- Put the cursor ON the originating file inside the oil listing, reusing
    -- oil's own mechanism (the same one it uses when you navigate into and back
    -- out of a directory).  `get_entry_on_line` matching happens on the next
    -- render, so schedule it.
    if want_entry then
      -- oil populates the listing ASYNCHRONOUSLY, so a single schedule() can
      -- run before any entries exist (and `maybe_set_cursor` would silently find
      -- nothing).  Poll until the entry is present, then position on it.
      local attempts, max_attempts = 0, 50 -- ~50 * 20ms = 1s
      local function try_place()
        attempts = attempts + 1
        if not (vim.api.nvim_buf_is_valid(oil_buf) and M.is_oil(oil_buf)) then
          return -- oil closed / replaced; nothing to do
        end
        -- Only act once oil has actually rendered entries.
        local oillib = require("oil")
        local has_entries = false
        for lnum = 1, vim.api.nvim_buf_line_count(oil_buf) do
          local ok_e, e = pcall(oillib.get_entry_on_line, oil_buf, lnum)
          if ok_e and e and e.name == want_entry then
            has_entries = true
            break
          end
        end

        if has_entries then
          local ok_view, view = pcall(require, "oil.view")
          if ok_view and view.set_last_cursor and view.maybe_set_cursor then
            view.set_last_cursor(vim.api.nvim_buf_get_name(oil_buf), want_entry)
            view.maybe_set_cursor()
          end
          return
        end

        if attempts >= max_attempts then
          vim.notify(
            ("oil: '%s' not found in %s"):format(want_entry, dir),
            vim.log.levels.WARN
          )
          return
        end
        vim.defer_fn(try_place, 20)
      end
      vim.defer_fn(try_place, 10)
    end
  end
end

-- =============================================================================
--  §3b  Buffer-group classification + count icon (shared by tabs.lua & lualine)
-- =============================================================================

--- Groups: a label mapped to the list of nvim filetypes that belong to it.
--- This is the canonical "filetype -> group" map, shared by the tabline and
--- anything else that needs to classify buffers.
local GROUPS = {
  Code = {
    "lua", "python", "go", "rust", "java", "c", "cpp", "javascript",
    "typescript", "javascriptreact", "typescriptreact", "css", "scss", "html",
    "json", "jsonc", "yaml", "sql", "nix", "sh", "bash", "zsh", "fish",
    "vim", "ruby", "php", "kotlin", "swift", "haskell",
  },
  FileMgr = { "oil" },
  Docs = { "markdown", "text", "org", "rst", "latex", "tex" },
  Config = { "conf", "dotenv", "toml", "ini", "gitcommit", "gitrebase", "hjson", "json5", "jsonc" },
  Terminal = { "terminal" },
  Broot = { "broot" },
  Tools = { "help", "fugitive", "fugitiveblame", "diff", "git", "man", "qf" },
}

local FALLBACK_GROUP = "Buffers"

--- Classify a buffer by its FILETYPE.  Returns the group label, or the
--- fallback "Buffers" when the filetype is not in any group.
function M.group_for_buffer(bufnr)
  local ft = vim.bo[bufnr].filetype or ""
  for label, fts in pairs(GROUPS) do
    for _, f in ipairs(fts) do
      if f == ft then
        return label
      end
    end
  end
  return FALLBACK_GROUP
end

--- Nerd Font glyphs for a buffer count (1->󰲠, 2->󰲢, ..., 9->󰲰, 10+->󰲲),
--- matching Emacs MRU-tabs.el `my/ct--overflow-icons`.
local overflow_icons = { "󰲠", "󰎧", "󰎪", "󰎭", "󰎱", "󰎳", "󰎶", "󰎹", "󰲰", "󰲲" }

--- Return the Nerd Font glyph for a buffer count (1..10+).
function M.buffer_count_icon(count)
  return overflow_icons[math.min(math.max(count, 1), 10)] or overflow_icons[10]
end

--- Return the number of LISTED buffers that share the active buffer's group.
--- (lualine and the tabline both use this so their counts stay in sync.)
function M.current_group_count()
  local bufnr = vim.api.nvim_get_current_buf()
  local group = M.group_for_buffer(bufnr)
  local n = 0
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buflisted then
      local name = vim.api.nvim_buf_get_name(b)
      local bname = vim.fn.bufname(b)
      if name ~= "" and bname ~= "[No Name]" and not bname:match("^%*") then
        if M.group_for_buffer(b) == group then
          n = n + 1
        end
      end
    end
  end
  return n
end

--- Return the filetype icon for a buffer (via nvim-web-devicons), with a
--- generic fallback icon for unknown filetypes (e.g. .hjson).  Custom icons
--- are registered in lua/plugins/nvim-web-devicons.lua.
function M.filetype_icon(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ok, dev = pcall(require, "nvim-web-devicons")
  if not ok or not dev or not dev.get_icon then
    return "" -- generic file icon fallback
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  local ft = vim.bo[bufnr].filetype
  local icon = dev.get_icon(name, ft)
  if icon and icon ~= "" then
    return icon
  end
  local def = dev.get_default_icon and dev.get_default_icon()
  return (def and def.icon) or ""
end

--- Open Oil (the writable file manager).
--- Emacs analogue: grease.el / dired / dirvish.
function M.open_oil()
  local ok, _ = pcall(vim.cmd, "Oil")
  if not ok then
    vim.cmd("terminal Oil ~")
  end
end

--- Toggle a file manager (Oil) at the current working directory.
--- If already inside an Oil buffer, close it and return to the previous buffer.
--- Emacs: `C-e` -> `my/dired-from-terminal` (using getcwd() instead of OSC-7).
function M.toggle_file_manager_at_cwd()
  if vim.bo.filetype == "oil" then
    -- Already in Oil: close and return to the alternate buffer.
    local alt = vim.fn.bufnr("#")
    vim.cmd("close")
    if alt ~= -1 and vim.api.nvim_buf_is_valid(alt) then
      vim.cmd("buffer " .. alt)
    end
    return
  end

  local dir = vim.fn.expand("%:p:h")
  if dir == "" or vim.fn.isdirectory(dir) == 0 then
    dir = vim.fn.getcwd()
  end
  require("oil").open(dir)
end

-- =============================================================================
--  §4  Search / flash integration
-- =============================================================================

--- Exact-word search (prompt + wrap in \<...\>).
--- Emacs analogue: `S` was ripgrep, but this is the existing nvim `S` binding
--- kept intact; the ripgrep search is `M.search_ripgrep_jump` (§5).
function M.exact_word_search()
  local q = vim.fn.input("Exact Pattern: \\< ...\\>")
  if q == "" then
    return
  end
  q = vim.fn.escape(q, "/")
  vim.fn.setreg("/", "\\<" .. q .. "\\>")
  vim.cmd("silent! normal! n")
  vim.o.hlsearch = true
end

--- Flash jump on `f` (search-sync fixed): record a jump mark, run flash, and
--- when a match is chosen, sync the shared `/` register + search history.
--- This is the existing `f` mapping extracted verbatim.
function M.flash_jump_f()
  vim.cmd("normal! m'")
  -- Record the pre-jump position in the global ring (so C-o returns here).
  local ok, jump = pcall(require, "config.jumplist")
  if ok and jump and jump.push then jump.push() end

  require("flash").jump({
    action = function(match, state)
      -- Update the search register with the pattern.
      vim.fn.setreg("/", state.pattern.pattern)
      -- Move the cursor to the match position.
      vim.api.nvim_win_set_cursor(match.win, { match.pos[1], match.pos[2] })
      -- Add to search history so it shows up in q/.
      vim.fn.histadd("search", state.pattern.pattern)
      -- Clean up flash state.
      state:hide()
    end,
  })
end

-- =============================================================================
--  §5  Search/jump commands (ports of emacs/keybinds.el `s` / `S`)
--      These are intentionally UNBOUND — bind them in keymaps.lua.
-- =============================================================================

--- Record the current position into the global jump ring (if available),
--- so `C-o` returns here.  Falls back gracefully if jumplist module is absent.
local function push_jump()
  local ok, jump = pcall(require, "config.jumplist")
  if ok and jump and jump.push then
    jump.push()
  end
end

--- Seed the shared `/` register + search history so `n`/`N`/`*`/`#` and the
--- statuscolumn search-instance counter all use the same pattern.
--- Emacs: `isearch-update-ring` + `evil-regexp-search`.
local function seed_search(query)
  if not query or query == "" then
    return
  end
  -- Escape nothing: the user typed a plain/fuzzy query; use it literally.
  vim.fn.setreg("/", vim.pesc(query))
  vim.fn.histadd("search", query)
  vim.o.hlsearch = true
end

--- Fuzzy-search the current buffer's lines, seed the `/` register from the
--- typed query (on picker close).  Emacs: `s` -> `my/consult-line-with-jump`.
--- The picker is opened via `vim.schedule` so the mapping returns first and its
--- first redraw isn't swallowed (otherwise it only paints on the next keypress).
function M.search_line_jump()
  push_jump()
  vim.schedule(function()
    Snacks.picker.lines({
      on_close = function(picker)
        local f = picker.input and picker.input.filter
        -- The `lines` picker is NOT live, so the typed fuzzy query lives in
        -- `filter.pattern` (live pickers use `filter.search`).  Reading `search`
        -- here was nil, so the `/` register was never seeded.
        local q = f and (f.pattern or f.search)
        seed_search(q)
      end,
    })
  end)
end

--- Ripgrep the project (root = cwd), seed the `/` register from the typed query
--- (on picker close).  Emacs: `S` -> `my/consult-ripgrep-with-jump`.
function M.search_ripgrep_jump()
  push_jump()
  vim.schedule(function()
    Snacks.picker.grep({
      cwd = vim.fn.getcwd(),
      on_close = function(picker)
        local q = picker.input and picker.input.filter and picker.input.filter.search
        seed_search(q)
      end,
    })
  end)
end

--- Operator-pending flash motion (nvim analog of Emacs `df`/`yf`/`cf`).
--- Bind on `f` in operator-pending mode; flash jumps to the chosen target and
--- the pending operator applies to it (e.g. `dfx` deletes to the x-flash hit).
function M.flash_motion()
  require("flash").jump({ mode = "char" })
end

-- =============================================================================
--  §6  Zoxide travel (port of emacs/ghostel/ghostfire.el `ghostfire-travel`
--      and keybinds.el `my/zoxide-travel-dispatch` / M-z)
-- =============================================================================

--- Run `zoxide query -ls [filter]` and parse output into a list of
--- `{ score = number, path = string }`.
--- Emacs: `ghostfire-parse-score-line` + `ghostfire--run`
function M.zoxide_query(filter)
  local args = { "query", "-ls" }
  if filter and filter ~= "" then
    for word in filter:gmatch("%S+") do
      table.insert(args, word)
    end
  end

  local ok, raw = pcall(vim.fn.system, { "zoxide", unpack(args) })
  if not ok then
    return {}
  end

  local results = {}
  for line in raw:gmatch("[^\n]+") do
    -- zoxide RIGHT-JUSTIFIES the score field, so most lines begin with
    -- whitespace (e.g. " 376.0 /path").  Anchoring with "^%d" would silently
    -- drop every entry except the top-scoring one, so allow leading spaces.
    local score, path = line:match("^%s*(%d+%.?%d*)%s+(.+)$")
    if path then
      table.insert(results, { score = tonumber(score), path = path })
    end
  end
  return results
end

--- Zoxide directory travel — always opens Oil at the chosen directory.
--- Emacs: `my/zoxide-travel-dispatch` (M-z) in keybinds.el.
---
---   anything (including terminal buffers) -> `:Oil <dir>`
---
--- NOTE on oil: `:Oil <dir>` creates a fresh oil buffer, but oil's
--- `bufhidden = "wipe"` (lua/plugins/oil.lua) means the previous one is wiped
--- immediately — so repeating M-z from inside oil never accumulates buffers.
function M.zoxide_travel()
  local results = M.zoxide_query("")
  if #results == 0 then
    vim.notify("zoxide: no entries", vim.log.levels.INFO)
    return
  end

  -- Build picker items: `     1234  /path` (score right-justified to width 6,
  -- then two spaces, then the path) — matches Emacs' `ghostfire-consult-format`.
  local items = {}
  local by_display = {}
  for _, r in ipairs(results) do
    local display = string.format("%6d  %s", math.floor(r.score), r.path)
    by_display[display] = r.path
    items[#items + 1] = {
      text = display,
      path = r.path,
      score = r.score,
      -- `file` drives the icon/rendering; `text` drives fuzzy matching.
      file = r.path,
    }
  end

  local picker
  picker = require("snacks").picker.pick({
    title = "Zoxide",
    items = items,
    -- Keep zoxide's own frecency ordering; Snacks would otherwise re-sort.
    sort = false,
    -- Render the score + path verbatim (no icon column shuffling).
    format = function(item)
      return { { item.text, "Normal" } }
    end,
    confirm = function(p, item)
      p:close()
      local dir = item and (item.path or by_display[item.text])
      if not dir or dir == "" then
        return
      end
      -- All buffer types behave the same: open Oil at the chosen directory.
      vim.cmd("Oil " .. vim.fn.fnameescape(dir))
    end,
  })
  return picker
end

-- =============================================================================
--  §7  Terminal spawn (port of emacs/ghostfire.el `my/ghostel-new-dispatch`,
--      minus the now-defunct numbered-terminal index)
-- =============================================================================

--- Spawn a terminal.  (The old fixed `1  terminal` / `2  terminal` index and
--- `b:numbered_terminal_index` tag were removed: everything is now MRU-ranked
--- on the fly — the tab bar and <M-i> picker show `MRU.rank` + the foreground
--- program — so a second, independent terminal numbering provided no value and
--- leaked a stale `term://N` digit into search.  The cwd resolution and the
--- `cd … && exec $SHELL` spawn below are still needed and kept.)
--- Emacs: `M-t` -> `my/ghostel-new-dispatch`.
function M.spawn_terminal()
  -- Start the shell in the directory of the buffer we spawned from:
  --   * a terminal buffer -> that terminal's LIVE cwd (/proc/<pid>/cwd), so
  --     spawning a terminal from a terminal keeps you where you were;
  --   * any other buffer  -> the focused file's directory (falls back to cwd).
  local source = vim.api.nvim_get_current_buf()
  local dir
  if vim.bo[source].buftype == "terminal" then
    dir = M.terminal_cwd(source)
  end
  if not dir or dir == "" then
    dir = M.current_file_dir()
  end

  -- IMPORTANT: `:lcd` does NOT reliably influence where `:terminal` starts the
  -- shell (verified: getcwd() reported the target while the shell's
  -- /proc/<pid>/cwd stayed at the old directory).  So cd explicitly inside the
  -- spawned shell and `exec` it, which keeps the process alive — the same
  -- pattern M.spawn_broot uses.
  local shell = vim.o.shell ~= "" and vim.o.shell or (vim.env.SHELL or "sh")
  if dir and dir ~= "" and vim.fn.isdirectory(dir) == 1 then
    vim.cmd(
      "terminal "
        .. shell
        .. " -c "
        .. vim.fn.shellescape("cd " .. dir .. " && exec " .. shell)
    )
  else
    vim.cmd("terminal")
  end
  vim.cmd("startinsert")
end

-- =============================================================================
--  §8  Terminal helpers (existing inline functions, extracted verbatim)
-- =============================================================================

--- Open a vertical-split terminal running a tmux Julia session.
function M.open_julia_terminal()
  vim.cmd("vsplit | terminal tmux new-session -A -s julia_session")
end

--- Open a terminal from the current Oil directory (oil buffer only).
function M.oil_open_terminal()
  local ok, oil = pcall(require, "oil")
  if not ok then
    vim.notify("oil.nvim not loaded", vim.log.levels.WARN)
    return
  end
  local dir = oil.get_current_dir()
  if dir then
    local cmd = string.format("cd %s && exec $SHELL", vim.fn.shellescape(dir))
    vim.cmd("terminal " .. cmd)
  else
    print("Not in an Oil buffer")
  end
end

--- Open a vertical-split terminal (tmux).
function M.open_tmux_vsplit()
  vim.cmd("vsplit | terminal tmux attach || tmux new-session")
end

--- Open a terminal in a vertical split: current buffer on the LEFT, terminal on
--- the RIGHT, and focus the terminal.  The shell starts in the current file's
--- directory.
function M.terminal_vsplit()
  local dir = M.current_file_dir()
  -- vsplit puts the new window to the right (splitright is on).  Set that
  -- window's local cwd (`:lcd`) so the shell starts there, then open a plain
  -- `:terminal` (a bare :terminal launches $SHELL and stays alive).
  vim.cmd("vsplit")
  if dir and dir ~= "" and vim.fn.isdirectory(dir) == 1 then
    pcall(vim.cmd, "lcd " .. vim.fn.fnameescape(dir))
  end
  vim.cmd("terminal")
  vim.cmd("startinsert")
end

--- Open a horizontal-split terminal (tmux).
function M.open_tmux_terminal()
  vim.cmd("terminal tmux")
end

--- Remove all buffers except the current one.
--- Emacs analogue: n/a (convenience), existing `<leader>bo` mapping.
function M.close_other_buffers()
  local current_buf = vim.api.nvim_get_current_buf()
  local buffers = vim.api.nvim_list_bufs()

  for _, buf in ipairs(buffers) do
    if buf ~= current_buf and vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_buf_delete(buf, { force = false })
    end
  end
end

-- =============================================================================
--  §9  Panes glyphs (port of emacs/panes.el — wrap/truncation + divider)
--      Call M.setup_pane_glyphs() once at startup (from options.lua or init.lua).
-- =============================================================================

--- Set the wrap/truncation glyph and window-divider color to match Emacs
--- `panes.el` (accent `·`).
function M.setup_pane_glyphs()
  -- No wrap/truncation indicator glyph (removed per user request).
  vim.opt.showbreak = ""
  -- End-of-buffer fill char is already " " in options.lua; keep it.
  -- vim.opt.fillchars:append({ eob = " " })

  -- Window divider color: light grey fg, invisible bg.  In nvim 0.10+
  -- `VertSplit` is linked to `WinSeparator`, so set the latter (and also
  -- VertSplit for older nvim / explicit overrides).
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#8c8c8c", bg = "none" })
  vim.api.nvim_set_hl(0, "VertSplit", { fg = "#8c8c8c", bg = "none" })
end

-- M.setup_terminal_esc() was moved to config/terminal_autocmds.lua.

-- =============================================================================
--  §10  txm hover — boxed ASCII render of the equation under the cursor
-- =============================================================================

--- Render the LaTeX equation under the cursor using the external `txm` CLI's
--- BOXED output, shown in a floating window.  (Currently UNBOUND — kept as a
--- utility; `<leader>J` is now satty, see §11.)
---
--- Implementation: reuse txm.nvim's own parser to locate the `$...$` math zone
--- containing the cursor, shell out to `txm` (default = boxed), strip the ANSI
--- escapes txm emits unconditionally, and open the result in a floating
--- scratch buffer.
function M.txm_hover()
  local parser = require("txm.parser")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local text = table.concat(lines, "\n")

  -- Cursor position (0-based row for parser offsets).
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  -- Byte offset of the cursor within `text`.
  local offset = 0
  for i = 1, row do
    offset = offset + #lines[i] + 1 -- +1 for the newline
  end
  offset = offset + col

  -- txm.parser.find_latex returns { content, e } per region; it does NOT return
  -- the region's start offset.  Reconstruct each region's start by scanning
  -- forward for its content, then check whether the cursor falls inside it.
  local chosen
  local scan = 1
  for _, r in ipairs(parser.find_latex(text)) do
    local start = text:find(r.content, scan, true)
    if start then
      local finish = start + #r.content
      if offset >= start and offset <= finish then
        chosen = r
        break
      end
      scan = finish + 1
    end
  end

  if not chosen or vim.trim(chosen.content) == "" then
    vim.notify("Not on an equation", vim.log.levels.INFO)
    return
  end

  -- Run txm (boxed by default) and strip ANSI.
  local out = vim.fn.systemlist({ "txm", chosen.content })
  local function strip(s)
    return (s:gsub("\27%[[%d;]*m", ""))
  end
  for i, l in ipairs(out) do
    out[i] = strip(l)
  end

  -- Show in a floating window (same layout as txm.nvim's preview).
  local pad = "    "
  local display = {}
  for _, l in ipairs(out) do
    display[#display + 1] = pad .. l
  end
  table.insert(display, 1, "")
  display[#display + 1] = ""

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, display)
  local width = math.min(vim.fn.max(vim.tbl_map(vim.fn.strdisplaywidth, display)), math.floor(vim.o.columns * 0.8))
  local height = math.min(#display, math.floor(vim.o.lines * 0.8))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width + 4,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    border = "single",
    title = " txm ",
    title_pos = "center",
    style = "minimal",
  })
  vim.bo[buf].modifiable = false
  vim.wo[win].winhighlight = "NormalFloat:Normal,FloatBorder:Normal,FloatTitle:Normal"
  vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = buf })
end

-- =============================================================================
--  §11  math image rendering — render the equation under the cursor to a PNG
--       (pdflatex + magick, doubled density 768, transparent) and open it in
--       satty (fullscreen, scroll/zoom/annotate).  Bound to <leader>J.
-- =============================================================================

--- Render the LaTeX equation under the cursor to a PNG (pdflatex + magick), then
--- return the PNG path (or nil).
function M.render_equation_png()
  -- Find the math node under the cursor via tree-sitter (same nodes the hover
  -- float uses: inline_formula, displayed_equation, math_environment, formula),
  -- so ALL math forms are detected, not just `$...$`.
  local math_node_types = {
    inline_formula = true,
    displayed_equation = true,
    math_environment = true,
    formula = true,
  }
  local function math_at_cursor()
    local ok, parser = pcall(vim.treesitter.get_parser, vim.api.nvim_get_current_buf())
    if not ok or not parser then
      return nil
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row0 = cursor[1] - 1
    local col = cursor[2]
    local found
    parser:for_each_tree(function(tstree)
      if found or not tstree then
        return
      end
      local root = tstree:root()
      local node = root:named_descendant_for_range(row0, col, row0, col + 1)
      local cur = node
      while cur do
        if math_node_types[cur:type()] then
          found = cur
          break
        end
        cur = cur:parent()
      end
      if not found and math_node_types[root:type()] then
        found = root
      end
    end)
    if found then
      return vim.treesitter.get_node_text(found, vim.api.nvim_get_current_buf()), found:type()
    end
    return nil
  end

  local content, node_type = math_at_cursor()
  if not content or vim.trim(content) == "" then
    vim.notify("Not on an equation", vim.log.levels.INFO)
    return nil
  end

  content = vim.trim(content)

  -- Environments (align/equation/matrix/pmatrix/...): keep the raw
  -- \begin{...}...\end{...} body as-is (so `&`/`\` alignment chars stay valid)
  -- and do NOT wrap in \[..\].
  local is_environment = node_type == "math_environment"

  if not is_environment then
    -- Formula: strip the $/$$/\(/\[/\] delimiters and wrap in display math.
    content = content:gsub("^%$+%s*", ""):gsub("%s*%$+$", "")
    content = content:gsub("^\\%[", ""):gsub("\\%]$", "")
    content = content:gsub("^\\%( ", ""):gsub(" \\%)$", "")
  end

  local tmp = vim.fn.tempname()
  local dir = vim.fn.fnamemodify(tmp, ":h")
  local base = vim.fn.fnamemodify(tmp, ":t:r")
  local tex = dir .. "/" .. base .. ".tex"
  local pdf_file = dir .. "/" .. base .. ".pdf"
  local png = dir .. "/" .. base .. ".png"
  vim.fn.mkdir(dir, "p")

  local fg = "FF4400"
  local body = is_environment and content or ("\\[" .. content .. "\\]")
  local tex_src = table.concat({
    "\\documentclass[preview,border=0pt,varwidth,12pt]{standalone}",
    "\\usepackage{amsmath,amssymb,amsfonts,amscd,mathtools,xcolor}",
    "\\begin{document}",
    "{\\Large\\color[HTML]{" .. fg .. "}",
    body,
    "}",
    "\\end{document}",
  }, "\n")

  local f = io.open(tex, "w")
  if not f then
    vim.notify("failed to write temp tex", vim.log.levels.ERROR)
    return nil
  end
  f:write(tex_src)
  f:close()

  -- Compile LaTeX -> PDF, then rasterize PDF -> PNG with DOUBLED density (768)
  -- and a TRANSPARENT background (alpha preserved).
  local cmd = string.format(
    "cd %s && pdflatex -interaction=nonstopmode -halt-on-error -output-directory=%s %s >/dev/null 2>&1 && magick -density 768 -background none %s -trim +repage %s >/dev/null 2>&1",
    vim.fn.shellescape(dir),
    vim.fn.shellescape(dir),
    vim.fn.shellescape(base),
    vim.fn.shellescape(pdf_file),
    vim.fn.shellescape(png)
  )
  vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("math render failed", vim.log.levels.ERROR)
    return nil
  end
  return png
end

--- Open the equation under the cursor in satty (fullscreen, scroll/zoom).
function M.math_image_buffer()
  local png = M.render_equation_png()
  if not png then
    return
  end
  local png_q = vim.fn.shellescape(png)
  local launch
  if vim.fn.executable("satty") == 1 then
    launch = "satty --filename " .. png_q .. " --fullscreen"
  else
    launch = "xdg-open " .. png_q
  end
  vim.fn.system({ "sh", "-c", launch .. " >/dev/null 2>&1 &" })
end

return M
