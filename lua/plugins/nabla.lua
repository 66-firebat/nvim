-- =============================================================================
--  nabla.nvim — render the LaTeX equation under the cursor in a popup.
--
--  On-demand only: nothing is loaded until <leader>J is pressed, at which point
--  the popup shows the math zone the cursor is inside.  Works in normal and
--  visual mode (visual renders the selection).
--
--  NOTE: this plugin needs the `latex` tree-sitter parser for non-markdown
--  buffers (`utils.lua` calls `vim.treesitter.get_parser(buf, "latex")`), and
--  the `markdown` parser for markdown buffers.  Both are present here; install
--  with `:TSInstall latex` if not.
--
--  (Previously this spec also pulled in neo-tree and mason, which nabla does not
--  use, and called `nvim-treesitter.configs.setup()` — that second setup call
--  overwrote the main treesitter configuration in lua/plugins/nvim-treesitter.lua.
--  Both were removed.)
-- =============================================================================

return {
  "jbyuki/nabla.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  lazy = true,
  keys = {
    {
      "<leader>J",
      function() require("nabla").popup() end,
      desc = "Nabla popup",
      mode = { "n", "v" },
    },
  },
}
