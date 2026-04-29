return {
  "NStefan002/screenkey.nvim",
  version = "*",
  -- event = "VeryLazy",
  lazy = false,
  opts = {
    win_opts = {
      height = 1,
    },
  },
  keys = {
    {
      "<leader>ut",
      "<CMD>Screenkey toggle_statusline_component<CR>",
      desc = "[screenkey: toggle screenkey]",
    },
  },
}

