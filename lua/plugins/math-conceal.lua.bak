-- =============================================================================
--  math-conceal.nvim — LaTeX + Typst symbol conceal (ASCII/Unicode + graphical).
--
--  Two render paths:
--    * ASCII/Unicode conceal — tree-sitter symbol replacement (greek, math,
--      font, delim, phy) via extmark conceal. No external binary needed.
--    * Graphical equation conceal — kitty-graphics-rendered equations, requires
--      the optional Rust `typst-concealer-service` binary (built via `build`).
--
--  NO commands and NO keymaps are exposed — this is a `setup()` + Lua-API
--  plugin that auto-attaches to configured filetypes via a FileType hook.
--
--  NOTE (relation to other math plugins in this config):
--    * mdmath.nvim  — raster images via ImageMagick/librsvg (already active).
--    * nabla (popup), txm (virtual text) — on-demand text renderers.
--    * math-conceal — replaces the *source* glyphs inline (conceal), which is a
--      DIFFERENT job: it hides `\alpha` and shows `α`, with optional graphical
--      overlay of whole equations.  It overlaps with nabla/txm in spirit but
--      operates through `:help conceallevel` rather than floating windows or
--      virtual text.
--
--  Graphical mode requires Neovim 0.11+ and a kitty-graphics terminal (Ghostty
--  supports it).  The Rust service is OPTIONAL — ASCII conceal works without it.
-- =============================================================================

return {
  "pxwg/math-conceal.nvim",
  -- Load on the math filetypes (NOT VeryLazy): the plugin's ASCII/Unicode
  -- conceal has no built-in FileType autocmd, so it must be loaded eagerly
  -- enough to attach to buffers as they open.  Triggering on the math
  -- filetypes keeps it lazy for everything else.
  ft = { "tex", "markdown", "typst", "plaintex", "context", "bibtex" },
  version = "*",
  -- Optional: build the Rust service for graphical equation conceal.  Requires
  -- Cargo/Rust.  Comment out to disable graphical mode (ASCII conceal still works).
  -- NOTE: this is a shell command, NOT a Lua function — the plugin has no
  -- `math-conceal.install` module (an earlier spec incorrectly used one).
  build = "cargo build --release --manifest-path service/Cargo.toml",
  opts = {
    conceal = {
      "greek",
      "script",
      "math",
      "font",
      "delim",
      "phy",
    },
    ft = { "plaintex", "tex", "context", "bibtex", "markdown", "typst" },
    opt = {
      conceallevel = 2,
      concealcursor = "n",
    },
    image = {
      enabled = true,
      -- Force the RENDERED IMAGE (the typst-composited equation shown above
      -- the raw source) to use the monoglow glow green.  With styling_type =
      -- "colorscheme" (default), the image color is derived from Normal.fg
      -- (gray #cccccc in monoglow-z); setting `color` overrides that with a
      -- typst color expression so the base image text is #1bfd9c.
      styling_type = "colorscheme",
      color = 'rgb("#ff4400")',
      -- Color the rendered image uniformly with #ff4400 (all typst math
      -- elements use the SAME color).  These `#show` rules are redundant with
      -- `color` but are kept explicit so every element is definitely #ff4400.
      renderers = {
        typst = {
          filetypes = { "typst" },
          header = [=[
#show math.attach: set text(fill: rgb("#ff4400"))
#show math.frac: set text(fill: rgb("#ff4400"))
#show math.op: set text(fill: rgb("#ff4400"))
#show math.accent: set text(fill: rgb("#ff4400"))
#show math.lr: set text(fill: rgb("#ff4400"))
]=],
        },
        markdown = {
          filetypes = { "markdown" },
          header = [=[
#show math.attach: set text(fill: rgb("#ff4400"))
#show math.frac: set text(fill: rgb("#ff4400"))
#show math.op: set text(fill: rgb("#ff4400"))
#show math.accent: set text(fill: rgb("#ff4400"))
#show math.lr: set text(fill: rgb("#ff4400"))
]=],
        },
      },
    },
    -- Colorize the RAW (un-concealed) LaTeX source so scrubbing the cursor
    -- over an equation shows syntax highlighting instead of the default
    -- `Conceal` group (which is dim/gray).  Each math-conceal capture is
    -- re-linked to a standard, monoglow-colored group.
    highlights = {
      -- environment / structure
      ["@_env"]          = { link = "Statement", default = false },
      ["@_frac_name"]    = { link = "Function",  default = false },
      ["@_func_name"]    = { link = "Function",  default = false },
      ["@_line"]         = { link = "Statement", default = false },
      ["@_tagged"]       = { link = "Statement", default = false },
      -- commands (\alpha, \int, \frac, ...)
      ["@cmd"]           = { link = "Keyword",   default = false },
      ["@cmd_escape"]    = { link = "Special",   default = false },
      ["@tex_math_command"] = { link = "Keyword", default = false },
      -- functions / names
      ["@func"]          = { link = "Function",  default = false },
      ["@func_name"]     = { link = "Function",  default = false },
      ["@abs_name"]      = { link = "Function",  default = false },
      -- symbols / operators
      ["@symbol"]        = { link = "Operator",  default = false },
      ["@tex_greek"]     = { link = "Identifier", default = false },
      ["@tex_font_name"] = { link = "Type",      default = false },
      ["@typ_greek_symbol"] = { link = "Identifier", default = false },
      ["@typ_math_symbol"]  = { link = "Operator",  default = false },
      ["@typ_math_font"]    = { link = "Type",      default = false },
      ["@typ_font_name"]    = { link = "Type",      default = false },
      ["@typ_symbol"]       = { link = "Operator",  default = false },
      ["@typ_phy_symbol"]   = { link = "Special",   default = false },
      -- sub/superscript letters + digits
      ["@sub_letter"]    = { link = "Identifier", default = false },
      ["@sub_digit"]     = { link = "Number",     default = false },
      ["@sup_letter"]    = { link = "Identifier", default = false },
      ["@sup_digit"]     = { link = "Number",     default = false },
      ["@sub_symbol"]    = { link = "Operator",   default = false },
      ["@sup_symbol"]    = { link = "Operator",   default = false },
      ["@sub_object"]    = { link = "Identifier", default = false },
      ["@sup_object"]    = { link = "Identifier", default = false },
      ["@first_letter"]  = { link = "Identifier", default = false },
      ["@second_letter"] = { link = "Identifier", default = false },
      ["@font_letter"]   = { link = "Identifier", default = false },
      ["@font_digit"]    = { link = "Number",     default = false },
      -- delimiters / parens / punctuation
      ["@open_paren"]     = { link = "Delimiter", default = false },
      ["@close_paren"]    = { link = "Delimiter", default = false },
      ["@left_paren"]     = { link = "Delimiter", default = false },
      ["@right_paren"]    = { link = "Delimiter", default = false },
      ["@left_paren_cmd"] = { link = "Delimiter", default = false },
      ["@right_paren_cmd"]= { link = "Delimiter", default = false },
      ["@left_brace"]     = { link = "Delimiter", default = false },
      ["@right_brace"]    = { link = "Delimiter", default = false },
      ["@left_1"]         = { link = "Delimiter", default = false },
      ["@left_2"]         = { link = "Delimiter", default = false },
      ["@right_1"]        = { link = "Delimiter", default = false },
      ["@right_2"]        = { link = "Delimiter", default = false },
      ["@left_content"]   = { link = "Identifier", default = false },
      ["@right_content"]  = { link = "Identifier", default = false },
      ["@content"]        = { link = "Identifier", default = false },
      ["@comma"]          = { link = "Delimiter", default = false },
      ["@punctuation"]    = { link = "Delimiter", default = false },
      ["@frac"]           = { link = "Operator",  default = false },
      -- typst inline markers
      ["@typ_inline_dollar"]    = { link = "Delimiter", default = false },
      ["@typ_inline_ampersand"] = { link = "Delimiter", default = false },
      ["@typ_inline_asterisk"]  = { link = "Special",   default = false },
      ["@typ_inline_quote"]     = { link = "Delimiter", default = false },
      ["@typ_math_delim"]       = { link = "Delimiter", default = false },
      ["@conceal_dollar"]       = { link = "Delimiter", default = false },
    },
  },
  -- IMPORTANT: `main = "math-conceal"` only merges config (the init.lua
  -- setup() does NOT wire the runtime).  The REAL runtime lives in
  -- `math-conceal.nvim`, whose module auto-runs init_runtime() on load — that
  -- is what applies conceallevel/attaches buffers/sets highlights.  Call it
  -- here (after config is merged) so window options and highlighting actually
  -- take effect.
  config = function(_, opts)
    require("math-conceal").setup(opts)
    local runtime = require("math-conceal.nvim")
    runtime.setup(opts)

    -- The plugin has NO FileType autocmd for ASCII/Unicode conceal (only the
    -- optional IMAGE renderer registers one).  Without this, newly-opened
    -- tex/markdown/typst buffers never get conceallevel set or the unicode
    -- surface attached — explaining the missing conceal + raw-source colors.
    local fts = opts.ft or {}
    if #fts > 0 then
      local group = vim.api.nvim_create_augroup("math-conceal.user-attach", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = fts,
        callback = function(ev)
          -- Set the window-local conceal options + attach the unicode/image
          -- surface for this buffer.
          runtime.set(ev.match, ev.buf)
        end,
      })
    end
  end,
}
