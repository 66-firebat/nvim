-- =============================================================================
--  cursor.lua — per-mode terminal cursor colour & shape (OSC / DECSCUSR)
--
--  Port of emacs/evil-cursor.el.  When nvim runs inside a terminal that supports
--  OSC 12 (cursor colour) and DECSCUSR (cursor shape), this changes the visible
--  cursor on every mode change:
--
--      normal  -> hollow block, #ff4400   (reset: Ghostty's `cursor-style`)
--      visual  -> underline,    #1bfd9c
--      insert  -> bar,          #d3d3d3
--
--  All three BLINK (DECSCUSR 1/3/5 are the blinking variants).
--
--  HOW IT WORKS
--  `vim.api.nvim_ui_send()` (nvim >= 0.12) writes raw bytes straight to the TUI
--  host terminal — the equivalent of Emacs' `send-string-to-terminal`.  This is
--  the ONLY correct way to talk to the outer terminal: `io.stdout:write()` and
--  `nvim_chan_send()` are wrong for a TUI (see :h nvim_ui_send()).
--
--  IMPORTANT — interaction with 'guicursor'
--  options.lua sets `vim.o.guicursor = ""`, which stops nvim emitting its own
--  cursor-shape escapes.  That is INTENTIONAL and compatible: we are the only
--  thing writing cursor escapes.  Do not set a non-empty 'guicursor' as well,
--  or nvim's escapes will fight ours.
--
--  IMPORTANT — hollow block is not addressable by DECSCUSR
--  The protocol has no code for a hollow block; Ghostty implements it as a
--  config-only style (`cursor-style = block_hollow`) and reports it as
--  DECSCUSR 1/2.  So normal mode sends **DECSCUSR 0** ("terminal default"),
--  which Ghostty restores to the style from its config file.  That is why the
--  Ghostty config must keep `cursor-style = block_hollow` for this to look
--  right (see git_repositories/ghostty/config).
--
--  API:
--      require("config.cursor").setup()        -- install the autocmds
--      require("config.cursor").apply(mode)    -- apply a style explicitly
--      require("config.cursor").reset()        -- restore terminal defaults
-- =============================================================================

local M = {}

-- =============================================================================
--  §1  Style table
-- =============================================================================

--- DECSCUSR cursor-shape codes (`CSI Ps SP q`).
--- Even numbers are steady, odd numbers blink; 0 = terminal default.
M.SHAPE = {
  default = "0", -- terminal default (Ghostty: `cursor-style`)
  block_blink = "1",
  block = "2",
  underline_blink = "3",
  underline = "4",
  bar_blink = "5",
  bar = "6",
}

--- Cursor appearance per nvim mode.
---   color = hex string for OSC 12, or nil to reset to the terminal default
---   shape = key into M.SHAPE
M.styles = {
  -- Default: Ghostty's own hollow-block style, your accent colour.
  normal = { color = "#ff4400", shape = "default" },
  -- Visual / select: green underline.
  visual = { color = "#1bfd9c", shape = "underline_blink" },
  -- Insert / replace: light-grey bar.
  insert = { color = "#d3d3d3", shape = "bar_blink" },
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
  -- mode() may be a multi-char string like "no", "nov", "niI", "cv", ...
  local first = mode:sub(1, 1)
  if first == "i" or first == "R" then
    return "insert"          -- insert + replace
  elseif first == "v" or first == "V" or first == "\22" or mode:sub(1, 1) == "s"
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
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    callback = function(ev)
      local new_mode = ev.match:match(":(.*)$") or ""
      -- Cmdline/cmdwin churn is noisy and not a "real" cursor state; skip it to
      -- avoid spamming the terminal with escapes.
      if new_mode:sub(1, 1) == "c" then
        return
      end
      M.apply(new_mode)
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
