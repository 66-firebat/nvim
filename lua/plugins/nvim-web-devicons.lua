-- =============================================================================
--  nvim-web-devicons — filetype icons used by the tabline, lualine, oil, etc.
--
--  Registered as an explicit plugin (rather than only a transitive dependency)
--  so we can configure custom icons in one place.
--
--  Lookup precedence (highest first):
--    override > override_by_filename > override_by_extension
--  There is no `override_by_filetype`; filetype lookups fall back to the
--  extension/filename tables, except for special entries like `terminal`.
-- =============================================================================

return {
  "nvim-tree/nvim-web-devicons",
  lazy = false, -- load eagerly; other plugins (lualine, oil) expect it available
  config = function()
    require("nvim-web-devicons").setup({
      override = {
        -- Terminals: a terminal buffer's filetype is `terminal`, so THIS is the
        -- key that controls the tab-bar icon for every terminal (the shell
        -- running inside is irrelevant).  `override_by_extension` cannot be
        -- used here — nothing looks up an extension for a terminal buffer.
        -- Test glyph: Nerd Font "console" (U+E795).  Swap back to 󰆍
        -- (U+F018D) if you prefer that one.
        terminal = { icon = "", color = "#ff4400", name = "Terminal" },
      },
      override_by_extension = {
        -- Custom / non-standard filetypes. Add more here as needed.
        hjson = { icon = "󰘓", color = "#ff4400", name = "Hjson" },
        -- yaml  = { icon = "", color = "#ff4400", name = "Yaml" },
        -- toml  = { icon = "", color = "#ff4400", name = "Toml" },
      },
    })
  end,
}
