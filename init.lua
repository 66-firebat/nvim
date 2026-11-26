-- THIS WILL FORCE THE RTP OF THE INIT.LUA PARENT DIRECTORY TO BE ADDED TO NVIM RUNTIME PATH
--[[ local current_file = debug.getinfo(1).source:sub(2)

local parent_dir = vim.fn.fnamemodify(current_file, ":p:h:h")

vim.opt.rtp:prepend(parent_dir)

print("Config path: " .. vim.fn.stdpath("config")) ]]

vim.g.mapleader = " "					-- change leader to a space
vim.g.maplocalleader = " "				-- change localleader to a space

-- Disable unused providers (was previously injected via programs.neovim).
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0
require("core.lazy")
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.terminal_autocmds").setup()
-- Global persisted jump ring (C-o/C-i) + its VimEnter/VimLeavePre hooks.
require("config.jumplist").setup()
-- Global MRU buffer list (single source of truth for tab + picker numbering).
require("config.mru").setup()
-- Per-mode terminal cursor colour/shape via OSC 12 + DECSCUSR (Ghostty).
require("config.cursor").setup()
-- Per-window grouped MRU tab bar (port of emacs/MRU-tabs.el).
require("config.tabs").setup()
-- Statuscolumn (direct render, no statuscol.nvim caching layer).
require("config.statuscolumn").setup()

-- designates the pynvim provider to be used based on a shell variable IF a shell variable exists. This allows nvim to reference a different python executable when in a nix shell that defines the python3_host_prog environment variable
if vim.env.python3_host_prog then
    vim.g.python3_host_prog = vim.env.python3_host_prog
end

-- require("core.mason-path")
-- require("core.lsp")
-- require("config.mason-verify")
-- require("config.health-check")
--[[ -- Define a function to open Oil in the current working directory
local function open_oil_on_startup()
    -- Check if Neovim started without any file arguments
    if #vim.api.nvim_list_bufs() == 1 and vim.bo.buftype == "" and vim.fn.argc() == 0 then
        -- The first buffer is an empty, unlisted buffer, so open Oil
        -- require("Fyler").open()
        vim.cmd("Fyler")
    end
end

-- Execute the function after Neovim has finished starting up
vim.api.nvim_create_autocmd("VimEnter", {
    callback = open_oil_on_startup,
}) ]]
