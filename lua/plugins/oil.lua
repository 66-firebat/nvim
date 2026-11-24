return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  -- Optional dependencies
  -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
  -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
  dependencies = { { "nvim-mini/mini.icons", opts = {} } },
  lazy = false,
  opts = {
    columns = {
      "icon",
      -- "permissions",
      "size",
      -- "mtime",
    },
  },
  config = function()
    require("oil").setup({
      -- NOTE: do NOT set win_options.winbar here.  If oil manages the winbar
      -- at all (even to ""), it overwrites the winbar AFTER the MRU-tabs
      -- autocmd runs, leaving the tab header blank.  Letting oil leave the
      -- winbar untouched lets config/tabs.lua's value persist.
      -- Wipe oil buffers when navigating away instead of hiding them, so
      -- browsing directories does not pile up one hidden buffer per directory.
      buf_options = {
        buflisted = false,
        bufhidden = "wipe",
      },
      columns = {
        "icon",
        -- "permissions",
        "size",
        -- "mtime",
      },
      keymaps = {
        ["yp"] = {
          desc = "Copy filepath to system clipboard",
          callback = function()
            require("oil.actions").copy_entry_path.callback()
            -- This copies the path to the internal register; 
            -- to force it to the system clipboard (+) use:
            vim.fn.setreg("+", vim.fn.getreg(vim.v.register))
          end,
        },
      },
    })

    require("oil").toggle_hidden()
    -- Save the current working directory to a file on exit or directory change
    -- local function save_cwd_to_file()
      --   local cwd = require("oil").get_current_dir()
      --   local file = io.open(os.getenv("TMPDIR") .. "/.nvim_last_dir", "w")
      --   if file then
      --     file:write(cwd)
      --     file:close()
      --   end
      -- end
      --
      -- vim.api.nvim_create_autocmd({ "VimLeavePre", "DirChanged" }, {
        --   callback = save_cwd_to_file,
        -- })




        -- Declare a global function to retrieve the current directory
        function _G.get_oil_winbar()
          local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
          local dir = require("oil").get_current_dir(bufnr)
          if dir then
            return vim.fn.fnamemodify(dir, ":~")
          else
            -- If there is no current directory (e.g. over ssh), just show the buffer name
            return vim.api.nvim_buf_get_name(0)
          end
        end

      end,
    }
