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

local function get_process_tree_rss(parent_pid)
  local total_rss_pages = 0
  local children = {}

  -- 1. Get RSS of the current PID
  local statm = io.open("/proc/" .. parent_pid .. "/statm", "r")
  if statm then
    local content = statm:read("*all")
    statm:close()
    local rss = content:match("%d+%s+(%d+)")
    total_rss_pages = total_rss_pages + (tonumber(rss) or 0)
  end

  -- 2. Find all children of this PID
  -- NixOS/Linux stores children in /proc/[pid]/task/[pid]/children
  local child_file = io.open("/proc/" .. parent_pid .. "/task/" .. parent_pid .. "/children", "r")
  if child_file then
    local content = child_file:read("*all")
    child_file:close()
    for child_pid in content:gmatch("%d+") do
      table.insert(children, tonumber(child_pid))
    end
  end

  -- 3. Recursively add children's memory
  for _, child_pid in ipairs(children) do
    total_rss_pages = total_rss_pages + get_process_tree_rss(child_pid)
  end

  return total_rss_pages
end

function Get_buffer_stats()
  if vim.bo.buftype ~= "terminal" then return get_file_size() end
  
  local root_pid = vim.b.terminal_job_pid
  if not root_pid then return "No PID" end

  local total_pages = get_process_tree_rss(root_pid)
  local total_mb = (total_pages * 4096) / 1024 / 1024

  return string.format("󰓾 %-5d:%.1f MB", root_pid, total_mb)
end

local function get_nvim_stats()
    local pid = vim.fn.getpid()

    -- Optimized: Use Neovim's internal libuv binding instead of 'ps'
    -- resident_set_memory returns bytes
    local rss_bytes = vim.loop.resident_set_memory()
    local rss_mb = rss_bytes / 1024 / 1024

    -- Include buffer count from the dedicated function
    local buf_stats = Get_buffer_stats()

    return string.format(" %5d:%.1fMB %s %s", pid, rss_mb, "", buf_stats)
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
          a = { fg = '#2b2b2b', bg = '#ff5500', gui = 'bold' },
          b = { fg = '#2b2b2b', bg = '#ff5500' },
          c = { fg = '#903f16', bg = '#2b2b2b' },
          z = { fg = '#2b2b2b', bg = '#ff5500', gui = 'bold' },
        },
        insert = {
          a = { fg = '#2c2c2c', bg = '#ff5500', gui = 'bold' },
          b = { fg = '#2b2b2b', bg = '#903f16' },
          c = { fg = '#ff5500', bg = '#2b2b2b' },
          -- x = { fg = '#2c2c2c', bg = '#ff5500', gui = 'bold' },
          -- y = { fg = '#2c2c2c', bg = '#ff5500', gui = 'bold' },
          -- z = { fg = '#2c2c2c', bg = '#ff5500', gui = 'bold' },
        },
        visual = {
          a = { fg = '#2c2c2c', bg = '#ff5500', gui = 'bold' },
          b = { fg = '#2b2b2b', bg = '#903f16' },
          c = { fg = '#ff5500', bg = '#2b2b2b' },
        -- x = { fg = '#2c2c2c', bg = '#ff5500', gui = 'bold' },
        -- y = { fg = '#2c2c2c', bg = '#ff5500', gui = 'bold' },
        -- z = { fg = '#2c2c2c', bg = '#ff5500', gui = 'bold' },
      },
      replace = {
        a = { fg = '#2c2c2c', bg = '#ff5500', gui = 'bold' },
        b = { fg = '#2b2b2b', bg = '#903f16' },
        c = { fg = '#ff5500', bg = 'none' },
      },
      inactive = {
        a = { fg = '#ff5500', bg = '#903f16', gui = 'bold' },
        b = { fg = '#903f16', bg = '#2b2b2b' },
        c = { fg = '#903f16', bg = '#2b2b2b' },
        z = { fg = '#903f16', bg = '#2b2b2b', gui = 'bold' },
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
        lualine_a = {mode, get_git_branch, 'searchcount', 'location',  diagnostics},
        -- lualine_b = {{ 'filetype', cond = hide_in_width }, diff},
        lualine_b = {},
        lualine_c = {diff},
        lualine_x = {function() return require("screenkey").get_keys() end },
        lualine_y = {},
        lualine_z = {'searchcount', {'location', cond = hide_in_width}, 'progress', { 'buffers', mode = 4, symbols = { modified = ' 󱍸', alternate_file = '󱇴 ', }, } },
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
          { get_nvim_stats,
            color = { fg = '#2b2b2b', bg = '#903f16', gui='bold' },
            separator = { left = '', right = '' },
          },
          get_buffer_count,
        },
        lualine_b = {'searchcount'},
        lualine_c = {
          {
            'filetype',
            icon_only = true,
          }
        },
        lualine_x = {},
        lualine_y = {},
        lualine_z = {{ 'filename', path = 2, color = { fg = '#903f16', bg = '#2b2b2b' } }},
      },
      extensions = { 'oil' },
    }
  end,
}





