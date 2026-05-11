return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  ---@module "ibl"
  ---@type ibl.config
  opts = {
    scope = {
      enabled = true,
      show_start = false,
      show_end = false,
      show_exact_scope = true,
      highlight = {"IndentColor"},
      char = "󰇙"
    },
    indent = {
      -- Set the character to a vertical bar (or any character you prefer)
      char = "󰇙",
    },
  },
}


