-- marks.nvim is DISABLED.  It binds `m` (and m1, m2, ...) which conflicts with
-- the custom mark system in lua/config/statuscolumn.lua (m -> M.set_mark).
-- Disabling it prevents marks.nvim from shadowing our `m` keybinding.
return {}
