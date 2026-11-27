-- =============================================================================
--  txm.nvim — LaTeX preview via the external `txm` CLI (Terminal TeX Math).
--
--  Two render modes:
--    * `<leader>Jt` / `:TxmToggle`   — whole-buffer inline preview as VIRTUAL
--      TEXT (auto-refreshes on TextChanged/InsertLeave, like mdmath but text).
--    * `<leader>Jp` (visual)         — select math, preview the selection in a
--      floating scratchpad buffer (via `<Plug>(TxmPreview)`).
--
--  NOTE: unlike nabla (pure-Lua inline ASCII), txm shells out to the Rust `txm`
--  binary on each render.  The binary is NOT bundled — it must be on PATH.
--  It is added to `home/fireshark.nix` (`home.packages = [ txm ]`).
--
--  Relationship to the other math renderers in this config:
--    * mdmath.nvim  — always-on raster/vector images (highest fidelity, slow).
--    * nabla        — on-demand popup of the cursor's equation (pure Lua).
--    * txm          — text (virtual-text) whole-buffer preview, cheap + fast.
--      `txm` overlaps most with nabla's `toggle_virt` (which we disabled due to
--      parser fragility); txm is the intended replacement for that use case.
-- =============================================================================

return {
  "rv178/txm.nvim",
  -- The plugin is lazy by default and only exposes commands + a <Plug> map;
  -- trigger it on those so nothing loads until a math preview is requested.
  -- (Its main module does no global setup that needs eager loading.)
  keys = {
    -- Toggle whole-buffer inline virtual-text preview.
    { "<leader>Jt", "<cmd>TxmToggle<CR>", desc = "txm: toggle buffer render" },
    -- Preview the visual selection in a floating scratchpad.
    { "<leader>Jp", "<Plug>(TxmPreview)", mode = "v", desc = "txm: preview selection" },
  },
  cmd = { "TxmRender", "TxmClear", "TxmToggle" },
  -- NOTE: the inline virtual text is hardcoded to the `Comment` highlight group
  -- in the plugin source (lua/txm/init.lua: `{{ l, 'Comment' }}`), which reads
  -- as dimmed/disabled text in most colorschemes.  Overriding it requires a
  -- fork or a post-load patch of `applied`.  Left as a follow-up (see TODO.md).
  --
  -- If the `txm` binary is missing, the commands still register but fail with a
  -- clear systemlist/ENOENT error — nothing else breaks.
}
