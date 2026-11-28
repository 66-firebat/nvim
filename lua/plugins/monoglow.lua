return {
  "wnkz/monoglow.nvim",
  lazy = false,
  priority = 1000,
  opts = {

    on_colors = function(colors)
      colors.glow = "#ff4400"
    end,

    -- Color the RAW LaTeX math (as revealed by math-conceal when scrubbing the
    -- cursor) with the monoglow glow green, so equations stand out from the
    -- gray body text.  monoglow-z's syntax colors are all gray; these re-map
    -- the math tokens to #1bfd9c (the original monoglow glow) so the source is
    -- visibly highlighted while editing.  NOTE: this is independent of the
    -- global `colors.glow = "#ff4400"` override above.
    on_highlights = function(highlights, colors)
      local glow = "#1bfd9c"
      local math_tokens = {
        "@function",           -- \alpha, \int, \frac (LaTeX commands)
        "@function.builtin",   -- built-in math functions
        "@function.call",
        "@constant",           -- greek letters / math constants
        "@constant.builtin",
        "@number",             -- digits in sub/superscripts
        "@number.float",
        "@operator",           -- + - = < > etc.
        "@markup.math",        -- the $...$ math environment wrapper
        "@string.special",
      }
      for _, group in ipairs(math_tokens) do
        highlights[group] = { fg = glow }
      end
    end,

  },
}
