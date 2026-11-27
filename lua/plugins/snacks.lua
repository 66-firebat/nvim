return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = {
      enabled = true,
      -- Keep the custom statuscolumn.lua gutter active on big files:
      -- the stock setup clears `statuscolumn`, which wipes out our labels.
      setup = function(ctx)
        if vim.fn.exists(":NoMatchParen") ~= 0 then
          vim.cmd([[NoMatchParen]])
        end
        Snacks.util.wo(0, { foldmethod = "manual", conceallevel = 0 })
        vim.b.completion = false
        vim.b.minianimate_disable = true
        vim.b.minihipatterns_disable = true
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(ctx.buf) then
            vim.bo[ctx.buf].syntax = ctx.ft
          end
        end)
      end,
    },
    dashboard = { enabled = true},
    explorer = {
      layout = {
        preview = "main",
        layout = {
          backdrop = false,
          height = 0.5,
          position = "bottom",
          border = "none",
          box = "vertical",
          {
            win = "input",
            height = 1,
            border = true,
            title = "{title} {live} {flags}",
            title_pos = "center",
          },
          { win = "list", border = "none" },
          { win = "preview", title = "{preview}", height = 0.4, border = "top" },
        },
      },
      prompt = " THIS : ",
      enabled = true,
      sources = {
        files = { hidden = true },
      },
    },
    indent = { enabled = false },
    input = { enabled = true },
    notifier = {
      enabled = true,
      timeout = 3000,
    },
    picker = {
      layout = {

        preview = "main",
        layout = {
          backdrop = false,
          height = 0.5,
          position = "bottom",
          border = "none",
          box = "vertical",
          {
            win = "input",
            height = 1,
            border = true,
            title = "{title} {live} {flags}",
            title_pos = "center",
          },
          { win = "list", border = "none" },
          { win = "preview", title = "{preview}", height = 0.4, border = "top" },
        },

      },
      prompt = "  : ",
      enabled = true,
      sources = {
        files = { hidden = false },
        command_history = {
          confirm = function(picker, item)
            -- Prefer the selected item; fall back to whatever the user typed
            -- so a brand-new command (with no history match) still runs.
            local cmd = item and (item.cmd or item.text) or picker.input.filter.pattern
            picker:close()
            if cmd and cmd ~= "" then
              vim.fn.histadd("cmd", cmd)
              vim.cmd(cmd)
            end
          end,
        },
        git_log = {
          -- Custom preview: show a compact `git diff --stat`-style summary
          -- instead of the full patch (which is too tall/wide for the small
          -- preview window and gets clipped).  Output:
          --     <hash> <subject>
          --     <file> | <N> ++--
          --     ...
          --     N files changed, X insertions(+), Y deletions(-)
          preview = function(ctx)
            local commit = ctx.item and ctx.item.commit
            if not commit then
              return
            end
            local cmd = { "git", "--no-pager", "show", "--stat", "--oneline", commit }
            return Snacks.picker.preview.cmd(cmd, ctx, { ft = "git" })
          end,
          confirm = function(picker, item)
            picker:close()
            local hash = item and item.commit
            if not hash then
              return
            end
            vim.schedule(function()
              vim.cmd("Gtabedit " .. hash)
            end)
          end,
        },
        git_status = {
          -- Append per-file change counts (+N -M) from `git diff --numstat`
          -- (working tree) and `--cached` (index), looked up lazily and
          -- memoized so we only shell out to git once per repo.
          format = function(item, picker)
            local fmt = Snacks.picker.format.git_status(item, picker)
            if not item.file then
              return fmt
            end
            local cwd = item.cwd or picker.opts.cwd or vim.fn.getcwd()
            local cache = picker._git_status_counts
              or {}
            picker._git_status_counts = cache
            local key = cwd .. "\0" .. (item.file or "")
            if cache[key] == nil then
              cache[key] = {}
            end
            local counts = cache[key]
            if counts.loaded == nil then
              counts.loaded = true
              -- Build path -> (added, deleted) for worktree and index.
              local function numstat(args)
                local out = vim.fn.systemlist({ "git", "--no-pager", "diff", "--numstat", unpack(args) })
                local m = {}
                for _, line in ipairs(out) do
                  local a, d, p = line:match("^(%d+)\t(%d+)\t(.+)$")
                  if p then
                    m[p] = { added = tonumber(a), deleted = tonumber(d) }
                  end
                end
                return m
              end
              -- Working tree (unstaged) vs index.
              local wt = numstat({})
              -- Index (staged) vs HEAD.
              local ix = numstat({ "--cached" })
              -- Determine the path as git reports it (handle renames: use the
              -- new path from item.rename when present).
              local path = item.rename or item.file
              local w = wt[path] or wt[item.file]
              local i = ix[path] or ix[item.file]
              counts.added = (w and w.added or 0) + (i and i.added or 0)
              counts.deleted = (w and w.deleted or 0) + (i and i.deleted or 0)
            end
            -- Append " +N -M" (only if there is any count).
            if counts.added and counts.added > 0 or counts.deleted and counts.deleted > 0 then
              local s = " "
              s = s .. ("+%d"):format(counts.added or 0) .. " " .. ("-%d"):format(counts.deleted or 0)
              fmt[#fmt + 1] = { s, "SnacksPickerGitStat" }
            end
            return fmt
          end,
          confirm = function(picker, item)
            local status = item and item.status
            local file = item and (item.rename or item.file)
            if not file then
              return
            end
            -- Capture the main (target) window BEFORE closing, so the
            -- vimdiff opens there and not in the just-closed picker or a
            -- terminal window.
            local main_win = picker.main
            picker:close()
            -- State-aware fugitive VERTICAL vimdiff based on the porcelain XY
            -- code.  X = index (staged), Y = working tree (unstaged).
            -- Fugitive resolves a bare path as "the file as it exists in the
            -- work tree"; a commit/index object prefixes it (e.g. HEAD:path,
            -- :0:path = index version).  :Gvdiffsplit always splits vertical.
            local x = (status:sub(1, 1) or " ")
            local y = (status:sub(2, 2) or " ")
            local unstaged = y ~= " " and y ~= "?"
            local staged = x ~= " " and x ~= "?"
            local esc = vim.fn.fnameescape(file)
            local cmd
            if unstaged and staged then
              -- Both staged and unstaged: diff HEAD vs work tree (full net change).
              cmd = "Gvdiffsplit! " .. esc
            elseif staged then
              -- Staged only: diff index vs HEAD (what will be committed).
              cmd = "Gvdiffsplit HEAD:" .. vim.fn.fnameescape(file)
            elseif unstaged then
              -- Unstaged only: diff work tree vs index.
              cmd = "Gvdiffsplit " .. esc
            else
              -- Untracked (?)/ignored (!): nothing to diff against, so edit.
              vim.schedule(function()
                vim.cmd("edit " .. esc)
              end)
              return
            end
            vim.schedule(function()
              -- Run the split in the captured main window, not the current
              -- (possibly terminal/picker) window.
              if main_win and vim.api.nvim_win_is_valid(main_win) then
                vim.api.nvim_set_current_win(main_win)
              end
              vim.cmd(cmd)
            end)
          end,
          win = {
            input = {
              keys = {
                -- Ctrl+Enter edits the file (Enter is the state-aware diff).
                ["<C-CR>"] = { "git_edit_file", mode = { "n", "i" } },
              },
            },
          },
          actions = {
            git_edit_file = function(picker, item)
              local file = item and (item.rename or item.file)
              if not file then
                return
              end
              picker:close()
              vim.schedule(function()
                vim.cmd("edit " .. vim.fn.fnameescape(file))
              end)
            end,
          },
        },
      },
    },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true,
      ---@class snacks.scroll.Config
      ---@field animate snacks.animate.Config|{}
      ---@field animate_repeat snacks.animate.Config|{}|{delay:number}
        animate = {
          duration = { step = 100, total = 200 },
          easing = "linear",
        },
        -- faster animation when repeating scroll after delay
        animate_repeat = {
          delay = 100, -- delay in ms before using the repeat animation
          duration = { step = 100, total = 50 },
          easing = "linear",
        },
        -- NOTE: do NOT include terminal buffers here.  snacks.scroll animates
        -- via `:normal!` inside nvim_win_call on a timer; running that in a
        -- terminal-mode buffer throws "Can't re-enter normal mode from
        -- terminal mode".  Terminals are therefore excluded (default filter).
    },
    -- statuscolumn = { enabled = true },
    words = { enabled = true },
    styles = {
      notification = {
        -- wo = { wrap = true } -- Wrap notifications
      },
    },
  },
  keys = {
    -- Bare `:` opens the command-history picker (insert mode, input focused).
    {
      ":",
      function()
        Snacks.picker.command_history()
      end,
      mode = { "n", "x" },
      desc = "Command History",
    },
    -- Top Pickers & Explorer
    {
      "<leader><space>",
      function()
        Snacks.picker.smart()
      end,
      desc = "Smart Find Files",
    },
    {
      "<leader>/",
      function()
        Snacks.picker.grep()
      end,
      desc = "Grep",
    },
    {
      "<leader>:",
      function()
        Snacks.picker.command_history()
      end,
      desc = "Command History",
    },
    {
      "<leader>sn",
      function()
        Snacks.picker.notifications()
      end,
      desc = "Search Notifications",
    },
    -- (removed) "<leader>e" was Snacks.explorer(); now bound to spawn_broot in keymaps.lua
    -- Buffer picker: now bound to <M-i> in keymaps.lua (so it also works in
    -- terminal mode).  Not defined here to avoid a duplicate mapping.
    {
      "<leader>fc",
      function()
        Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
      end,
      desc = "Find Config File",
    },
    {
      "<leader>ff",
      function()
        Snacks.picker.files()
      end,
      desc = "Find Files",
    },
    {
      "<leader>fg",
      function()
        Snacks.picker.git_files()
      end,
      desc = "Find Git Files",
    },
    {
      "<leader>fp",
      function()
        Snacks.picker.projects()
      end,
      desc = "Projects",
    },
    {
      "<leader>pp",
      function()
        Snacks.picker.projects()
      end,
      desc = "Projects",
    },
    -- <M-r> (Recent) moved to keymaps.lua so it also works in terminal mode.
    -- git
    {
      "<leader>gb",
      function()
        Snacks.picker.git_branches()
      end,
      desc = "Git Branches",
    },
    {
      "<leader>gl",
      function()
        Snacks.picker.git_log()
      end,
      desc = "Git Log",
    },
    {
      "<leader>gL",
      function()
        Snacks.picker.git_log_line()
      end,
      desc = "Git Log Line",
    },
    {
      "<leader>gS",
      function()
        Snacks.picker.git_stash()
      end,
      desc = "Git Stash",
    },
    {
      "<leader>gd",
      function()
        Snacks.picker.git_diff()
      end,
      desc = "Git Diff (Hunks)",
    },
    {
      "<leader>gf",
      function()
        Snacks.picker.git_log_file()
      end,
      desc = "Git Log File",
    },
    -- Grep
    {
      "<leader>sb",
      function()
        Snacks.picker.lines()
      end,
      desc = "Buffer Lines",
    },
    {
      "<C-s>",
      function()
        Snacks.picker.grep_buffers()
      end,
      desc = "Grep Open Buffers",
    },
    {
      "<leader>st",
      function()
        Snacks.picker.grep()
      end,
      desc = "Grep",
    },
    {
      "<leader>sw",
      function()
        Snacks.picker.grep_word()
      end,
      desc = "Visual selection or word",
      mode = { "n", "x" },
    },
    -- search
    {
      '<leader>s"',
      function()
        Snacks.picker.registers()
      end,
      desc = "Registers",
    },
    {
      "<leader>s/",
      function()
        Snacks.picker.search_history()
      end,
      desc = "Search History",
    },
    {
      "<leader>sa",
      function()
        Snacks.picker.autocmds()
      end,
      desc = "Autocmds",
    },
    -- Removed duplicate mapping for <leader>sb (already defined at line 175-180)
    {
      "<leader>sc",
      function()
        Snacks.picker.command_history()
      end,
      desc = "Command History",
    },
    {
      "<leader>sC",
      function()
        Snacks.picker.commands()
      end,
      desc = "Commands",
    },
    {
      "<leader>sd",
      function()
        Snacks.picker.diagnostics()
      end,
      desc = "Diagnostics",
    },
    {
      "<leader>sD",
      function()
        Snacks.picker.diagnostics_buffer()
      end,
      desc = "Buffer Diagnostics",
    },
    {
      "<leader>sh",
      function()
        Snacks.picker.help()
      end,
      desc = "Help Pages",
    },
    {
      "<leader>sH",
      function()
        Snacks.picker.highlights()
      end,
      desc = "Highlights",
    },
    {
      "<leader>si",
      function()
        Snacks.picker.icons()
      end,
      desc = "Icons",
    },
    {
      "<leader>sj",
      function()
        Snacks.picker.jumps()
      end,
      desc = "Jumps",
    },
    {
      "<leader>sk",
      function()
        Snacks.picker.keymaps()
      end,
      desc = "Keymaps",
    },
    {
      "<leader>sl",
      function()
        Snacks.picker.loclist()
      end,
      desc = "Location List",
    },
    {
      "<leader>sm",
      function()
        Snacks.picker.marks()
      end,
      desc = "Marks",
    },
    {
      "<leader>sM",
      function()
        Snacks.picker.man()
      end,
      desc = "Man Pages",
    },
    {
      "<leader>sp",
      function()
        Snacks.picker.lazy()
      end,
      desc = "Search for Plugin Spec",
    },
    {
      "<leader>sq",
      function()
        Snacks.picker.qflist()
      end,
      desc = "Quickfix List",
    },
    {
      "<leader>sR",
      function()
        Snacks.picker.resume()
      end,
      desc = "Resume",
    },
    {
      "<leader>su",
      function()
        Snacks.picker.undo()
      end,
      desc = "Undo History",
    },
    {
      "<leader>uC",
      function()
        Snacks.picker.colorschemes()
      end,
      desc = "Colorschemes",
    },
    -- LSP
    {
      "gd",
      function()
        Snacks.picker.lsp_definitions()
      end,
      desc = "Goto Definition",
    },
    {
      "gD",
      function()
        Snacks.picker.lsp_declarations()
      end,
      desc = "Goto Declaration",
    },
    {
      "gr",
      function()
        Snacks.picker.lsp_references()
      end,
      nowait = true,
      desc = "References",
    },
    {
      "gI",
      function()
        Snacks.picker.lsp_implementations()
      end,
      desc = "Goto Implementation",
    },
    {
      "gy",
      function()
        Snacks.picker.lsp_type_definitions()
      end,
      desc = "Goto T[y]pe Definition",
    },
    {
      "<leader>p",
      function()
        Snacks.picker.lsp_symbols()
      end,
      desc = "LSP Symbols",
    },
    {
      "<leader>WS",
      function()
        Snacks.picker.lsp_workspace_symbols()
      end,
      desc = "LSP Workspace Symbols",
    },
    -- Other
    {
      "<leader>Z",
      function()
        Snacks.zen()
      end,
      desc = "Toggle Zen Mode",
    },
    {
      "<leader>z",
      function()
        Snacks.zen.zoom()
      end,
      desc = "Toggle Zoom",
    },
    {
      "<leader>.",
      function()
        Snacks.scratch()
      end,
      desc = "Toggle Scratch Buffer",
    },
    {
      "<leader>S",
      function()
        Snacks.scratch.select()
      end,
      desc = "Select Scratch Buffer",
    },
    {
      "<leader>n",
      function()
        Snacks.notifier.show_history()
      end,
      desc = "Notification History",
    },
    {
      "Q",
      function()
        Snacks.bufdelete()
      end,
      desc = "Delete Buffer",
    },
    {
      "<leader>cR",
      function()
        Snacks.rename.rename_file()
      end,
      desc = "Rename File",
    },
    {
      "<leader>gB",
      function()
        Snacks.gitbrowse()
      end,
      desc = "Git Browse",
      mode = { "n", "v" },
    },
    {
      "<leader>gg",
      function()
        Snacks.lazygit()
      end,
      desc = "Lazygit",
    },
    {
      "<leader>un",
      function()
        Snacks.notifier.hide()
      end,
      desc = "Dismiss All Notifications",
    },
    {
      "<c-/>",
      function()
        Snacks.terminal()
      end,
      desc = "Toggle Terminal",
    },
    {
      "<c-_>",
      function()
        Snacks.terminal()
      end,
      desc = "which_key_ignore",
    },
    {
      "]]",
      function()
        Snacks.words.jump(vim.v.count1)
      end,
      desc = "Next Reference",
      mode = { "n", "t" },
    },
    {
      "[[",
      function()
        Snacks.words.jump(-vim.v.count1)
      end,
      desc = "Prev Reference",
      mode = { "n", "t" },
    },
    {
      "<leader>N",
      desc = "Neovim News",
      function()
        Snacks.win({
          file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
          width = 0.6,
          height = 0.6,
          wo = {
            spell = false,
            wrap = false,
            signcolumn = "yes",
            statuscolumn = " ",
            conceallevel = 3,
          },
        })
      end,
    },
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        -- Create some toggle mappings
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.line_number():map("<leader>ul")
        Snacks.toggle
        .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
        :map("<leader>uc")
        Snacks.toggle.treesitter():map("<leader>uT")
        Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
        Snacks.toggle.inlay_hints():map("<leader>uh")
        Snacks.toggle.indent():map("<leader>ug")
        Snacks.toggle.dim():map("<leader>uD")
      end,
    })
  end,
}
