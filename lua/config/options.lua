-- Use :lua print(package.path) to see the path. Note that the ../config directory is not part of the current package path. If desired, thepackage path can be added via modifying the package.path variable
local opt = vim.opt
local cmd = vim.cmd
local api = vim.api
local nvim_create_autocmd = api.nvim_create_autocmd
local nvim_set_hl = api.nvim_set_hl

require("config.vimtex.config")
require("config.highlight_groups.highlights")
-- Panes parity (wrap/truncation glyph + divider color), port of emacs/panes.el
require("config.reusable_functions").setup_pane_glyphs()
-- Set up LSP servers
require("config.lsp.luals")
-- require("config.lsp.pylsp")

vim.lsp.enable("basedpyright")
-- pulls in the autocommand for julials
require("config.lsp.julials")

-- vim.g.vimtex_compiler_method = "lualatex"
-- sets scrollback memory to 9999 lines. Exceeding lines will cause earliest lines to be removed from buffer memory. Use :set scrollback=<value> to manually designate scrollback memory.
vim.o.scrollback = 9999
vim.g.mapleader = " "					-- change leader to a space
-- Disable spelling (so text files don't show red squiggle lines on startup. Enable spelling with set spell)
vim.o.spell = false
vim.g.maplocalleader = " "				-- change localleader to a space
vim.g.loaded_netrw = 1					-- disable netrw
vim.g.loaded_netrwPlugin = 1				--  disable netrw
vim.opt.incsearch = true				-- make search act like search in modern browsers
vim.opt.backup = false					-- creates a backup file
vim.opt.cmdheight = 1					-- more space in the neovim command line for displaying messages
vim.opt.completeopt = { "menu", "menuone", "noselect" } -- mostly just for cmp
vim.opt.conceallevel = 0				-- so that `` is visible in markdown files
vim.opt.fileencoding = "utf-8"				-- the encoding written to a file
vim.opt.hlsearch = true					-- highlight all matches on previous search pattern
vim.opt.ignorecase = true				-- ignore case in search patterns
vim.opt.mouse = ""					-- disable the mouse completely
vim.opt.pumheight = 10					-- pop up menu height
vim.opt.showmode = false				-- we don't need to see things like -- INSERT -- anymore

vim.opt.showtabline = 0					-- always show tabs
vim.opt.smartcase = true				-- smart case
vim.opt.splitbelow = true				-- force all horizontal splits to go below current window
vim.opt.splitright = true				-- force all vertical splits to go to the right of current window
vim.opt.swapfile = false				-- creates a swapfile
vim.opt.termguicolors = true				-- set term gui colors (most terminals support this)
vim.opt.timeoutlen = 666666			-- time to wait for a mapped sequence to complete (in milliseconds)
vim.opt.undofile = true					-- enable persistent undo
vim.opt.updatetime = 100				-- faster completion (4000ms default)
vim.opt.writebackup = false				-- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
vim.opt.expandtab = true				-- convert tabs to spaces
vim.opt.shiftwidth = 2 -- Amount to indent with << and >>
vim.opt.tabstop = 2 -- How many spaces are shown per Tab
vim.opt.softtabstop = 2 -- How many spaces are shown per Tab
-- vim.opt.smartindent = false				    -- make indenting smarter again
-- Lists invisibles
-- vim.opt.list = true
-- vim.opt.listchars = { tab = "|-", trail = "·", nbsp = "␣" }

vim.opt.cursorline = false				-- highlight the current line
-- vim.opt.cursorcolumn = true				-- highlight the current line
vim.opt.number = true					-- set numbered lines
vim.opt.breakindent = false				-- wrap lines with indent
vim.opt.relativenumber = true				-- set relative numbered lines
vim.opt.numberwidth = 3					-- set number column width to 2 {default 4}
-- Enable word-wise line breaking (wrap at spaces)
vim.opt.wrap = true           -- enable line wrapping
vim.opt.linebreak = true      -- break only at word boundaries
vim.opt.breakat = " "         -- only break at spaces
vim.opt.breakindent = false    -- keep visual indentation for wrapped lines
vim.opt.showbreak = ""         -- no indicator for wrapped lines
vim.opt.scrolloff = 0				   -- Makes sure there are always eight lines of context
-- vim.opt.sidescrolloff = 8				   -- Makes sure there are always eight lines of context
vim.opt.showcmd = true		 -- Don't show the command in the last line
vim.opt.ruler = true		  -- Don't show the ruler
vim.opt.guifont = "monospace:h17" -- the font used in graphical neovim applications
vim.opt.title = true		  -- set the title of window to the value of the titlestring
vim.opt.confirm = true		  -- confirm to save changes before exiting modified buffer
vim.opt.fillchars = { eob = " ", vert = "╎" } -- change the char at end of buffer + vertical divider
-- vim.opt.winborder = "rounded" -- solid
vim.opt.winborder = "single"	  -- https://neovim.io/doc/user/options.html#'winborder'

-- Cursor SHAPE + BLINK is handled entirely by nvim's 'guicursor'.
-- (Cursor COLOUR per mode is handled by config/cursor.lua via OSC 12, since
--  'guicursor' cannot express colour.)
--
--   n-v-c : solid block, blinking      (normal / visual)
--   i-ci  : thin vertical bar, blinking (insert)
--   r-cr  : horizontal bar              (replace)
--   (no `t:` entry — terminal-mode shape is handled by config/cursor.lua via a
--    direct DECSCUSR escape.  If `t:` is present, nvim ALSO emits its own shape
--    right after ours and overrides it; see the note below.)
--
-- NOTE: 'guicursor' has no "hollow block" token (only block/hor/ver/underline),
-- so normal mode is a SOLID block.  Ghostty's `cursor-style = block_hollow` only
-- applies while nvim is not specifying a shape.
-- IMPORTANT: every mode we care about must be listed explicitly — an OMITTED
-- mode defaults to a solid `block` (see :h 'guicursor', "Default is block for
-- each mode").  That is why terminal mode previously stayed a block even though
-- insert was a bar.  `t:` mirrors `i-ci:`.
-- NOTE: `t:` is deliberately ABSENT.  With a `t:` entry nvim emits its own
-- DECSCUSR for terminal buffers, and in a captured TTY trace it writes
-- `ESC[2 q` immediately AFTER config/cursor.lua's `ESC[6 q`, overriding it — so
-- terminal mode always ended up a block.  Leaving `t:` out means nvim emits
-- nothing for terminals and cursor.lua's escape is the one that sticks.
-- Blinking is ALLOWED: explicit blink timings are supplied for every mode so
-- nvim requests the blinking DECSCUSR variants (1/3/5) and keeps the cursor
-- blinking in both nvim and the outer terminal.
-- (Per :h 'guicursor', any blink number being zero means NO blinking, so all
-- three of blinkwait/blinkon/blinkoff are given non-zero values.)
-- blinkon/blinkoff DOUBLED (400/250 -> 800/500), i.e. one full on+off cycle is
-- 1300ms instead of 650ms, so the blink is half as frequent.
vim.opt.guicursor = "n-v-c:block-blinkwait700-blinkon800-blinkoff500,"
  .. "i-ci:ver25-blinkwait700-blinkon800-blinkoff500,"
  .. "r-cr:hor20-blinkwait700-blinkon800-blinkoff500"


-- (previous cursor experiments, kept for reference)
-- vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20"
-- vim.opt.guicursor = "i-ci:ver30-iCursor-blinkwait300-blinkon200-blinkoff150"


-- vim.opt.cursorlineopt = "number"		 -- set the cursorline
-- vim.opt.tabstop = 2				 -- insert 2 spaces for a tab
-- vim.opt.laststatus = 0 -- Always display the status line

-- changes colors of the number columns and other associated features
-- vim.api.nvim_set_hl(0, 'Normal', { fg = '#FF6000', bg = 'none' })
-- vim.api.nvim_set_hl(0, 'CursorLine', { fg = 'none', bg = '#80401a', blend = 5 })
-- vim.api.nvim_set_hl(0, 'Visual', { fg = 'none', bg = '#80401a', blend = 50 })
-- vim.api.nvim_set_hl(0, 'ministatuslinemodenormal', { fg = '#ff6000', bg = '#80401a' })

vim.filetype.add({
	extension = {
		env = "dotenv",
	},
	filename = {
		[".env"] = "dotenv",
		["env"] = "dotenv",
	},
	pattern = {
		["[jt]sconfig.*.json"] = "jsonc",
		["%.env%.[%w_.-]+"] = "dotenv",
	},
})


-- vim.opt.list = true

-- local space = "·"
-- opt.listchars:append {
-- 	tab = "▍·",
-- 	multispace = space,
-- 	eol = "↲",
-- 	extends = "❯",
-- 	precedes = "❮",
-- 	lead = space,
-- 	trail = space,
-- 	nbsp = space,
-- }
--
-- cmd([[match TrailingWhitespace /\s\+$/]])
--
-- nvim_set_hl(0, "TrailingWhitespace", { link = "Error" })
--



-- vim.diagnostic.config({
-- 	virtual_lines = {
-- 		current_line = true,
-- 	},
-- 	signs = {
-- 		text = {
-- 			[vim.diagnostic.severity.ERROR] = "",
-- 			[vim.diagnostic.severity.WARN]  = "",
-- 			[vim.diagnostic.severity.INFO]  = "",
-- 			[vim.diagnostic.severity.HINT]  = "󰌵",
-- 		},
-- 	},
-- })

-- Define your icons
local icons = {
  [vim.diagnostic.severity.ERROR] = " ",
  [vim.diagnostic.severity.WARN]  = " ",
  [vim.diagnostic.severity.HINT]  = "󰠠 ",
  [vim.diagnostic.severity.INFO]  = " ",
}

vim.diagnostic.config({
  virtual_text = {
    -- 1. Use a function for the prefix to return different symbols
    prefix = function(diagnostic)
      return icons[diagnostic.severity] or "● "
    end,
    -- 2. Return an empty string in format to hide the message text
    format = function(diagnostic)
      return ""
    end,
    spacing = 1,
  },
})

-- vim.api.nvim_create_augroup("remember_folds", { clear = true })
--
-- vim.api.nvim_create_autocmd("BufWinLeave", {
--   group = "remember_folds",
--   pattern = "*",
--   command = "mkview",
-- })
--
-- vim.api.nvim_create_autocmd("BufWinEnter", {
--   group = "remember_folds",
--   pattern = "*",
--   command = "silent! loadview",
-- })



-- 1. Set the global slime target to 'neovim'.
-- This tells vim-slime to look for an open Neovim terminal buffer to send text to.
vim.g.slime_target = "neovim"

-- Set bracketed paste mode for Neovim so slime can deliver data to ipython interpreters
vim.g.slime_bracketed_paste = 1
vim.g.slime_python_ipython = 1



-- vim.api.nvim_create_autocmd("VimEnter", {
--     group = augroup,
--     callback = function()
--         -- Check if the current buffer is a 'normal' text buffer
--         -- buftype should be empty, and filetype should not be a known utility type.
--         -- vim.bo is a shortcut for buffer-local options.
--         if vim.bo.buftype == "" and not vim.tbl_contains({ 'lazy', , 'terminal', , 'quickfix', , 'help', , 'prompt', }, vim.bo.filetype) then
--             -- Run the command only for text-editing buffers
--             vim.cmd("let &statuscolumn=' %C%l %=%#StatusColumnBorder#▍%s'")
--
--             -- Example: Print a message
--             print("VimEnter: Statuscolumn set for a text buffer!")

--         end
--     end,
-- })


-- vim.opt.statuscolumn = [[%!v:lua.StatusColumn()]]
-- vim.o.signcolumn = "yes:2"
-- vim.o.statuscolumn = '%s%= %{%v:relnum %} %#StatusColumnBorder#▍'
-- lua/plugins/gitsigns.lua

--MAIN STATUSCOLUMN CONFIGURATION

-- Global configuration to disable all diagnostic signs
vim.diagnostic.config({
	signs = false, -- This is the key setting
})



-- Explicitly tell Neovim to use wl-copy and wl-paste
vim.g.clipboard = {
	name = 'wl-copy',
	copy = {
		['+'] = { 'wl-copy', '--trim-newline' }, -- The '+' register is the system clipboard
		['*'] = { 'wl-copy', '--trim-newline' }, -- The '*' register is the primary selection
	},
	paste = {
		['+'] = 'wl-paste -n',
		['*'] = 'wl-paste -n',
	},
	cache_enabled = 1,
}

-- Still need to set this option for y/p to use the system clipboard
vim.opt.clipboard = "unnamedplus"

-- Disable showmatch
-- vim.opt.showmatch = false

-- vim.g.vimtex_compiler_latexmk = {
--   executable = 'latexmk',
--   options = {
--     '-lualatex',
--     '-file-line-error',
--     '-synctex=1',
--     '-interaction=nonstopmode', 
--     -- and so on
--   },
-- }


vim.g.vimtex_compiler_latexmk_engines = { ["_"] = "-lualatex" }

require("monoglow").setup({
  -- Change the "glow" color
  on_colors = function(colors)
    colors.glow = "#fd1b7c"
  end
})


-- Sets the virtualedit option to block, which permits unobstructed block-wise visual mode (moves past end of line). Change to "all" if all modes are intended to be supported in this way
vim.opt.virtualedit = "block"


vim.api.nvim_create_user_command('JuliaToggle', function()
    -- Get active clients named "julials" for the current buffer
    local clients = vim.lsp.get_clients({ bufnr = 0, name = "julials" })
    
    if #clients > 0 then
        -- If running, stop all instances of julials
        for _, client in ipairs(clients) do
            client.stop()
        end
        vim.notify("Julia LSP Stopped", vim.log.levels.INFO)
    else
        -- If not running, attempt to start it
        vim.cmd("LspStart julials")
        vim.notify("Julia LSP Started", vim.log.levels.INFO)
    end
end, {
    desc = "Toggle Julia LSP on/off for the current buffer"
})


-- Fall back to OSC 52 clipboard for the + and * registers when no functional
-- native clipboard tool is found. Requires Neovim 0.10+ and a terminal that
-- supports OSC 52 (WezTerm, iTerm2, Kitty, Ghostty, etc.).
-- We check not only whether clipboard tools are installed, but also whether
-- their display server is available ($DISPLAY for X11, $WAYLAND_DISPLAY for
-- Wayland). This ensures that tools like xclip or wl-copy on a headless server
-- or in an SSH session without display forwarding correctly fall through to
-- OSC 52. Fixes clipboard issues when running Neovim on a remote server from a
-- local tmux session.
local has_osc52, osc52 = pcall(require, 'vim.ui.clipboard.osc52')
local has_native_clipboard = (vim.fn.executable('pbcopy') == 1)
    or (vim.fn.executable('xclip') == 1 and vim.env.DISPLAY)
    or (vim.fn.executable('xsel') == 1 and vim.env.DISPLAY)
    or (vim.fn.executable('wl-copy') == 1 and vim.env.WAYLAND_DISPLAY)
if has_osc52 and not has_native_clipboard then
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = osc52.copy('+'),
      ['*'] = osc52.copy('*'),
    },
    paste = {
      ['+'] = osc52.paste('+'),
      ['*'] = osc52.paste('*'),
    },
  }
end

-- Add 'S' to shortmess to hide the [1/x] search index
vim.opt.shortmess:append("S")
