-- =============================================================================
--  tabs.lua — per-window grouped MRU tab bar (port of emacs/MRU-tabs.el)
--
--  Renders a header line (winbar) for EACH window showing:
--    [group icon] [line number]  tab1 tab2 tab3 ... [overflow]
--
--  Faithfully mirrors emacs/MRU-tabs.el:
--    - Buffers are grouped by filetype/buftype into categories (Code, Docs,
--      Config, Terminal, etc.).
--    - Within the current group, tabs are MRU-ordered (most recently used first).
--    - Each tab shows a modified marker and is separated by a powerline glyph.
--    - The far-left segment is the group icon + 6-char (hyphen-padded) line number.
--    - Tabs that don't fit are trimmed and shown as an overflow icon.
--
--  This is PER-WINDOW (like Emacs header-line-format), so it renders via
--  `vim.wo.winbar` rather than lualine's global tabline.
--
--  API:
--      require("config.tabs").setup()        -- enable globally
--      require("config.tabs").forward()      -- cycle to next tab (M-l)
--      require("config.tabs").backward()     -- cycle to prev tab (M-h)
-- =============================================================================

local M = {}

-- Shared reusable functions (filetype->group map, buffer_count_icon, etc.).
local R = require("config.reusable_functions")

-- =============================================================================
--  Group categories (Emacs my/tab-group-categories -> nvim filetypes)
-- =============================================================================

-- Groups and filetype->group classification now live in
-- config/reusable_functions.lua (M.group_for_buffer).  tabs.lua consumes it.
local function group_for_buffer(bufnr)
  return R.group_for_buffer(bufnr)
end

--- Hardcoded icon per group (no mini.icons dependency).  The fallback covers
--- the "Buffers" catch-all and any group without an explicit icon.
local GROUP_ICONS = {
  Code     = "󰣕",
  FileMgr  = "󰏇",
  Docs     = "",
  Config   = "",
  Terminal = "",
  Broot    = "󰙅",
  Tools    = "",
}

local FALLBACK_ICON = ""

--- Return the hardcoded icon for a GROUP label (falls back to the catch-all).
local function group_icon(group)
  return GROUP_ICONS[group] or FALLBACK_ICON
end

--- Filetype icon now lives in reusable_functions.lua (M.filetype_icon).
local function current_file_icon(bufnr)
  return R.filetype_icon(bufnr)
end

-- =============================================================================
--  Buffer list / MRU ordering  — SUPERSEDED by config/mru.lua (§8b)
-- =============================================================================
-- The old per-group timestamp model was replaced by a single GLOBAL MRU list
-- owned by `config.mru`.  The original implementation is kept commented below
-- for reference; it will be deleted during the final cleanup pass.
--
-- local function visible_buffers()
--   local result = {}
--   for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
--     if vim.api.nvim_buf_is_loaded(bufnr) then
--       local ft = vim.bo[bufnr].filetype
--       -- Oil directory buffers are `buflisted = false`, but we DO want every
--       -- oil buffer to show as a tab in the FileMgr group.  Include them here.
--       local is_oil = ft == "oil"
--       if vim.bo[bufnr].buflisted or is_oil then
--         local name = vim.api.nvim_buf_get_name(bufnr)
--         -- Skip scratch/messages/unlisted-style (mirrors Emacs exclusion).
--         local bname = vim.fn.bufname(bufnr)
--         if name ~= "" and bname ~= "[No Name]" and not bname:match("^%*") then
--           table.insert(result, bufnr)
--         end
--       end
--     end
--   end
--   return result
-- end
--
-- -- Store per-group MRU order: { [group] = { [bufnr] = timestamp } }
-- local mru_ts = {}
-- local function touch(bufnr)
--   mru_ts[bufnr] = vim.uv.hrtime()
-- end
--
-- --- Return the buffers of GROUP, ordered most-recently-used first.
-- local function mru_group(group)
--   local bufs = {}
--   for _, bufnr in ipairs(visible_buffers()) do
--     if group_for_buffer(bufnr) == group then
--       bufs[#bufs + 1] = bufnr
--     end
--   end
--   table.sort(bufs, function(a, b)
--     return (mru_ts[a] or 0) > (mru_ts[b] or 0)
--   end)
--   return bufs
-- end

local MRU = require("config.mru")

--- Return the buffers of GROUP in ASCENDING GLOBAL MRU RANK order.
--- The number shown on each tab is that global rank (design Q1/Q3), so a group
--- can legitimately display non-contiguous numbers (1, 4, 9).
---@param group string
---@return integer[]
local function mru_group(group)
  local bufs = {}
  for _, bufnr in ipairs(MRU.list()) do
    if group_for_buffer(bufnr) == group then
      bufs[#bufs + 1] = bufnr
    end
  end
  -- MRU.list() is already MRU-first; ranks ascend in that same order.
  return bufs
end

-- =============================================================================
--  Rendering
-- =============================================================================

local function highlight(group, text)
  return "%#" .. group .. "#" .. text
end

--- Stable buffer identity.  SUPERSEDED by `mru.rank()` (§8b): the number is
--- now the buffer's 1-based position in the GLOBAL MRU list (mutable, no gaps,
--- shifts on every change).  The old creation-order implementation is kept
--- commented for reference; it will be deleted during the final cleanup pass.
--
-- local stable_number = {} -- bufnr -> number
-- local function rebuild_stable_numbers()
--   stable_number = {}
--   -- Listed buffers, sorted by bufnr ascending (= creation order).
--   local listed = {}
--   for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
--     if vim.bo[bufnr].buflisted then
--       listed[#listed + 1] = bufnr
--     end
--   end
--   table.sort(listed)
--   for i, bufnr in ipairs(listed) do
--     stable_number[bufnr] = i
--   end
-- end
-- local function get_stable_number(bufnr)
--   if not stable_number[bufnr] then
--     rebuild_stable_numbers()
--   end
--   return stable_number[bufnr] or bufnr
-- end

--- Global MRU rank of BUFNR (1-based), or nil when untracked.
---@param bufnr integer
---@return integer|string
local function get_stable_number(bufnr)
  return MRU.rank(bufnr) or "?"
end

--- Tab label: global MRU rank + modified marker + powerline lead + name.
--- Format is IDENTICAL for every buffer type (design Q18):
---     "<rank>  <name>"
--- where `name` is:
---   * terminal -> its live foreground program (e.g. "bash", "nvim")
---   * oil      -> the directory's basename
---   * file     -> the file's basename
local function tab_label(bufnr, selected)
  local modified = vim.bo[bufnr].modified
  local prefix = modified and "󰑧 " or ""
  local buftype = vim.bo[bufnr].buftype
  local name

  if buftype == "terminal" then
    -- Terminals show "<prog>:<cwd-basename>" (e.g. "bash:nvim") — the
    -- foreground program + the last cwd component, so multiple terminals are
    -- distinguishable at a glance (kept in sync with the <M-i> picker).
    name = MRU.terminal_name(bufnr)
  elseif vim.bo[bufnr].filetype == "oil" then
    -- Oil buffer names look like `oil:///path/to/dir/`.  Show only the
    -- directory's basename (e.g. `/home/u/proj` -> `proj`); fall back to the
    -- home-abbreviated path for a filesystem root or empty basename.
    local raw = vim.api.nvim_buf_get_name(bufnr)
    local dir = raw:gsub("^oil://", ""):gsub("/+$", "")
    if dir == "" then dir = "/" end
    name = vim.fn.fnamemodify(dir, ":t")
    if name == "" then name = vim.fn.fnamemodify(dir, ":~") end
    if name == "" then name = dir end
  else
    name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
    if name == "" then name = vim.fn.bufname(bufnr) end
  end

  local num = get_stable_number(bufnr)
  local label = MRU.rank_label(num)
  -- Layout:  <label> <sep> <name> <sep> <filetype icon>
  -- e.g.     aa <sep> bash <sep>   
  -- The filetype icon sits at the END, after the name, separated by its own
  -- separator.  (It used to live in lualine segment A; that slot now shows the
  -- scrollbar-thumb slice icon instead.)
  local icon = R.filetype_icon(bufnr)
  local tail
  if icon and icon ~= "" then
    tail = "  " .. icon .. " "
  else
    tail = ""
  end
  local body = " " .. label .. "  " .. prefix .. name .. tail
  local hl = selected and "TabSelected" or "TabUnselected"
  return highlight(hl, body)
end

--- Group icon segment (the line-number segment removed).
--- The leading glyph is the overflow glyph for the NUMBER OF BUFFERS in the
--- current group, matching Emacs MRU-tabs.el.
local function group_icon_segment(group, count, lnum)
  local icon = R.buffer_count_icon(count)
  return highlight("TabCountLead", "█")
    .. highlight("TabGroupIcon", icon .. " ")
end

--- Main render function for a window's winbar (PURE — does not mutate state).
---
--- Group follows the WINDOW'S buffer (design Q4 option c): the window always
--- shows the group its current buffer belongs to, and NO foreign tab is
--- force-inserted.  Members are listed in ASCENDING GLOBAL MRU RANK order;
--- the current buffer is always rank #1, so it is naturally leftmost.
local function render(winid)
  -- While a Snacks picker is open, its PREVIEW window shows a merely-
  -- highlighted buffer.  Display that buffer as the "current" tab so the
  -- tabline tracks the preview, WITHOUT changing MRU order (design option b;
  -- config/mru.lua suppresses reordering during previews).
  local win_buf = vim.api.nvim_win_get_buf(winid)
  local bufnr = win_buf
  -- Only the window that OPENED the picker follows its preview.  Applying this
  -- to every window made ALL split winbars show the previewed buffer's group,
  -- which is wrong: a split showing an unrelated buffer must keep its own tabs.
  local preview
  if MRU.preview_origin_window() == winid then
    preview = MRU.preview_buffer()
  end
  -- While this window owns an open picker previewing a REAL MRU member, the tab
  -- bar follows the PREVIEW: it shows that buffer as current AND switches to
  -- that buffer's GROUP (design option b).  The picker's own scratch/preview
  -- buffers are ignored via the `MRU.rank(preview)` check.
  if preview and MRU.rank(preview) then
    bufnr = preview
  end
  local group = group_for_buffer(bufnr)
  local lnum = vim.api.nvim_win_get_cursor(winid)[1]

  local buf_list = mru_group(group)

  -- Safety net: the current buffer may not be a tracked MRU member yet (e.g.
  -- a very fresh buffer).  Always show it so the winbar never renders empty.
  local current_present = false
  for _, b in ipairs(buf_list) do
    if b == bufnr then current_present = true break end
  end
  if not current_present then
    table.insert(buf_list, 1, bufnr)
  end

  -- Put the CURRENT buffer first (leftmost).  It is rank #1 globally, but if
  -- it is untracked it would otherwise sort arbitrarily.  This only reorders
  -- the LOCAL copy for display; it never mutates config/mru.lua state.
  for i, b in ipairs(buf_list) do
    if b == bufnr then
      table.remove(buf_list, i)
      table.insert(buf_list, 1, bufnr)
      break
    end
  end

  local win_width = vim.api.nvim_win_get_width(winid)
  local icon_str = group_icon_segment(group, #buf_list, lnum)
  M._last_debug = { winid = winid, bufnr = bufnr, group = group, mru = { unpack(buf_list) }, n = #buf_list }
  -- Separator between the buffer-count icon and the filetype icon.
  icon_str = icon_str .. highlight("TabCountSep", "")
  -- (filetype icon removed — it now lives in lualine segment A.)

  -- Build tab segments.
  local segments = {}
  for _, b in ipairs(buf_list) do
    local sel = (b == bufnr)
    local label = tab_label(b, sel)
    local hl = sel and "TabSelected" or "TabUnselected"
    local cap_hl = sel and "TabCapSel" or "TabCapUnsel"
    local sep = highlight(cap_hl, " ")
    local sep_between = highlight(cap_hl, " ") .. highlight("TabSepSecond", "")
    segments[#segments + 1] = { label = label, sep = sep, sep_between = sep_between, bufnr = b, sel = sel }
  end

  -- Trim RIGHTMOST non-selected tabs until everything fits (Emacs
  -- MRU-tabs.el `nbutlast` logic).  The current buffer is ALREADY leftmost,
  -- so trimming from the right always keeps it visible and renders strictly
  -- left-to-right (never shifts the bar rightward).
  --
  -- Width accounting MUST match the actual rendered string exactly, else the
  -- winbar overflows and Neovim paints its own `<` truncation marker on the
  -- left — swallowing the count icon + current tab.
  local function dispwidth(s)
    return vim.fn.strdisplaywidth(s:gsub("%%#.-#", ""):gsub("%%%*", ""))
  end

  -- Build the flat output for a given segment list, then measure its TRUE
  -- width (icon prefix + per-tab label + separators exactly as rendered).
  local function build_out(segs)
    local out = icon_str
    for i, s in ipairs(segs) do
      out = out .. s.label
      if i < #segs then
        out = out .. s.sep_between  -- two separators between tabs (3 cells)
      end
    end
    if #segs > 0 then
      out = out .. segs[#segs].sep  -- trailing separator (2 cells)
      out = out .. "%#TabEmpty#"
    end
    return out
  end

  -- Drop rightmost (never-leftmost/current) tabs until the REAL rendered
  -- string fits the window.  The leftmost tab is the current buffer; keep it
  -- at all costs so the count icon + current tab stay visible.
  while #segments > 1 and dispwidth(build_out(segments)) > win_width do
    table.remove(segments) -- remove RIGHTMOST
  end

  return build_out(segments)
end

-- =============================================================================
--  Cycling (Emacs my/ct--cycle / M-h / M-l)
-- =============================================================================

local function cycle(delta)
  local bufnr = vim.api.nvim_get_current_buf()
  local group = group_for_buffer(bufnr)
  local buf_list = mru_group(group)
  local idx = nil
  for i, b in ipairs(buf_list) do
    if b == bufnr then idx = i break end
  end
  if not idx then return end
  local n = #buf_list
  local next_i = ((idx - 1 + delta) % n) + 1
  vim.api.nvim_set_current_buf(buf_list[next_i])
end

function M.forward()
  cycle(1)
end

function M.backward()
  cycle(-1)
end

-- =============================================================================
--  Highlight groups
-- =============================================================================

local function ensure_highlights()
  local defs = {
    TabGroupIcon     = { fg = "#ff4400", bg = "#2b2b2b", bold = true },
    -- Leading cap before the count icon (space + 󱗸), blends into gutter bg.
    TabCountLead     = { fg = "#2b2b2b", bg = "#ff4400" },
    -- Separator between the count icon and the filetype icon.
    TabCountSep      = { fg = "#2b2b2b", bg = "#ff4400" },
    -- Filetype icon (inverted vs TabGroupIcon): dark fg on orange bg.
    TabFileIcon      = { fg = "#2b2b2b", bg = "#ff4400", bold = true },
    -- Powerline cap before the filetype icon: fg=#2b2b2b / bg=#ff4400.
    TabFileCap       = { fg = "#2b2b2b", bg = "#ff4400", bold = true },
    TabGroupSep      = { fg = "#2b2b2b", bg = "#ff4400" },
    TabGroupLnum     = { fg = "#2b2b2b", bg = "#ff4400", bold = true },
    TabSelected      = { fg = "#2b2b2b", bg = "#ff4400", bold = true },
    TabUnselected    = { fg = "#2b2b2b", bg = "#5c5c5c" },
    -- Right cap (`󱗴`) separated from the tab text, with its own highlight.
    TabCapSel        = { fg = "#2b2b2b", bg = "#ff4400", bold = true },
    TabCapUnsel      = { fg = "#2b2b2b", bg = "#5c5c5c" },
    -- Second separator glyph between tabs (independent highlight group).
    TabSepSecond     = { fg = "#5c5c5c", bg = "#2b2b2b" },
    -- Powerline lead glyph: selected lead is orange; non-selected lead is dark.
    TabLeadSel       = { fg = "#ff4400", bg = "#8c8c8c", bold = true },
    TabLeadUnsel     = { fg = "#2b2b2b", bg = "#5c5c5c" },
    TabOverflow      = { fg = "#ff4400", bg = "#2b2b2b", bold = true },
    TabModified      = { fg = "#ff4400", bg = "#2b2b2b" },
    -- Resets highlight so the trailing area after the last tab blends into the
    -- window/terminal background (no fg/bg).
    TabEmpty         = { fg = "#2b2b2b", bg = "#2b2b2b" },
  }
  for name, opts in pairs(defs) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

-- =============================================================================
--  Setup
-- =============================================================================

function M.setup()
  ensure_highlights()

  local group = vim.api.nvim_create_augroup("MRUTabs", { clear = true })

  -- Set winbar once per window (on enter).  The `%{...}` expression inside
  -- the winbar re-evaluates _render() on every redraw automatically, so we do
  -- NOT need to re-assign it on cursor moves / text changes.  We also skip
  -- floating windows (snacks pickers, popups) because they have no room for a
  -- winbar (that was the E36 "not enough room" source).
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "WinNew" }, {
    group = group,
    callback = function()
      local winid = vim.api.nvim_get_current_win()
      local cfg = vim.api.nvim_win_get_config(winid)
      if cfg.relative and cfg.relative ~= "" then
        -- Floating window: no winbar.
        vim.wo[winid].winbar = ""
        return
      end
      local height = vim.api.nvim_win_get_height(winid)
      if height < 3 then
        -- Too small for a meaningful winbar.
        vim.wo[winid].winbar = ""
        return
      end
      vim.wo[winid].winbar = "%{%v:lua.require('config.tabs')._render()%}"
    end,
  })

  -- NOTE: BufEnter MRU tracking was MOVED to config/mru.lua (§8b, design Q12a)
  -- — tabs.lua is now a pure reader of the global MRU list and owns no MRU
  -- state of its own.

  -- Apply to current window immediately.
  local winid = vim.api.nvim_get_current_win()
  vim.wo[winid].winbar = "%{%v:lua.require('config.tabs')._render()%}"

  vim.cmd("redraw")
end

--- Exposed for the winbar %{} expression (must be a plain Lua call).
function M._render()
  local winid = vim.api.nvim_get_current_win()
  return render(winid)
end

--- Diagnostic: dump the buffers in the current group (run
--- `:lua require('config.tabs').debug_group()`).
function M.debug_group()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(b)
    print(string.format("buf=%d listed=%s loaded=%s ft=%q group=%s name=%s",
      b, tostring(vim.bo[b].buflisted), tostring(vim.api.nvim_buf_is_loaded(b)),
      vim.bo[b].filetype, group_for_buffer(b), name))
  end
  if M._last_debug then
    print(string.format("RENDER: win=%d bufnr=%d group=%s n=%d mru=%s",
      M._last_debug.winid, M._last_debug.bufnr, M._last_debug.group,
      M._last_debug.n, vim.inspect(M._last_debug.mru)))
  end
end

return M
