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
      -- Using iblscope in the highlights.lua file
      -- highlight = {"Comment"},
      char = ""
    },
    indent = {
      -- Set the character to a vertical bar (or any character you prefer)
      char = "",
    },
  },
  config = function(_, opts)
    require("ibl").setup(opts)

    -- Re-sync ibl's derived @ibl.* highlight groups.  `IblIndent`/`IblScope`
    -- are set in config/highlight_groups/highlights.lua, but that file runs
    -- BEFORE the monoglow colorscheme (and ibl's first setup) loads, so ibl
    -- copies a stale color into @ibl.indent.char.1 / @ibl.scope.char.1.  The
    -- rendered indent/scope chars then ignore any later IblIndent/IblScope
    -- edits.  Re-running highlights.setup() (idempotent) re-reads the current
    -- values from the final highlight groups, so the chars match.
    local function resync()
      require("ibl.highlights").setup()
    end

    -- (1) after lazy init + the first colorscheme application settles
    vim.schedule(resync)
    -- (2) on every subsequent colorscheme load/reload, so the colors never
    --     drift stale again (e.g. after a manual `:colorscheme`).
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = resync,
    })
  end,
}


