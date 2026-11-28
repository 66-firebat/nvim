-- =============================================================================
--  keymaps.lua — key bindings ONLY
--
--  This file contains ONLY `vim.keymap.set(...)` bind lines.  Every custom Lua
--  function lives in `lua/config/reusable_functions.lua` (module `M`), plus the
--  dedicated modules `statuscolumn.lua`, `jumplist.lua`, and `tabs.lua`.
--
--  To bind a new function, require it here and add a bind line; do NOT inline
--  function bodies.
-- =============================================================================

-- Reusable general-purpose functions.
local M = require("config.reusable_functions")

local opts = { noremap = true, silent = true }
local map = vim.keymap.set

-- Global jump ring (C-o back / C-i forward) — port of emacs/jumpring.el
local jump = require("config.jumplist")
vim.keymap.set("n", "<C-o>", jump.backward, { desc = "Jump back (jumplist)" })
vim.keymap.set("n", "<C-i>", jump.forward, { desc = "Jump forward (jumplist)" })

-- Set a mark, cleaning up any prior mark with the same name first.
local SC = require("config.statuscolumn")
vim.keymap.set("n", "m", SC.set_mark, { desc = "Set mark (clean)" })

-- Fast saving and quitting
-- map("n", "<leader>w", ":write!<CR>", { silent = false, desc = "Save file" })
-- map("n", "<leader>q", ":q!<CR>", opts)

-- 't' will perform the BUILT-IN 'f' behavior, ignoring any other 'f' maps
vim.keymap.set({ "n", "x", "o" }, "t", "f", { remap = false, desc = "Built-in forward search" })
-- 'T' will perform the BUILT-IN 'F' behavior
vim.keymap.set({ "n", "x", "o" }, "T", "F", { remap = false, desc = "Built-in backward search" })

-- Remap for dealing with visual line wraps
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })

-- better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- paste over currently selected text without yanking it
map("v", "p", '"_dp')
map("v", "P", '"_dP')

-- copy everything between { and } including the brackets
map("n", "YY", "va{Vy", opts)

-- Move to start/end of line
map({ "n", "x", "o" }, "H", "^", opts)
map({ "n", "x", "o" }, "L", "g_", opts)

-- Panes resizing
map("n", "+", ":vertical resize +5<CR>")
map("n", "_", ":vertical resize -5<CR>")
map("n", "=", ":resize +5<CR>")
map("n", "-", ":resize -5<CR>")

map("n", "n", "nzz", opts)
map("n", "N", "Nzz", opts)
map("n", "*", "*zzv", opts)
map("n", "#", "#zzv", opts)
map("n", "g*", "g*zz", opts)
map("n", "g#", "g#zz", opts)

-- Split line with X
map("n", "X", ":keeppatterns substitute/\\s*\\%#\\s*/\\r/e <bar> normal! ==^<cr>", { silent = true })

-- Select all
map("n", "<C-a>", "ggVG", opts)

-- write file in current directory
map("n", "<C-n>", ":w %:h/", opts)

-- Get highlighted line numbers in visual mode
map("v", "<leader>ln", ':lua require("config.utils").get_highlighted_line_numbers()<CR>', opts)

map("n", "<leader>rl", function()
  vim.cmd("w")
  vim.cmd("SlimeSendCurrentLine")
end, { desc = "[vim-slime]: send current line" })

map("n", "<leader>L", ":cd %:h<CR>", {
  desc = "[L]ocate file in system",
})

-- Send motion (paragraph) to Slime, and move the cursor to the end of it
map("n", "<leader>rr", "<Plug>SlimeMotionSend}}", {
  silent = true,
  desc = '[vim-slime]: send motion "}" ',
})

-- FILE MANAGEMENT
-- map('n', '<leader>e', "<cmd>Fyler<cr>", { desc = 'Open Oil' })

-- Toggle Oil at the current file's directory (Emacs M-e).
-- In an oil buffer it closes it and returns to the buffer oil was spawned from;
-- otherwise it opens oil rooted at the focused file's directory.
-- (broot toggle kept commented for reference)
-- map({ "n", "t" }, "<M-e>", M.broot_toggle, { desc = "Toggle broot at file dir" })
map({ "n", "t" }, "<M-e>", M.oil_toggle, { desc = "Toggle oil at file dir" })

-- Zoxide directory travel (Emacs M-z / my/zoxide-travel-dispatch).
-- NORMAL mode only: the picker needs a normal-mode context, and in a terminal
-- buffer you reach normal mode with <Esc> first.
--   terminal buffer -> cd's that terminal's shell
--   anything else   -> opens oil at the chosen directory
map("n", "<M-z>", M.zoxide_travel, { desc = "Zoxide travel" })

-- `s` -> fuzzy search the current buffer's lines (Emacs `s` / consult-line).
map("n", "s", M.search_line_jump, { desc = "Search buffer lines" })
-- `S` -> ripgrep the project (Emacs `S` / consult-ripgrep).
map("n", "S", M.search_ripgrep_jump, { desc = "Ripgrep project" })

-- Open a terminal from the current Oil directory (oil buffer only)
map("n", "<leader>cd", M.oil_open_terminal, { desc = "[oil]: open terminal in current directory" })

-- Delete word using CTRL+BKSPC
map("n", "<C-BS>", "diw", { noremap = true, silent = true })

-- <C-d> / <C-u> left at their NATIVE behaviour (plain half-page scroll).
-- They were previously mapped to "<C-d>zz" / "<C-u>zz" to keep the cursor
-- centered, but that breaks HOLDING the key: each key-repeat scrolled and then
-- `zz` re-centered the viewport, so the view oscillated (scroll up a bit, snap
-- back, scroll up a bit...) instead of scrolling smoothly.  `zz` is a
-- do-it-once operation and does not compose with repetition.
-- (Use `zz` by hand when you want a centred jump.)

-- Move selected line down (J) and up (K)
map("v", "J", ":m '>+1<CR>gv=gv", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)

-- Sets flash utility to f key and saves position to the jump list
-- Flash jump on `f` in normal/visual (search-sync via the shared `/` register).
vim.keymap.set({ "n", "x" }, "f", M.flash_jump_f, { desc = "Flash Jump (Search Sync Fixed)" })
-- Operator-pending flash motion on `f` (df/yf/cf jump to a flash target).
vim.keymap.set("o", "f", M.flash_motion, { desc = "Flash motion (operator-pending)" })

-- Disable any LSP in the current buffer
vim.keymap.set("n", "<leader>lx", function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    print("No active LSP clients to stop.")
    return
  end
  local client_names = {}
  for _, client in ipairs(clients) do
    table.insert(client_names, client.name)
    vim.lsp.stop_client(client.id)
  end
  print("Stopped LSP client(s): " .. table.concat(client_names, ", "))
end, { desc = "Stop LSP for current buffer with info" })

-- Remap \ to repeat search (;)
vim.keymap.set({ "n", "x", "o" }, "\\", ";", { noremap = true, desc = "Repeat last f/t/F/T search" })

-- Use the static single-char labels to jump to a line in the statuscolumn.
-- (Replaces the old vai.nvim jump; see lua/config/statuscolumn.lua)
vim.keymap.set({ "n", "x", "v" }, ";", function()
  vim.cmd("normal! m'")
  require("config.statuscolumn").jump()
end, { noremap = true, desc = "[statuscolumn]: static-label line jump" })

-- Jumps to marks (respecting mark column positions), recording to jumplist
vim.keymap.set("n", "'", function() M.jump_to_mark("`") end, { desc = "Jump to exact mark column" })
vim.keymap.set("n", '"', function() M.jump_to_mark("'") end, { desc = "Jump to mark line start" })

-- Pipes zoxide output to an oil buffer
vim.keymap.set("n", "<M-f>", function()
  local tmp = vim.fn.tempname()
  local term = Snacks.terminal.open("zoxide query -l | fzf > " .. tmp, {
    win = {
      height = 0.6,
      width = 0.8,
      style = "terminal",
      border = "single",
    },
  })

  vim.api.nvim_buf_attach(term.buf, false, {
    on_detach = function()
      vim.schedule(function()
        local ok, lines = pcall(vim.fn.readfile, tmp)
        if ok and lines[1] then
          local path = vim.trim(lines[1])
          if path ~= "" then
            require("oil").open(path)
          end
        end
        vim.fn.delete(tmp)
      end)
    end,
  })
end)

-- Exit terminal mode and go to the next buffer
vim.keymap.set("t", "<C-h>", [[<Cmd>bprevious<CR>]], { desc = "Terminal previous buffer" })
vim.keymap.set("t", "<C-l>", [[<Cmd>bnext<CR>]], { desc = "Terminal next buffer" })
-- Leave terminal mode AND restore the normal cursor appearance.
-- nvim reports both terminal-job mode and terminal-NORMAL mode as "nt", so
-- config/cursor.lua cannot tell them apart on its own; doing it here, in the
-- very mapping that performs the transition, makes the colour revert reliably.
local function exit_terminal_mode()
  vim.cmd("stopinsert")
  pcall(function()
    local cursor = require("config.cursor")
    -- Tell the ModeChanged handler to stand down for this transition, otherwise
    -- it re-applies the INSERT colour (mode is still reported as "nt") and
    -- undoes the normal colour set just below.
    if cursor.suppress_next then
      cursor.suppress_next()
    end
    cursor.apply("n")
  end)
end

vim.keymap.set("t", "<C-;>", exit_terminal_mode, { desc = "Exit terminal mode" })
-- ESC in terminal mode -> leave terminal mode (go to normal mode).
-- NOTE: this captures ESC for ALL terminal buffers, so programs that use ESC
-- (vim/less/htop/broot inside the terminal) won't receive it.  Use <C-;> if
-- you prefer to keep ESC for the program.
vim.keymap.set("t", "<Esc>", exit_terminal_mode, { desc = "Exit terminal mode" })

-- Forward ESC to the terminal's job when in a terminal buffer's NORMAL mode
-- (the counterpart to the ESC-in-terminal-mode map above).  Installed once per
-- terminal via TermOpen by config/terminal_autocmds.lua; buffer-local so it
-- only fires in terminal buffers and never touches regular file buffers.

-- Navigate buffers without centering the cursor
vim.keymap.set("n", "<C-l>", [[<Cmd>bnext<CR>]], opts)
vim.keymap.set("n", "<C-h>", [[<Cmd>bprevious<CR>]], opts)

-- Opens a vsplit terminal (current buffer left, terminal right).
map({ "n", "t" }, "<M-T>", M.terminal_vsplit, { desc = "Terminal in vsplit (right)" })

-- Opens a terminal (Emacs M-t).
map({ "n", "t" }, "<M-t>", M.spawn_terminal, { desc = "Terminal" })

-- Smart other window (Emacs M-w): split right showing the alternate buffer if
-- there is only one window, otherwise focus the other window.
map({ "n", "t" }, "<M-w>", M.smart_other_window, { desc = "Other window" })

-- Smart close window (Emacs M-W): close the current window; no-op if it is the
-- last window in the tab.
map({ "n", "t" }, "<M-W>", M.smart_close_window, { desc = "Close window" })

-- Buffer picker (Alt-i) — global MRU order + MRU ranks, shared with the tab
-- bar.  Lives in config/mru.lua so the numbering stays in one place.
map({ "n", "t" }, "<M-i>", function()
  require("config.mru").pick_buffers()
end, { desc = "Buffers (MRU)" })

-- Recent files (Alt-r) — also available in terminal mode.
map({ "n", "t" }, "<M-r>", function()
  Snacks.picker.recent()
end, { desc = "Recent" })

-- Copilot panel open.  Owned by the copilot.lua plugin (i-mode, key="<M-CR>"
-- in its panel config).  Kept here, commented, for reference only — do not
-- enable or you'll double-bind it.
-- vim.keymap.set("i", "<M-CR>", function() vim.cmd("Copilot panel") end, { desc = "Copilot panel" })

-- Kill the current buffer (Alt-k) — works in normal AND terminal mode.
map({ "n", "t" }, "<M-k>", function()
  local bufnr = vim.api.nvim_get_current_buf()
  -- Snacks.bufdelete handles terminals + last-window cases cleanly.
  local ok = pcall(function()
    require("snacks").bufdelete({ buf = bufnr })
  end)
  if not ok then
    pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
  end
end, { desc = "Kill current buffer" })

-- Switch to alternate buffer
vim.keymap.set({ "n", "t", "i" }, "<C-b>", [[<Cmd>b#<CR>]], { desc = "Switch to alternate buffer" })

-- Snacks picker spell checker
vim.keymap.set("n", "z=", function()
  local current_file = vim.api.nvim_buf_get_name(0)
  Snacks.picker.spelling({
    ---@param item snacks.Picker.Item
    transform = function(item)
      item.file = current_file
      return item
    end,
    preview = "file",
    layout = { preset = "vertical" },
  })
end, { desc = "Spelling Suggestions with File Preview" })

-- Close all other buffers
vim.keymap.set("n", "<leader>bo", M.close_other_buffers, { desc = "Close all other buffers" })

-- Git status picker (Snacks): one entry per `git status --porcelain` line.
-- Enter = state-aware fugitive diff, Shift+Enter = edit file.  See
-- lua/plugins/snacks.lua (picker.sources.git_status).
-- If the repo is clean, show the normal `git status` output; if not a git
-- repo, notify instead of opening an empty picker.
vim.keymap.set("n", "<leader>gs", function()
  local rev = vim.fn.system({ "git", "rev-parse", "--is-inside-work-tree" })
  if vim.v.shell_error ~= 0 then
    vim.notify("not a git repo", vim.log.levels.WARN)
    return
  end
  local out = vim.fn.systemlist({ "git", "status", "--porcelain" })
  if #out == 0 then
    vim.cmd("Git status")
    return
  end
  Snacks.picker.git_status()
end, { desc = "Git Status" })
