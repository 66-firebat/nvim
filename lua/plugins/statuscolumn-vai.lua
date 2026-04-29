local function statusBorderBump()
  local cursorline = vim.fn.line(".")
  if vim.v.lnum == cursorline then
    return "%#StatusColumnBorder#┣ "
  else
    return "%#StatusColumnBorder#┃ "
  end
end

-- Function to remove highlights from the status column as an attempt to prevent odd  backgrounds blocks from rendering after the statuscolumn border.
local function noHighlight()
  local cursorline = vim.fn.line(".")
  if vim.v.lnum == cursorline then
    return "%#NoColor#"
  else
    return "%#NoColor#"
  end
end

return {
  "luukvbaal/statuscol.nvim",
  dependencies = {
    "johnpmitsch/vai.nvim",
  },
  config = function()
    local builtin = require("statuscol.builtin")
    local labels = require("vai.labels")
    
    local function label_func(args)

      local label_map = labels.build_labels()
      local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
      local first_line, last_line = vim.fn.line("w0"), vim.fn.line("w$")
      
      -- Calculate the width needed for the largest line number
      local max_line = last_line
      -- local num_width = #tostring(max_line)
      -- Hardcoding numwidth to prevent dynamic fluctuations in the width of the statuscolumn. Comment this out if you want a more compact statuscolumn for code that doesn't have as many lines. This WILL break if you have a file that has more characters in it's maximum linue number than the number hardcoded in the num_width variable. So, for example, setting the num_wdith to 4 will break if you have a file with more than 9999 lines.
      local num_width = 4
      
      -- Create reverse mapping: line_number -> label
      local line_to_label = {}
      for label, line_num in pairs(label_map) do
        line_to_label[line_num] = label
      end
      
      local text
      -- Show line number for cursor line, label for others
      if args.lnum == cursor_line then
        text = tostring(args.lnum)
      else
        text = line_to_label[args.lnum] or ""
      end
      
      -- Pad to match the width of line numbers
      return string.format("%" .. num_width .. "s", text)
    end
    
    require("statuscol").setup({
      relculright = true,
      segments = {
        { text = { "%#StatusCol# " }},
        {
          sign = {
            namespace = { "gitsigns" },
            maxwidth = 1,
            colwidth = 1,
            auto = false
          },
          hl = "CursorLineNr"
        },
        { text = { "%#StatusCol# " }},
        { text = { label_func} },
        { text = { "%#StatusMark#" }},
        {
          sign = {
            name = { ".*" },
            maxwidth = 1,
            colwidth = 1,
            auto = false
          },
          hl = "StatusMark", -- This forces the segment to use your custom group
        },
        { text = { ' ', statusBorderBump}, hl = "MonoGlowStatusColumnBorder" },
        -- { text = { noHighlight },
        { text = { "%#NoColor#" }},
      }
    })
  end,
}
