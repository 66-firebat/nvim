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
  -- Load lazily; the plugin's plugin/math-conceal.lua already registers a
  -- FileType hook, but setup() is still recommended to set conceal groups/ft.
  event = "VeryLazy",
  main = "math-conceal",
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
    },
  },
}
