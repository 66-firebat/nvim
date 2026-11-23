-- =============================================================================
--  jumplist.lua — global persisted jump ring (port of emacs/jumpring.el)
--
--  A SINGLE jump history shared by ALL windows and buffers (unlike Neovim's
--  native per-window jumplist).  Records jumps in every buffer type — normal
--  files, terminals, oil, help — by hooking the explicit jump commands
--  (`f` flash, `;` statuscolumn jump, `s`/`S` search) via `jump.push()`.
--
--  `C-o` / `C-i` navigate the ring backwards/forwards (bind these yourself).
--  The ring is persisted across sessions to a JSON file under
--  `vim.fn.stdpath("state")`, mirroring Emacs' savehist for `evil-jumps-history`.
--
--  API:
--      require("config.jumplist").push()       -- record current position
--      require("config.jumplist").backward()   -- step back  (C-o)
--      require("config.jumplist").forward()    -- step forward (C-i)
-- =============================================================================

local M = {}

-- State file location.  stdpath("state") is ~/.local/state/nvim by default.
local function state_path()
  return vim.fn.stdpath("state") .. "/jumplist.json"
end

-- The ring: a list of entries, newest FIRST.
-- Each entry: { bufnr = <number>, line = <number>, col = <number>, file = <string> }
M.ring = {}

-- Index into M.ring (1-based) of the NEXT entry to jump to when navigating.
-- `M.pos` tracks where we are in the ring during back/forward traversal.
M.pos = 0

-- The "home" position (where the cursor was before we started navigating
-- back with C-o).  Forward (C-i) returns here when pos reaches 0 again.
M.destination = nil

-- Max ring length (Emacs evil-jumps-max-length defaults to 100).
M.max_length = 100

-- =============================================================================
--  Serialization (JSON via vim.json)
-- =============================================================================

local function serialize()
  local data = vim.json.encode(M.ring)
  local ok, err = pcall(function()
    local f = io.open(state_path(), "w")
    if f then
      f:write(data)
      f:close()
    end
  end)
  if not ok then
    vim.notify("jumplist: failed to save: " .. tostring(err), vim.log.levels.WARN)
  end
end

local function deserialize()
  local f = io.open(state_path(), "r")
  if not f then
    return
  end
  local raw = f:read("*a")
  f:close()
  if not raw or raw == "" then
    return
  end
  local ok, decoded = pcall(vim.json.decode, raw)
  if ok and type(decoded) == "table" then
    M.ring = decoded
  end
end

-- =============================================================================
--  Entry construction + filtering
-- =============================================================================

--- Build an entry for the current cursor position.
--- Mirrors emacs `evil--jumps-current-file-name`: for non-file buffers (terminal,
--- oil, dired-analog) we fall back to the buffer name, so terminal/oil jumps are
--- preserved (the exact gap emacs patched `evil--jumps-push` to fix).
local function current_entry()
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  local name = vim.api.nvim_buf_get_name(bufnr)
  local file
  if name and name ~= "" then
    file = name
  else
    -- Non-file buffer: use buffer name (e.g. terminal://..., oil://...).
    file = vim.api.nvim_buf_get_name(bufnr)
    if not file or file == "" then
      file = vim.api.nvim_buf_is_valid(bufnr) and "buffer#" .. bufnr or "?"
    end
  end

  return { bufnr = bufnr, line = row, col = col, file = file }
end

--- Drop entries whose file/path no longer exists (mirrors emacs
--- `evil--jumps-savehist-sync` which filters dead files before saving).
local function filter_dead()
  local live = {}
  for _, e in ipairs(M.ring) do
    if e and e.file and e.file ~= "" then
      -- Buffers that are still loaded are always "live", regardless of file.
      if e.bufnr and vim.api.nvim_buf_is_valid(e.bufnr) then
        table.insert(live, e)
      elseif vim.fn.filereadable(e.file) == 1 or vim.fn.isdirectory(e.file) == 1 then
        table.insert(live, e)
      end
    end
  end
  M.ring = live
end

-- =============================================================================
--  Core API
-- =============================================================================

--- Record the current position onto the ring (newest first).
--- Called before a jump (`f`, `;`, `s`, `S`) so `C-o` can return here.
function M.push()
  local entry = current_entry()
  -- Avoid duplicate consecutive entries (same buffer+line+col).
  if M.ring[1]
    and M.ring[1].bufnr == entry.bufnr
    and M.ring[1].line == entry.line
    and M.ring[1].col == entry.col
  then
    return
  end

  table.insert(M.ring, 1, entry)
  if #M.ring > M.max_length then
    M.ring[#M.ring] = nil
  end
  -- After a jump, the cursor sits at the DESTINATION (not in the ring).  The
  -- ring's newest entry is where we came FROM, so pos=0 means "at destination".
  -- backward() then advances to pos=1 (ring[1] = origin) first.
  M.pos = 0
end

--- Restore cursor to the given entry, recreating/opening its buffer if needed.
local restore

--- Step backward through the ring (Emacs `C-o` / `evil-jump-backward`).
function M.backward()
  if M.pos >= #M.ring then
    vim.notify("No previous jump", vim.log.levels.INFO)
    return
  end
  -- On the first backward step, remember the current (destination) position so
  -- that C-i can later return to it.
  if M.pos == 0 then
    M.destination = current_entry()
  end
  -- Advance to the next-older entry and jump to it.
  M.pos = M.pos + 1
  M.jump_to(M.ring[M.pos])
end

--- Step forward through the ring (Emacs `C-i` / `evil-jump-forward`).
function M.forward()
  if M.pos <= 0 then
    vim.notify("No next jump", vim.log.levels.INFO)
    return
  end
  M.pos = M.pos - 1
  if M.pos == 0 then
    -- Return to the destination we started from.
    if M.destination then
      restore(M.destination)
    else
      vim.notify("No next jump", vim.log.levels.INFO)
    end
    return
  end
  M.jump_to(M.ring[M.pos])
end

--- Restore cursor to the given entry, recreating/opening its buffer if needed.
restore = function(entry)
  local bufnr = entry.bufnr
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_set_current_buf(bufnr)
  elseif entry.file and (vim.fn.filereadable(entry.file) == 1) then
    vim.cmd("edit " .. vim.fn.fnameescape(entry.file))
  elseif entry.file and entry.file:match("^buffer#") then
    -- Dead unnamed buffer we can't restore; skip.
    return false
  else
    return false
  end

  local line_count = vim.api.nvim_buf_line_count(0)
  local line = math.min(entry.line or 1, line_count)
  local col = entry.col or 0
  vim.api.nvim_win_set_cursor(0, { line, math.max(0, col) })
  return true
end

M.jump_to = restore

-- =============================================================================
--  Session persistence
-- =============================================================================

--- Load the ring from disk on startup, filtering out dead files.
function M.load()
  deserialize()
  filter_dead()
  -- After load, cursor is at "current" (destination), ring holds past positions.
  M.pos = 0
end

--- Save the ring to disk (filter dead files first).
function M.save()
  filter_dead()
  serialize()
end

--- Set up autocmds: restore on VimEnter, save on VimLeavePre.
function M.setup()
  local group = vim.api.nvim_create_augroup("Jumplist", { clear = true })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
      M.load()
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      M.save()
    end,
  })
end

return M
