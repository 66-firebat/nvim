-- =============================================================================
--  cursor.lua — per-mode terminal cursor COLOUR (OSC 12)
--
--  Port of emacs/evil-cursor.el, split in two because nvim offers two separate
--  mechanisms and only one of them can do colour:
--
--    SHAPE + BLINK  -> 'guicursor'  (see lua/config/options.lua)
--    COLOUR         -> this module  (OSC 12, via nvim_ui_send)
--
--  'guicursor' has no colour syntax, and DECSCUSR (the shape escape) proved
--  unreliable under Ghostty, so shape is left entirely to nvim while colour is
--  sent here.  They do not conflict: nvim never emits OSC 12, and this module
--  never emits DECSCUSR.
--
--      normal   -> #ff4400   (accent orange)
--      visual   -> #1bfd9c   (green)
--      insert   -> #d3d3d3   (light grey)
--      terminal -> #d3d3d3   (same as insert — terminal mode is morally insert)
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
-- terminal-job mode (C-\\ C-n / <Esc>) is ambiguous: nvim reports "nt" both
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

--- Cursor COLOUR per nvim mode.
---   color = hex string for OSC 12, or nil to reset to the terminal default
M.styles = {
  -- Default / normal: accent orange.
  normal = { color = "#ff4400" },
  -- Visual / select: green.
  visual = { color = "#1bfd9c" },
  -- Insert / replace / terminal: light grey.
  insert = { color = "#d3d3d3" },
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

--- Send DECSCUSR to set the cursor SHAPE.
--- Only used for TERMINAL buffers: nvim's own shape emission has been disabled
--- for that path (see options.lua / `set t_Ss=`), because nvim was writing its
--- own `ESC[2 q` immediately after ours and overriding it.  For every other
--- buffer 'guicursor' handles the shape natively.
--- DECSCUSR: 0=default 1=blink block 2=block 3=blink underline
---           4=underline 5=blink bar 6=bar
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

  -- Terminal mode: use the INSERT style (grey blinking bar) — while typing in a
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
  send_cursor_color(style.color)

  -- TERMINAL buffers: nvim's shape emission is disabled for this path, so we
  -- send DECSCUSR ourselves (a bar, matching insert).  Everywhere else
  -- 'guicursor' owns the shape and we must NOT interfere.
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype == "terminal" then
    if key == "insert" then
      send_cursor_shape("5") -- blinking bar (matches guicursor blinking)
    else
      send_cursor_shape("1") -- blinking block, matching normal mode
    end
  end
end

--- Restore the terminal's own cursor (colour + shape).
function M.reset()
  send_cursor_color(nil)
  send_cursor_shape("0") -- hand the shape back to the terminal
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

  -- Terminal buffers: `ModeChanged` does NOT reliably fire when entering a
  -- terminal (there is no real "normal -> terminal" text transition), so apply
  -- the INSERT style explicitly whenever we enter / spawn a terminal.  Per
  -- design, terminal mode uses the same cursor as insert mode (grey bar).
  -- Only force the insert style while the terminal JOB actually owns the keys
  -- (mode contains "t").  If you are in terminal-NORMAL mode inside a terminal
  -- buffer (after C-\ C-n / <Esc>) the normal style must apply instead.
  vim.api.nvim_create_autocmd({ "TermEnter", "TermOpen", "BufEnter" }, {
    group = group,
    callback = function(ev)
      if not (ev.buf and vim.api.nvim_buf_is_valid(ev.buf)) then
        return
      end
      if vim.bo[ev.buf].buftype ~= "terminal" then
        return
      end
      vim.schedule(function()
        M.apply(vim.api.nvim_get_mode().mode)
      end)
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
