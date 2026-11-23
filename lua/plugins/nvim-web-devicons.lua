-- =============================================================================
--  nvim-web-devicons — filetype icons used by the tabline, lualine, oil, etc.
--
--  Registered as an explicit plugin (rather than only a transitive dependency)
--  so we can configure custom icons (e.g. .hjson) in one place.
-- =============================================================================

return {
  "nvim-tree/nvim-web-devicons",
  lazy = false, -- load eagerly; other plugins (lualine, oil) expect it available
  config = function()
    require("nvim-web-devicons").setup({
      override_by_extension = {
        -- Custom / non-standard filetypes. Add more here as needed.
        hjson = { icon = "󰘓", color = "#ff4400", name = "Hjson" },
        -- yaml  = { icon = "", color = "#ff4400", name = "Yaml" },
        -- toml  = { icon = "", color = "#ff4400", name = "Toml" },
      },
    })
  end,
}
