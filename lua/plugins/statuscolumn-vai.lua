-- statuscol.nvim is NO LONGER USED.  The statuscolumn is now rendered by
-- lua/config/statuscolumn.lua directly via `vim.o.statuscolumn` (no caching
-- layer), so mark/label/gitsign updates render immediately on every redraw.
--
-- This file is kept as a disabled/empty spec so lazy.nvim does not install
-- statuscol.nvim anymore.  Do not delete it.

return {}
