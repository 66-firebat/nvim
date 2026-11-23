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

--- Close the current window; no-op if it is the last window in the tab.
--- Emacs: `my/smart-close-window` (M-W)
function M.smart_close_window()
  if vim.fn.winnr("$") <= 1 then
    vim.notify("Last window in tab, doing nothing", vim.log.levels.INFO)
    return
  end
  vim.cmd("close")
end

-- =============================================================================
--  §2  Buffer navigation
-- =============================================================================

--- Jump to a non-excluded buffer selected by numeric index.
--- The digit typed is used to seed the completion/prompt.
--- Emacs: `SPC b 0-9` -> `my/buffer-goto`
function M.buffer_by_index()
  local listed = vim.fn.getbufinfo({ buflisted = 1 })
  if #listed == 0 then
    vim.notify("No listed buffers", vim.log.levels.INFO)
    return
  end

  -- Exclude scratch-ish/unnamed buffers that are not useful to jump to.
  local candidates = {}
  for _, info in ipairs(listed) do
    if info.name ~= "" then
      table.insert(candidates, info)
    end
  end
  if #candidates == 0 then
    vim.notify("No named buffers", vim.log.levels.INFO)
    return
  end

  -- Build "N: name" display strings (1-based, matching Emacs behavior loosely).
  local display = {}
  for i, info in ipairs(candidates) do
    local short = vim.fn.fnamemodify(info.name, ":t")
    display[i] = string.format("%d: %s", i, short)
  end

  vim.ui.select(display, {
    prompt = "buffer: ",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if not choice then
      return
    end
    local idx = tonumber(choice:match("^(%d+):"))
    if idx and candidates[idx] and vim.api.nvim_buf_is_valid(candidates[idx].bufnr) then
      vim.cmd("buffer " .. candidates[idx].bufnr)
    end
  end)
end

--- Switch to the alternate (most recently viewed) buffer, toggling A<->B.
--- Emacs: `SPC b r` -> `my/switch-to-other-buffer`
function M.switch_previous_buffer()
  local alt = vim.fn.bufnr("#")
  if alt == -1 or not vim.api.nvim_buf_is_valid(alt) then
    vim.notify("No previous buffer available", vim.log.levels.INFO)
    return
  end
  vim.cmd("buffer " .. alt)
end

-- =============================================================================
--  §3  File managers / terminals
-- =============================================================================

--- Spawn `broot` in a terminal, rooted at the current file/project dir.
--- Emacs: `M-e` -> `my/broot-default-directory` (broot branch)
function M.open_broot()
  -- Change directory to the current buffer's directory if possible.
  pcall(vim.cmd, "cd %:h")

  local ok, _ = pcall(vim.cmd, "terminal broot")
  if not ok then
    vim.cmd("terminal broot ~")
  end
  vim.cmd("startinsert")
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
  if dir == "" or not vim.fn.isdirectory(dir) then
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

--- Fuzzy-search the current buffer's lines, seed the `/` register.
--- Emacs: `s` -> `my/consult-line-with-jump`
function M.search_line_jump()
  push_jump()
  Snacks.picker.lines()
end

--- Ripgrep the project (root = cwd), seed the `/` register.
--- Emacs: `S` -> `my/consult-ripgrep-with-jump`
function M.search_ripgrep_jump()
  push_jump()
  Snacks.picker.grep({ cwd = vim.fn.getcwd() })
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

--- Return the lowest unused terminal index (1, 2, 3, ...), scanning buffer
--- names for the `<N>` prefix.
--- Emacs: `my/ghostel-next-available`
function M.next_terminal_index()
  local i = 1
  while true do
    local target = string.format("%d ", i)
    local found = false
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name:match("^" .. vim.pesc(target)) then
        found = true
        break
      end
    end
    if not found then
      return i
    end
    i = i + 1
  end
end

--- Spawn a numbered terminal named "<N>  terminal".
--- Emacs: `M-t` -> `my/ghostel-new-dispatch` (indexed naming only).
function M.numbered_terminal()
  local index = M.next_terminal_index()
  local label = string.format("%d  terminal", index)

  vim.cmd("terminal")
  -- Rename the freshly created terminal buffer (last buffer is the terminal).
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(bufnr, label)
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

  -- Window divider color (orange accent), already set in highlights.lua, but
  -- ensure it is present for clarity.
  vim.api.nvim_set_hl(0, "VertSplit", { fg = "#ff4400", bg = "none" })
end

return M
