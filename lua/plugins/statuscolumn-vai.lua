return {
  "luukvbaal/statuscol.nvim",
  dependencies = {
    -- vai.nvim is no longer used for labels/jumping: the static single-char
    -- labeling + jump reader are implemented in lua/config/statuscolumn.lua.
    -- We keep this dependency list empty of vai so it is not auto-loaded.
  },
  config = function()
    -- Delegate the entire statuscolumn to our port (lua/config/statuscolumn.lua),
    -- which reproduces emacs/statuscolumn.el: static top-to-bottom letter labels,
    -- marks, search-instance counter, scrollbar slice, wrap icon, bolt, and the
    -- `┣`/`┃` current-line bump.
    require("config.statuscolumn").setup()
  end,
}
