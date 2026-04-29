return {
  "gbprod/yanky.nvim",
  dependencies = { "kkharji/sqlite.lua" },
  opts = {
    ring = {
      history_length = 100,
      storage = "shada",
    },
    system_clipboard = {
      sync_with_ring = true,
    },
    picker = {
      select = { action = nil },
      telescope = { enabled = false },
    },
  },
  keys = {
    { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put After" },
    { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put Before" },
    { "<c-p>", "<Plug>(YankyPutIndentAfterLinewise)", mode = { "n", "x" }, desc = "Linewise Put After" },
    { "<c-M-p>", "<Plug>(YankyPutIndentBeforeLinewise)", mode = { "n", "x" }, desc = "Linewise Put Before" },
    { "<M-p>", "<Plug>(YankyCycleForward)", desc = "Cycle Forward Yank History" },
    { "<M-n>", "<Plug>(YankyCycleBackward)", desc = "Cycle Backward Yank History" },
    -- Corrected picker call for Snacks
    { "<leader>py", function() Snacks.picker.yanky() end, desc = "Yank History" },
  },
  config = function(_, opts)
    require("yanky").setup(opts)

    -- -- Fixed Wayland Sync: Uses the correct path and prevents errors on startup
    -- vim.api.nvim_create_autocmd("FocusGained", {
    --   callback = function()
    --     -- In latest yanky, the sync logic is handled via the clipboard module
    --     local status, yanky_clipboard = pcall(require, "yanky.lib.clipboard")
    --     if status and yanky_clipboard.get_system_clipboard then
    --       -- This forces yanky to look at the system clipboard and 
    --       -- add it to the ring if it's new.
    --       yanky_clipboard.get_system_clipboard()
    --     end
    --   end,
    -- })

  end,
}
