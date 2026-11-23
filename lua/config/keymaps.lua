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

-- Open broot in a terminal (commented out; oil is the active file manager)
-- map("n", "<M-e>", M.open_broot, { desc = "open broot" })

-- Open Oil (writable file manager)
map("n", "<M-e>", M.open_oil, { desc = "open oil" })

-- Exact-word search on Shift+S
map("n", "S", M.exact_word_search, { desc = "Exact word search (prompt)" })

-- Open a terminal from the current Oil directory (oil buffer only)
map("n", "<leader>cd", M.oil_open_terminal, { desc = "[oil]: open terminal in current directory" })

-- Delete word using CTRL+BKSPC
map("n", "<C-BS>", "diw", { noremap = true, silent = true })

-- Keep cursor centered when scrolling
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)

-- Move selected line down (J) and up (K)
map("v", "J", ":m '>+1<CR>gv=gv", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)

-- Sets flash utility to f key and saves position to the jump list
vim.keymap.set({ "n", "x", "o" }, "f", M.flash_jump_f, { desc = "Flash Jump (Search Sync Fixed)" })

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
vim.keymap.set("t", "<C-;>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- Navigate buffers without centering the cursor
vim.keymap.set("n", "<C-l>", [[<Cmd>bnext<CR>]], opts)
vim.keymap.set("n", "<C-h>", [[<Cmd>bprevious<CR>]], opts)

-- Opens a vsplit terminal
map("n", "<leader>tT", M.open_tmux_vsplit, { desc = "Windowed Tmux" })

-- Opens a terminal on a separate buffer
map("n", "<leader>tt", M.open_tmux_terminal, { desc = "Windowed Tmux" })

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
