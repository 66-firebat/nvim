-- =============================================================================
--  cursor.lua — per-mode terminal cursor COLOUR (OSC 12) + SHAPE (DECSCUSR)
--
--  Port of emacs/evil-cursor.el, split in two because nvim offers two separate
--  mechanisms and only one of them can do colour:
--
--    SHAPE + BLINK  -> DECSCUSR (this module, via nvim_ui_send)
--    COLOUR         -> OSC 12    (this module, via nvim_ui_send)
--
--  'guicursor' is set to "" in lua/config/options.lua, so nvim does NOT emit
--  its own cursor-shape escapes.  That makes THIS module the sole writer of
--  DECSCUSR, so our shapes stick (see BUGS.md #1 for why 'guicursor' t: is
--  ignored and why we must own the terminal-mode shape ourselves).
--
--      normal   -> block, #ff4400   (accent orange)
--      visual   -> block, #1bfd9c   (green)
--      insert   -> bar,   #d3d3d3   (light grey)
--      terminal -> bar,   #d3d3d3   (same as insert — terminal mode is morally insert)
--
--  Blink is intentionally OFF: we use the STEADY DECSCUSR variants (2 = block,
--  6 = bar) so the cursor does not blink regardless of what the terminal
--  defaults to.
--
--  HOW IT WORKS
--  `vim.api.nvim_ui_send()` (nvim >= 0.12) writes raw bytes straight to the TUI
--  host terminal — the equivalent of Emacs' `send-string-to-terminal`, and the
--  documented way to talk to the outer terminal (`io.stdout:write()` and
--  `nvim_chan_send()` are wrong for a TUI; see :h nvim_ui_send()).
--
--  TERMINAL-MODE CAVEAT
--  nvim reports terminal-JOB mode and terminal-NORMAL mode as the identical
--  string "nt", so this module cannot tell them apart.  Leaving the terminal job
--  is therefore handled in keymaps.lua (`exit_terminal_mode`), which calls
--  `apply("n")` directly from the <Esc> / <C-;> mappings.
--
--  API:
--      require("config.cursor").setup()        -- install the autocmds
--      require("config.cursor").apply(mode)    -- apply a colour explicitly
--      require("config.cursor").reset()        -- restore the terminal default
-- =============================================================================

local M = {}

-- When set, the next ModeChanged-driven colour update is skipped.  Leaving
-- terminal-job mode (C-\ C-n / <Esc>) is ambiguous: nvim reports "nt" both
-- before and after, so the ModeChanged handler would re-apply the INSERT colour
-- and immediately undo the mapping's `apply("n")`.  keymaps.lua calls
-- `M.suppress_next()` before applying the normal colour to break that race.
local suppress_next = false

--- Skip the next ModeChanged colour update (used when leaving terminal mode).
function M.suppress_next()
  suppress_next = true
end

-- =============================================================================
--  §1  Style table
-- =============================================================================

--- DECSCUSR cursor-shape codes (`CSI Ps SP q`).
--- Even numbers are steady, odd numbers blink; 0 = terminal default.
M.SHAPE = {
  default = "0",        -- terminal default
  block_blink = "1",    -- blinking block
  block = "2",          -- steady block (box)
  underline_blink = "3",
  underline = "4",
  bar_blink = "5",      -- blinking vertical bar
  bar = "6",            -- steady vertical bar
}

--- Cursor appearance per nvim mode.
---   color = hex string for OSC 12, or nil to reset to the terminal default
---   shape = key into M.SHAPE
M.styles = {
  -- Default / normal: accent orange, steady block (box).
  normal = { color = "#ff4400", shape = "block" },
  -- Visual / select: green, steady block (box).
  visual = { color = "#1bfd9c", shape = "block" },
  -- Insert / replace / terminal: light grey, steady bar.
  insert = { color = "#d3d3d3", shape = "bar" },
}

-- =============================================================================
--  §2  Terminal escape emitters
-- =============================================================================

--- Send OSC 12 to set the cursor colour, or OSC 112 to reset it.
---@param color string|nil
local function send_cursor_color(color)
  local seq
  if color then
    seq = "\27]12;" .. color .. "\7"
  else
    seq = "\27]112\7"
  end
  pcall(vim.api.nvim_ui_send, seq)
end

--- Send DECSCUSR to set the cursor shape (see M.SHAPE).
--- Note the literal SPACE before `q` — required by the protocol.
---@param code string
local function send_cursor_shape(code)
  pcall(vim.api.nvim_ui_send, "\27[" .. code .. " q")
end

-- =============================================================================
--  §3  Public API
-- =============================================================================

--- Return the style key ("normal" | "visual" | "insert") for an nvim mode().
---@param mode string
---@return string
local function style_for_mode(mode)
  -- mode() may be a multi-char string like "no", "nov", "niI", "cv", or "nt"
  -- (the "n" there is the no-mouse flag, not normal mode).
  local first = mode:sub(1, 1)

  -- Terminal mode: use the INSERT style (grey bar) — while typing in a
  -- terminal you are effectively in insert mode, so this mirrors insert.
  -- NOTE: mode() reports terminal mode as "nt" (the leading "n" is the
  -- no-mouse flag), so test for "t" ANYWHERE in the string, not just first char.
  if mode:find("t", 1, true) then
    return "insert"
  end

  if first == "i" or first == "R" then
    return "insert"          -- insert + replace
  elseif first == "v" or first == "V" or first == "\22" or first == "s"
    or mode:sub(1, 2) == "no" or mode:sub(1, 2) == "ni" or first == "c" then
    -- visual, select, operator-pending, and cmdline all read as "visual"
    return "visual"
  end
  return "normal"
end

--- Apply the cursor appearance for a given nvim mode string.
---@param mode string|nil mode() value; defaults to the current mode
function M.apply(mode)
  mode = mode or vim.api.nvim_get_mode().mode
  local key = style_for_mode(mode)
  local style = M.styles[key] or M.styles.normal
  -- COLOUR via OSC 12.
  send_cursor_color(style.color)
  -- SHAPE via DECSCUSR.  'guicursor' is empty (options.lua), so nvim emits no
  -- shape of its own and ours is the only one sent.
  send_cursor_shape(M.SHAPE[style.shape] or M.SHAPE.default)
end

--- Restore the terminal's own cursor (colour + shape).
function M.reset()
  send_cursor_color(nil)
  send_cursor_shape(M.SHAPE.default)
end

-- =============================================================================
--  §4  Setup
-- =============================================================================

--- Install the mode-change autocmds.  Call once (from init.lua).
function M.setup()
  local group = vim.api.nvim_create_augroup("CursorAppearance", { clear = true })

  -- ModeChanged fires with "old:new" (e.g. "n:i").  React to the NEW mode.
  --
  -- We read the LIVE mode with `vim.api.nvim_get_mode().mode` rather than
  -- trusting `ev.match`'s new-mode field, and defer one tick so nvim has settled
  -- into the new mode before we query it.
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    callback = function(ev)
      local new_mode = ev.match:match(":(.*)$") or ""

      -- Cmdline/cmdwin churn is noisy and not a "real" cursor state; skip it to
      -- avoid spamming the terminal with escapes.
      if new_mode:sub(1, 1) == "c" then
        return
      end

      -- Leaving terminal-job mode is handled by the `t`-mode keymaps in
      -- keymaps.lua (they call M.suppress_next() then apply("n")).  Consume the
      -- flag here so this handler does not immediately undo that with the
      -- still-ambiguous "nt" live mode.
      if suppress_next then
        suppress_next = false
        return
      end

      vim.schedule(function()
        M.apply(vim.api.nvim_get_mode().mode)
      end)
    end,
  })

  -- Re-apply the cursor EVERY time we enter a buffer, so shape + colour stay
  -- aligned with the buffer's mode.  This fixes the stale-shape case where the
  -- cursor is wrong after switching into a new buffer (e.g. the terminal's
  -- DECSCUSR or a prior mode left the shape inconsistent).  Defer one tick so
  -- the live mode reflects the buffer we just entered.
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
      vim.schedule(function()
        M.apply()
      end)
    end,
  })

  -- Terminal buffers: `ModeChanged` does NOT reliably fire when entering a
  -- terminal (there is no real "normal -> terminal" text transition), and
  -- `BufEnter` into a terminal reports the ambiguous "nt" mode, so force the
  -- INSERT style explicitly whenever we enter / spawn a terminal.  Per design,
  -- terminal mode uses the same cursor as insert mode (grey bar).  Only force
  -- the insert style while the terminal JOB actually owns the keys (mode
  -- contains "t"), otherwise the normal style must apply.
  vim.api.nvim_create_autocmd({ "TermEnter", "TermOpen" }, {
    group = group,
    callback = function(ev)
      if ev.buf and vim.api.nvim_buf_is_valid(ev.buf)
        and vim.bo[ev.buf].buftype == "terminal"
        and vim.api.nvim_get_mode().mode:find("t", 1, true) then
        M.apply("t")
      end
    end,
  })

  -- Force TERMINAL-NORMAL mode whenever a terminal buffer becomes current
  -- (e.g. Alt+w shows an already-open terminal via `nvim_win_set_buf`).
  -- `vim.fn.mode()` returns "t" in Terminal-Job mode and "n" in
  -- Terminal-Normal mode, so we `stopinsert` whenever a terminal buffer is
  -- current but still in job (insert) mode.  The <Esc>/<C-;> mappings from
  -- keymaps.lua are unaffected: those already produce normal mode, and this
  -- autocmd only runs on BufEnter/WinEnter, not on mode changes.
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = group,
    callback = function()
      if vim.bo.buftype == "terminal" and vim.fn.mode() == "t" then
        vim.schedule(function()
          if vim.bo.buftype == "terminal" and vim.fn.mode() == "t" then
            vim.cmd("stopinsert")
          end
        end)
      end
    end,
  })

  -- Leaving nvim: hand the cursor back to the terminal so Ghostty isn't left
  -- showing (e.g.) the grey insert bar after you quit.
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      M.reset()
    end,
  })

  -- VimEnter: nvim may have started in a non-normal mode (e.g. -c 'startinsert');
  -- otherwise normalise to the current mode so we begin in a known state.
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
      vim.schedule(function()
        M.apply()
      end)
    end,
  })
end

return M
