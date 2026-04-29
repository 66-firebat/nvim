-- return {
--     lazy = false,
--     "benlubas/molten-nvim",
--     version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
--     build = ":UpdateRemotePlugins",
--     init = function()
--         -- this is an example, not a default. Please see the readme for more configuration options
--         vim.g.molten_output_win_max_height = 12
--     end,
-- }
--
return {
  "benlubas/molten-nvim",
  version = "^1.0.0", -- use version 1.x for stability
  build = ":UpdateRemotePlugins",
  init = function()
    -- These are required for Molten to work properly
    vim.g.molten_image_provider = "image.nvim" -- Optional: if you want to see Blender renders in Neovim
    vim.g.molten_output_win_max_height = 20
  end,
  config = function()
    -- Keymap to connect to your Blender Kernel. The default value is a hardcoded path to the expected lcoation of the kernel's json file
    vim.keymap.set("n", "<leader>mc", function()
      vim.ui.input({ prompt = 'Path to Blender Kernel JSON: ', default = '/home/wytchblade/.config/blender/5.0/extensions/.user/user_default/bpy_jupyter/.jupyter_connection_cache/bpy-jupyter-kernel-connection.json' },

      function(input)
        if input then
          vim.cmd("MoltenInit " .. input)
        end
      end)

    end, { desc = "[molten-nvim]: Connect to Jupyter Kernel (default=bpy_jupyter kernel)" })

    -- 2. Standard Cell Execution Keymaps
    vim.keymap.set("n", "<leader>mi", ":MoltenInit<CR>", { desc = "[molten-nvim]: Initialize Molten" })
    vim.keymap.set("n", "<leader>mr", ":MoltenRestart!<CR>", { desc = "[molten-nvim]: Restart Molten Kernel" })
    vim.keymap.set("n", "<leader>mo", ":MoltenEvaluateOperator<CR>", { desc = "[molten-nvim]: Evaluate Operator" })
    vim.keymap.set("n", "<leader>ml", ":MoltenEvaluateLine<CR>", { desc = "[molten-nvim]: Run Line" })
    vim.keymap.set("v", "<leader>mv", ":<C-u>MoltenEvaluateVisual<CR>gv", { desc = "[molten-nvim]: Run Visual Selection" })
    -- vim.keymap.set("n", "<leader>rd", ":MoltenDelete<CR>", { desc = "Delete Cell" })
    vim.keymap.set("n", "<leader>mh", ":MoltenHideOutput<CR>", { desc = "[molten-nvim]: Hide Output" })
    vim.keymap.set("n", "<leader>ms", ":MoltenShowOutput<CR>", { desc = "[molten-nvim]: Show Output" })
    vim.keymap.set("n", "<leader>me", ":MoltenEnterOutput<CR>", { desc = "[molten-nvim]: Enter Output" })
    vim.keymap.set("n", "<leader>mi", ":MoltenImagePopup<CR>", { desc = "[molten-nvim]: Image Popup" })

    -- 3. Automatic "Enter" behavior
    -- This makes it so if you are in a cell output, 'q' closes it
    -- vim.api.nvim_create_autocmd("FileType", {
    --   pattern = "molten_output",
    --   callback = function()
    --     vim.keymap.set("n", "q", ":MoltenHideOutput<CR>", { buffer = true })
    --   end,
    -- })
  end,
}
