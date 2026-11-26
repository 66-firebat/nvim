-- =============================================================================
--  terminal_autocmds.lua — every terminal-related autocmd, in one place
-- =============================================================================
--  Centralises autocmds driven by TermOpen / TermEnter / TermClose / terminal
--  foreground-program tracking.  See the per-autocmd comments for the design
--  rationale of each (several older attempts were removed and are documented as
--  "REMOVED" below so the history isn't lost).
--
--  Call require("config.terminal_autocmds").setup() once (from init.lua).
--
--  Modules previously owning these autocmds now expose small public helpers so
--  the terminal logic can live here without reaching into their local state:
--    * config.mru     -> M.touch / M.refresh_terminal_prog / M.invalidate_terminal_prog
--    * config.cursor  -> M.apply("t")
-- =============================================================================

local M = {}

-- =============================================================================
--  Windows / buffers
-- =============================================================================

local function setup_autoclose()
  -- Auto-close a terminal buffer when its job exits, so you don't see the
  -- "[Process exited N]" message.  Uses event.buf (the terminal buffer) so it
  -- never touches the user's file buffer.
  --
  -- REMOVED (older attempts, kept for history):
  --   * a TermClose autocmd that switched to the alternate buffer + `bd!` — it
  --     could switch away from the user's file.
  --   * a TermClose autocmd that did `vim.cmd("bd!")` with no buffer arg — it
  --     deleted the CURRENT buffer (the user's file) instead of the terminal.
  --   * a BufLeave autocmd that did `vim.cmd("bd!")` — same wrong-buffer bug.
  vim.api.nvim_create_autocmd("TermClose", {
    group = vim.api.nvim_create_augroup("TerminalAutoClose", { clear = true }),
    callback = function(event)
      vim.schedule(function()
        if event.buf and vim.api.nvim_buf_is_valid(event.buf) then
          pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
        end
      end)
    end,
  })
end

-- =============================================================================
--  Styling / appearance
-- =============================================================================

local function setup_styling()
  -- Enables all signcolumn/statuscolumn features in terminal buffers.
  --
  -- SETS:
  --   * filetype -> "broot" (if the buffer name contains "broot") or "terminal",
  --     so the tab-line groups terminals correctly.
  --   * number/relativenumber -> on (statuscol needs a "canvas" to draw on).
  --   * signcolumn -> "yes" (so it doesn't collapse).
  --   * statuscolumn -> inherited from the current global value (TermOpen
  --     sometimes clears it otherwise).
  --   * startinsert -> start in TERMINAL-JOB mode so the terminal is usable.
  --
  -- REMOVED (older attempt, kept for history):
  --   * a TermOpen autocmd that cleared `statuscolumn` to hide the sign column.
  --   * a TermOpen autocmd that only did `startinsert` + `vim.bo.filetype="bash"`
  --     (the filetype override was wrong — it broke tab-line terminal grouping).
  vim.api.nvim_create_autocmd("TermOpen", {
    group = vim.api.nvim_create_augroup("terminal-style-sync", { clear = true }),
    callback = function()
      local name = vim.api.nvim_buf_get_name(0)
      vim.bo.filetype = name:match("broot") and "broot" or "terminal"
      vim.opt_local.number = true
      vim.opt_local.relativenumber = true
      vim.opt_local.signcolumn = "yes"
      vim.opt_local.statuscolumn = vim.opt.statuscolumn:get()
      vim.cmd("startinsert")
    end,
  })
end

-- =============================================================================
--  Cursor appearance (config.cursor)
-- =============================================================================

local function setup_cursor()
  -- Terminal buffers: `ModeChanged` does NOT reliably fire when entering a
  -- terminal (no real "normal -> terminal" text transition), and `BufEnter` into
  -- a terminal reports the ambiguous "nt" mode, so force the INSERT cursor style
  -- explicitly whenever we enter / spawn a terminal.  Terminals use the same
  -- cursor as insert mode (grey bar).  Only force it while the terminal JOB
  -- actually owns the keys (live mode contains "t").
  --
  -- NOTE: intentionally REMOVED — an older handler did `startinsert` whenever a
  -- terminal became current in Terminal-Normal mode, forcing Terminal-Job mode on
  -- every BufEnter/WinEnter.  It broke scroll-up in fullscreen TUIs (pi, htop,
  -- less, …) because `startinsert` re-enters Terminal-Job mode and re-follows the
  -- terminal cursor, snapping the viewport back to the TUI's home/top row on each
  -- alt-screen redraw.  Entering a terminal still starts in job mode via the
  -- TermOpen `startinsert` above; a deliberate drop to normal mode (<Esc>/<C-;>)
  -- is now left alone so you can scroll freely.
  vim.api.nvim_create_autocmd({ "TermEnter", "TermOpen" }, {
    group = vim.api.nvim_create_augroup("TerminalCursor", { clear = true }),
    callback = function(ev)
      local cursor = require("config.cursor")
      if ev.buf and vim.api.nvim_buf_is_valid(ev.buf)
        and vim.bo[ev.buf].buftype == "terminal"
        and vim.api.nvim_get_mode().mode:find("t", 1, true) then
        cursor.apply("t")
      end
    end,
  })
end

-- =============================================================================
--  MRU membership + foreground-program tracking (config.mru)
-- =============================================================================

-- Refresh the terminal's foreground-program cache and redraw the
-- statusline/tabline if it changed.
local function maybe_refresh(bufnr)
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buftype == "terminal" then
    local mru = require("config.mru")
    if mru.refresh_terminal_prog(bufnr) then
      vim.cmd("redrawstatus!")
      vim.cmd("redrawtabline")
    end
  end
end

local function setup_mru()
  -- A terminal becomes an MRU member only once TermOpen fires (its buftype is
  -- still empty during the BufEnter that creates it), so touch it here to make
  -- the freshly spawned terminal rank #1 immediately.
  vim.api.nvim_create_autocmd("TermOpen", {
    group = vim.api.nvim_create_augroup("TerminalMRUTrack", { clear = true }),
    callback = function(ev)
      local mru = require("config.mru")
      mru.touch(ev.buf)
      mru.invalidate_terminal_prog(ev.buf)
      -- The previous winbar render may already have happened (before this buffer
      -- was tracked), leaving a stale "?" rank on screen.  Force the winbars to
      -- re-evaluate now that the terminal has a rank.
      vim.schedule(function()
        pcall(vim.api.nvim__redraw, { winbar = true, flush = true })
      end)
    end,
  })

  -- Refresh on entry into a terminal, and when we come back to the window.
  vim.api.nvim_create_autocmd({ "TermEnter", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("TerminalMRURefresh", { clear = true }),
    callback = function(ev)
      maybe_refresh(ev.buf)
    end,
  })

  vim.api.nvim_create_autocmd("FocusGained", {
    group = vim.api.nvim_create_augroup("TerminalMRURefresh", { clear = true }),
    callback = function()
      maybe_refresh(vim.api.nvim_get_current_buf())
    end,
  })

  vim.api.nvim_create_autocmd("TermClose", {
    group = vim.api.nvim_create_augroup("TerminalMRURefresh", { clear = true }),
    callback = function(ev)
      require("config.mru").invalidate_terminal_prog(ev.buf)
    end,
  })

  -- ── poll: ONLY the focused window's terminal ────────────────────────────
  -- One timer keyed to the focused window; when its tpgid changes, force an
  -- immediate redraw so every winbar updates.
  local poll_interval = require("config.mru").term_poll_interval
  local timer = assert((vim.uv or vim.loop).new_timer())
  timer:start(
    poll_interval,
    poll_interval,
    vim.schedule_wrap(function()
      local bufnr = vim.api.nvim_get_current_buf()
      if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      -- Only poll while actually sitting in a terminal buffer.
      if vim.bo[bufnr].buftype ~= "terminal" then
        return
      end
      local mru = require("config.mru")
      if mru.refresh_terminal_prog(bufnr) then
        vim.cmd("redrawstatus!")
        vim.cmd("redrawtabline")
      end
    end)
  )
end

-- =============================================================================
--  OSC 7 cwd tracking (shell -> nvim)
-- =============================================================================

local function setup_osc7_dir()
  -- When the shell emits an OSC 7 dir-change sequence (`\e]7;file://<host><path>\e\\`),
  -- nvim fires `TermRequest` with the raw sequence in `ev.data.sequence`.
  vim.api.nvim_create_autocmd("TermRequest", {
    group = vim.api.nvim_create_augroup("TerminalOsc7Dir", { clear = true }),
    desc = "Track shell cwd via OSC 7",
    callback = function(ev)
      local seq = ev.data.sequence
      if not (seq and seq:match("^\027%]7;")) then
        return
      end

      -- Strip the `\e]7;file://<host>` prefix, then any trailing ST/BEL.
      local dir = seq
        :gsub("^\027%]7;file://[^/]*", "")
        :gsub("\027\\$", "")
        :gsub("\a$", "")

      if vim.fn.isdirectory(dir) == 0 then
        vim.notify("OSC 7: invalid dir: " .. dir, vim.log.levels.WARN)
        return
      end

      vim.b[ev.buf].osc7_dir = dir
      if vim.api.nvim_get_current_buf() == ev.buf then
        -- Use :cd (global), not :lcd.  Fugitive and other git tooling resolve
        -- the repo from getcwd() (global), so a window-local :lcd would leave
        -- them pointing at the stale launch directory.
        vim.cmd.cd(vim.fn.fnameescape(dir))
      end
    end,
  })
end

-- =============================================================================
--  <Esc> forwarding (terminal normal mode)
-- =============================================================================

local function setup_terminal_esc()
  -- Forward ESC to the terminal's job when in a terminal buffer's NORMAL mode.
  -- Installed once per terminal via TermOpen, scoped with `buffer = <buf>` so it
  -- only fires inside that terminal buffer and never touches regular buffers.
  vim.api.nvim_create_autocmd("TermOpen", {
    group = vim.api.nvim_create_augroup("TerminalEscForward", { clear = true }),
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

-- =============================================================================
--  Setup
-- =============================================================================

function M.setup()
  setup_autoclose()
  setup_styling()
  setup_cursor()
  setup_mru()
  setup_terminal_esc()
  setup_osc7_dir()
end

return M
