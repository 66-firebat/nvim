return {
  {
    "t9md/vim-textmanip",
    config = function()
      -- Helper function for mapping
      local function map(mode, lhs, rhs)
        vim.keymap.set(mode, lhs, rhs, { silent = true })
      end

      -- 1. Visual mode mappings (Moving selected text)
      -- This allows you to drag blocks of text around with Ctrl + HJKL
      map("x", "<C-j>", "<Plug>(textmanip-move-down)")
      map("x", "<C-k>", "<Plug>(textmanip-move-up)")
      map("x", "<C-h>", "<Plug>(textmanip-move-left)")
      map("x", "<C-l>", "<Plug>(textmanip-move-right)")

      -- 2. Toggle Mapping (Duplicate text while moving)
      -- Pressing <Space> while in Visual mode toggles "duplicate" mode
      map("x", "<Space>", "<Plug>(textmanip-toggle-mode)")

      -- 3. Normal mode mappings (Duplicate lines)
      -- This clones the current line up or down
      map("n", "<C-j>", "<Plug>(textmanip-duplicate-down)")
      map("n", "<C-k>", "<Plug>(textmanip-duplicate-up)")
    end,
  },
}
