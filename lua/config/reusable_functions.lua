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
    -- Only one window: split right and show the most-recently-viewed buffer.
    local alt = vim.fn.bufnr("#")
    if alt == -1 or not vim.api.nvim_buf_is_valid(alt) then
      alt = vim.api.nvim_get_current_buf()
    end
    vim.cmd("vsplit")
    vim.api.nvim_win_set_buf(0, alt)
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

-- Buffer-local variable on an oil buffer, recording the buffer oil was spawned
-- from:  b:oil_source = <bufnr>
local OIL_SOURCE_VAR = "oil_source"

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
---   buffer oil was spawned from (tracked via `b:oil_source`).
--- - Otherwise: open oil rooted at the focused file's directory, recording the
---   current buffer as the origin so the toggle can return to it.
function M.oil_toggle()
  local bufnr = vim.api.nvim_get_current_buf()

  if M.is_oil(bufnr) then
    -- Close the oil buffer.  We still RECORD the source on open (b:oil_source)
    -- but do NOT force a return to it here — callers may use the tracked
    -- origin buffer themselves.  Just delete and let nvim pick the buffer.
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
  local ok = pcall(vim.cmd, "Oil " .. vim.fn.fnameescape(dir))
  if not ok then
    pcall(vim.cmd, "Oil")
  end
  local oil_buf = vim.api.nvim_get_current_buf()
  if M.is_oil(oil_buf) then
    vim.api.nvim_buf_set_var(oil_buf, OIL_SOURCE_VAR, source)
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
        local q = picker.input and picker.input.filter and picker.input.filter.search
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
    local score, path = line:match("^(%d+%.?%d*)%s+(.+)$")
    if path then
      table.insert(results, { score = tonumber(score), path = path })
    end
  end
  return results
end

--- Zoxide directory travel.
--- In a terminal buffer: `cd` the terminal's shell to the selected directory.
--- In any other buffer: open Oil at the selected directory.
--- Emacs: `M-z` -> `my/zoxide-travel-dispatch`
function M.zoxide_travel()
  local results = M.zoxide_query("")

  local items = {}
  for _, r in ipairs(results) do
    table.insert(items, string.format("%s  %s", r.score, r.path))
  end

  if #items == 0 then
    vim.notify("No zoxide entries", vim.log.levels.INFO)
    return
  end

  vim.ui.select(items, {
    prompt = "󰡦 : ",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if not choice then
      return
    end
    local path = choice:match("%d+%.?%d*%s+(.+)$") or choice:match("%s+(.+)$")
    if not path then
      return
    end
    path = vim.trim(path)

    if vim.bo.buftype == "terminal" then
      -- cd the terminal's shell.
      local chan = vim.b.terminal_job_id
      if chan then
        vim.api.nvim_chan_send(chan, "cd " .. vim.fn.shellescape(path) .. " && clear\n")
      else
        vim.notify("No terminal job id", vim.log.levels.WARN)
      end
    else
      require("oil").open(path)
    end
  end)
end

-- =============================================================================
--  §7  Numbered terminal (port of emacs/ghostfire.el `my/ghostel-new-dispatch`
--      indexed naming, without OSC 133 live-relabel)
-- =============================================================================

--- Return the lowest unused numbered-terminal index (1, 2, 3, ...).
--- Scans terminal buffers tagged with `b:numbered_terminal_index` (set by
--- `numbered_terminal`).  Emacs: `my/ghostel-next-available`.
function M.next_terminal_index()
  local used = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local ok, idx = pcall(vim.api.nvim_buf_get_var, bufnr, "numbered_terminal_index")
    if ok and idx then
      used[idx] = true
    end
  end
  local i = 1
  while used[i] do
    i = i + 1
  end
  return i
end

--- Spawn a numbered terminal named "<N>  terminal", tagged with a buffer-local
--- `numbered_terminal_index` so index reuse is reliable.
--- Emacs: `M-t` -> `my/ghostel-new-dispatch` (indexed naming only).
function M.numbered_terminal()
  local index = M.next_terminal_index()
  local label = string.format("%d  terminal", index)

  vim.cmd("terminal")
  local bufnr = vim.api.nvim_get_current_buf()
  -- Tag with the index (robust; independent of the buffer name).
  vim.api.nvim_buf_set_var(bufnr, "numbered_terminal_index", index)
  -- Rename using a `term://<label>` scheme so nvim keeps it as a non-file name
  -- (a bare relative name would be resolved against cwd into an absolute path).
  pcall(vim.api.nvim_buf_set_name, bufnr, "term://" .. label)
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

--- Forward ESC to the terminal's job when in a terminal buffer's NORMAL mode.
--  Installed once per terminal via TermOpen, scoped with `buffer = <buf>` so it
--  only fires inside that terminal buffer and never touches regular file buffers.
--  Call M.setup_terminal_esc() once at startup.
function M.setup_terminal_esc()
  local augroup = vim.api.nvim_create_augroup("TerminalEscForward", { clear = true })
  vim.api.nvim_create_autocmd("TermOpen", {
    group = augroup,
    desc = "Forward Esc to the terminal from normal mode",
    callback = function(args)
      local bufnr = args.buf
      vim.keymap.set("n", "<Esc>", function()
        local chan = vim.api.nvim_get_option_value("channel", { buf = bufnr })
        if chan and chan > 0 then
          vim.api.nvim_chan_send(chan, "\27")
        end
      end, { buffer = bufnr, desc = "Send Esc to terminal" })
    end,
  })
end

return M
