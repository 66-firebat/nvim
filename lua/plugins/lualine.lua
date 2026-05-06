local function get_file_size()
  -- 1. Get the full path of the current buffer.
  local file_path = vim.fn.expand('%:p')

  -- 2. Use vim.fn.getfsize() to get the file size.
  --    This function returns the size formatted (e.g., "2.5K", "10M", "1024B").
  --    It returns '-1' for non-existent files or special buffers.
  local size = vim.fn.getfsize(file_path)

  -- Optional: Handle special buffers like [No Name] or directories
  if size == '-1' then
    return '0B'
  end

  return size .. 'B'
end

local function get_nvim_stats()
    -- Get the PID of the current Neovim process
    local pid = vim.fn.getpid()
    
    -- Run a shell command to get the RSS memory in KB
    -- 'ps -p [pid] -o rss=' returns just the number
    local handle = io.popen("ps -p " .. pid .. " -o rss=")
    local result = handle:read("*a")
    handle:close()
    
    -- Clean up the output and convert to MB
    local rss_kb = tonumber(result:match("%d+"))
    if rss_kb then
        local rss_mb = rss_kb / 1024
        return string.format("󰓾 %d : %.1fMB", pid, rss_mb)
    end

    return "PID: " .. pid .. " | Mem: ?"
end

-- A Lua function to fetch the number of buffers currently open in the nvim instance.
local function get_buffer_count()
  local buffers = #vim.fn.getbufinfo({ buflisted = 1 })

  local emoji_map = {
    [1] = "󰲠", [2] = "󰲢", [3] = "󰲤",
    [4] = "󰲦", [5] = "󰲨", [6] = "󰲪",
    [7] = "󰲬", [8] = "󰲮", [9] = "󰲰"
  }

  local display

  if buffers > 0 and buffers < 10 then
    display = emoji_map[buffers]
  elseif buffers >= 10 then
    display = "󰲲 " -- Icon for "10+"
  else
    display = " " -- Icon for 0 or error
  end

  return display
end




-- A Lua function to fetch the current Git branch name of the repository
-- containing the current buffer's file.
local function get_git_branch()
  -- The command to get the current branch name, abbreviated.
  -- This command is run by git in the directory of the current file.
  local git_command = 'git rev-parse --abbrev-ref HEAD'
  local branch_hash_function = 'git rev-parse --short HEAD'

  -- Use vim.fn.system() to execute the command.
  -- This returns the command output, including a trailing newline.
  local branch_name = vim.fn.system(git_command)
  local branch_hash = vim.fn.system(branch_hash_function)

  -- The output from vim.fn.system() includes a trailing newline,
  -- so we use string.gsub to trim leading/trailing whitespace.
  branch_name = branch_name:gsub('^%s*(.-)%s*$', '%1')
  branch_hash = branch_hash:gsub('^%s*(.-)%s*$', '%1')

  -- Check if the command failed or if the output is empty (e.g., not a git repo)
  if branch_name == '' or branch_name:find('fatal:') then
    -- Return a recognizable default string for non-git files
    return '∅'
  end

  -- Prefix the branch name with a recognizable icon/symbol
  return branch_name .. ' : ' .. branch_hash
end

-- --- EXAMPLE USAGE ---
-- If you were using this in a lualine configuration, you would pass
-- the function itself (not its result) to the sections table:

-- sections = {
--   lualine_a = { 'mode' },
--   lualine_b = { get_git_branch } -- Here is where we use the function
-- }

-- For demonstration, let's print the result:
-- print(string.format("Current Branch: %s", get_git_branch()))

return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local mode = {
        'mode',
        fmt = function(str)
          return ' ' .. str
          -- return ' ' .. str:sub(1, 1) -- displays only the first character of the mode
        end,
      }

      local filename = {
        'filename',
        file_status = true, -- displays file status (readonly status, modified status)
        path = 0, -- 0 = just filename, 1 = relative path, 2 = absolute path
      }

      local hide_in_width = function()
        return vim.fn.winwidth(0) > 100
      end

      local diagnostics = {
        'diagnostics',
        sources = { 'nvim_diagnostic' },
        sections = { 'error', 'warn' },
        symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
        colored = false, -- Disable colored output
        update_in_insert = false,
        always_visible = false,
        cond = hide_in_width,
      }

      local diff = {
        'diff',
        colored = true,
        symbols = { added = ' ', modified = ' ', removed = ' ' }, -- changes diff symbols
        cond = hide_in_width,
      }
      local my_custom_theme = {
        normal = {
          a = { fg = '#2b2b2b', bg = '#ff4400', gui = 'bold' },
          b = { fg = '#2b2b2b', bg = '#ff4400' },
          c = { fg = '#ff4400', bg = '#2b2b2b' },
        },
        insert = {
          a = { fg = '#2c2c2c', bg = '#ff6000', gui = 'bold' },
          b = { fg = '#2b2b2b', bg = '#80401a' },
          c = { fg = '#ff6000', bg = '#2b2b2b' },
          -- x = { fg = '#2c2c2c', bg = '#ff6000', gui = 'bold' },
          -- y = { fg = '#2c2c2c', bg = '#ff6000', gui = 'bold' },
          -- z = { fg = '#2c2c2c', bg = '#ff6000', gui = 'bold' },
        },
        visual = {
          a = { fg = '#2c2c2c', bg = '#ff6000', gui = 'bold' },
          b = { fg = '#2b2b2b', bg = '#80401a' },
          c = { fg = '#ff6000', bg = '#2b2b2b' },
        -- x = { fg = '#2c2c2c', bg = '#ff6000', gui = 'bold' },
        -- y = { fg = '#2c2c2c', bg = '#ff6000', gui = 'bold' },
        -- z = { fg = '#2c2c2c', bg = '#ff6000', gui = 'bold' },
      },
      replace = {
        a = { fg = '#2c2c2c', bg = '#ff6000', gui = 'bold' },
        b = { fg = '#2b2b2b', bg = '#80401a' },
        c = { fg = '#ff6000', bg = 'none' },
      },
      inactive = {
        a = { fg = '#ff6000', bg = '#80401a', gui = 'bold' },
        b = { fg = '#2b2b2b', bg = '#903716' },
        c = { fg = '#2b2b2b', bg = '#903716' },
      },
    }

    require('lualine').setup {
      options = {
        icons_enabled = false,
        theme = my_custom_theme, -- Set theme based on environment variable
        -- Some useful glyphs:
        -- https://www.nerdfonts.com/cheat-sheet
        --        
        section_separators = { left = '', right = '' },
        component_separators = { left = '', right = '' },
        -- disabled_filetypes = { 'alpha', 'neo-tree', 'explorer'},
        always_divide_middle = true,
      },
      sections = {
        lualine_a = {mode, get_git_branch, diagnostics},
        -- lualine_b = {{ 'filetype', cond = hide_in_width }, diff},
        lualine_b = {diff},
        lualine_c = { filename },
        lualine_x = {function() return require("screenkey").get_keys() end },
        lualine_y = { 'searchcount'},
        lualine_z = {{get_file_size, cond = hide_in_width}, {'location', cond = hide_in_width}, 'progress' },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { { 'filename', path = 1 } },
        lualine_x = { { 'location', padding = 0 } },
        lualine_y = {},
        lualine_z = {},
      },
      tabline = {
        lualine_a = {
          get_nvim_stats,

          { get_buffer_count,
            color = { fg = '#ffaa88', bg = 'grey', gui='italic,bold' },
          }

        },
        lualine_b = {
          {
            'buffers',
            mode = 4,
            symbols = {
              modified = ' 󱍸',      -- Text to show when the buffer is modified
              alternate_file = '󱇴 ', -- Text to show to identify the alternate file
            },
          }
        },
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {'filetype'}
      },
      extensions = { 'oil' },
    }
  end,
}






