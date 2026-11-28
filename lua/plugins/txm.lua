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
  config = function()
    local txm = require("txm")

    -- Strip ANSI escape sequences (SGR: `\27[...m`) that the `txm` CLI emits
    -- for italics/color.  These render literally as `^[[3m` garbage in the
    -- virtual-text / floating buffers.  `txm` emits ANSI unconditionally (it
    -- ignores NO_COLOR/TERM=dumb/non-TTY), so we clean every line in Lua.
    local function strip(s)
      return (s:gsub("\27%[[%d;]*m", ""))
    end

    --- Same helper as the plugin's local `offset_to_line`.
    local function offset_to_line(lines, offset)
      local pos = 0
      for lnum, line in ipairs(lines) do
        pos = pos + #line + 1
        if offset <= pos then
          return lnum - 1
        end
      end
      return #lines - 1
    end

    local parser = require("txm.parser")
    local ns = vim.api.nvim_create_namespace("txm")
    local group = vim.api.nvim_create_augroup("txm-strip", { clear = true })

    -- Override `render` to strip ANSI from each virtual line.
    txm.render = function()
      local buf = vim.api.nvim_get_current_buf()
      txm.clear(true)
      vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
        group = group,
        buffer = buf,
        callback = function()
          txm.render()
        end,
      })
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local text = table.concat(lines, "\n")
      for _, r in ipairs(parser.find_latex(text)) do
        local content = vim.trim(r.content)
        if content ~= "" then
          local out = vim.fn.systemlist({ "txm", content })
          local virt = {}
          for _, l in ipairs(out) do
            virt[#virt + 1] = { { strip(l), "Comment" } }
          end
          if #virt > 0 then
            vim.api.nvim_buf_set_extmark(buf, ns, offset_to_line(lines, r.e), 0, {
              virt_lines = virt,
            })
          end
        end
      end
    end

    -- Override `preview` to strip ANSI from the floating scratchpad lines.
    txm.preview = function()
      vim.cmd('noautocmd normal! "zy')
      local text = vim.fn.getreg("z")
      vim.fn.setreg("z", "")
      local out = vim.fn.systemlist({ "txm", "--unboxed", text })
      for i, l in ipairs(out) do
        out[i] = strip(l)
      end
      local pad_str = string.rep(" ", 4)
      out = vim.tbl_map(function(line) return pad_str .. line end, out)
      out = vim.list_extend(vim.list_extend({ "" }, out), { "" })
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
      local width = math.min(vim.fn.max(vim.tbl_map(vim.fn.strdisplaywidth, out)), math.floor(vim.o.columns * 0.8))
      local height = math.min(#out, math.floor(vim.o.lines * 0.8))
      local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width + 4,
        height = height,
        row = (vim.o.lines - height) / 2,
        col = (vim.o.columns - width) / 2,
        border = "single",
        title = " txm ",
        title_pos = "center",
        style = "minimal",
      })
      vim.bo[buf].modifiable = false
      vim.wo[win].winhighlight = "NormalFloat:Normal,FloatBorder:Normal,FloatTitle:Normal"
      vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = buf })
    end
  end,
}
