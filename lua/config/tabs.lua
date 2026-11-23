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

-- =============================================================================
--  Group categories (Emacs my/tab-group-categories -> nvim filetypes)
-- =============================================================================

-- Groups: a label mapped to the list of nvim filetypes that belong to it.
-- Icons are hardcoded separately in GROUP_ICONS (no mini.icons dependency).
local GROUPS = {
  Code = {
    "lua", "python", "go", "rust", "java", "c", "cpp", "javascript",
    "typescript", "javascriptreact", "typescriptreact", "css", "scss", "html",
    "json", "jsonc", "yaml", "sql", "nix", "sh", "bash", "zsh", "fish",
    "vim", "ruby", "php", "kotlin", "swift", "haskell",
  },
  FileMgr = { "oil" },
  Docs = { "markdown", "text", "org", "rst", "latex", "tex" },
  Config = { "conf", "dotenv", "toml", "ini", "gitcommit", "gitrebase" },
  Terminal = { "terminal" },
  Broot = { "broot" },
  Tools = { "help", "fugitive", "fugitiveblame", "diff", "git", "man", "qf" },
}

local FALLBACK_GROUP = "Buffers"

--- Classify a buffer by its FILETYPE (no buftype).  Returns the group label,
--- or the fallback "Buffers" when the filetype is not in any group.
local function group_for_buffer(bufnr)
  local ft = vim.bo[bufnr].filetype or ""
  for label, fts in pairs(GROUPS) do
    for _, f in ipairs(fts) do
      if f == ft then
        return label
      end
    end
  end
  return FALLBACK_GROUP
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

--- Return the icon for the CURRENT buffer's filetype (via nvim-web-devicons).
local function current_file_icon(bufnr)
  local ok, dev = pcall(require, "nvim-web-devicons")
  if not ok or not dev or not dev.get_icon then
    return ""
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  local ft = vim.bo[bufnr].filetype
  local icon = dev.get_icon(name, ft)
  return icon or ""
end

-- =============================================================================
--  Buffer list (Emacs my/ct--visible-buffers)
-- =============================================================================

local function visible_buffers()
  local result = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
      local name = vim.api.nvim_buf_get_name(bufnr)
      -- Skip scratch/messages/unlisted-style (mirrors Emacs exclusion).
      local bname = vim.fn.bufname(bufnr)
      if name ~= "" and bname ~= "[No Name]" and not bname:match("^%*") then
        table.insert(result, bufnr)
      end
    end
  end
  return result
end

-- =============================================================================
--  MRU ordering (per group)
-- =============================================================================

-- Store per-group MRU order: { [group] = { [bufnr] = timestamp } }
local mru_ts = {}
local function touch(bufnr)
  mru_ts[bufnr] = vim.uv.hrtime()
end

--- Return the buffers of GROUP, ordered most-recently-used first.
local function mru_group(group)
  local bufs = {}
  for _, bufnr in ipairs(visible_buffers()) do
    if group_for_buffer(bufnr) == group then
      bufs[#bufs + 1] = bufnr
    end
  end
  table.sort(bufs, function(a, b)
    return (mru_ts[a] or 0) > (mru_ts[b] or 0)
  end)
  return bufs
end

-- =============================================================================
--  Rendering
-- =============================================================================

local function highlight(group, text)
  return "%#" .. group .. "#" .. text
end

--- Stable buffer identity: a clean 1..N number derived from buffer CREATION
--- ORDER (nvim bufnr is monotonically increasing), so numbers stay stable per
--- buffer and never re-number when others open/close.  Scratch/internal buffers
--- still advance the bufnr counter, but we only NUMBER listed buffers, so the
--- visible numbers are clean 1..N in creation order.
local stable_number = {} -- bufnr -> number
local function rebuild_stable_numbers()
  stable_number = {}
  -- Listed buffers, sorted by bufnr ascending (= creation order).
  local listed = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].buflisted then
      listed[#listed + 1] = bufnr
    end
  end
  table.sort(listed)
  for i, bufnr in ipairs(listed) do
    stable_number[bufnr] = i
  end
end
local function get_stable_number(bufnr)
  if not stable_number[bufnr] then
    rebuild_stable_numbers()
  end
  return stable_number[bufnr]
end

--- Tab label: stable number + modified marker + powerline lead + name.
local function tab_label(bufnr, selected)
  local modified = vim.bo[bufnr].modified
  local prefix = modified and "󰑧 " or ""
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
  if name == "" then name = vim.fn.bufname(bufnr) end
  local num = get_stable_number(bufnr)
  local label = " " .. num .. "󱗹 " .. prefix .. name
  local hl = selected and "TabSelected" or "TabUnselected"
  return highlight(hl, label)
end

--- Overflow icon (Emacs my/ct--overflow-str).
local overflow_icons = { " ", "󰲠", "󰲢", "󰲤", "󰲦", "󰲨", "󰲪", "󰲬", "󰲮", "󰲰", "󰲲" }
local function overflow_str(n)
  return " " .. (overflow_icons[math.min(n, 10)] or overflow_icons[10])
end

--- Group icon + line-number segment (Emacs my/ct--group-icon).
--- The leading icon is the overflow glyph 󰲠 (replaces the per-group icon).
local function group_icon_segment(group, lnum)
  local icon = "󰲠"
  local line_str = tostring(lnum)
  -- 6-char hyphen-padded (Emacs pads to 6 with hyphens).
  local padded = line_str
  while #padded < 6 do padded = "-" .. padded end

  return highlight("TabGroupIcon", "  " .. icon .. " ")
    .. highlight("TabGroupSep", "")
    .. highlight("TabGroupLnum", " " .. padded .. " ")
    .. highlight("TabGroupLnum", "")
end

--- Main render function for a window's winbar (PURE — does not mutate state).
local function render(winid)
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local group = group_for_buffer(bufnr)
  local lnum = vim.api.nvim_win_get_cursor(winid)[1]

  local buf_list = mru_group(group)
  -- Always show the CURRENT buffer's tab, even if it isn't in the
  -- visible_buffers() list.  This prevents the winbar from vanishing entirely.
  local current_present = false
  for _, b in ipairs(buf_list) do
    if b == bufnr then current_present = true break end
  end
  if not current_present then
    table.insert(buf_list, 1, bufnr)
  end
  if #buf_list == 0 then
    buf_list = { bufnr }
  end

  -- Move the CURRENT buffer to the FRONT (leftmost), exactly like Emacs
  -- MRU-tabs.el does: (delq win-buf) then (cons win-buf).  This must NOT
  -- mutate mru_ts (that would cause re-render flashing); it only reorders the
  -- local copy for display.
  for i, b in ipairs(buf_list) do
    if b == bufnr then
      table.remove(buf_list, i)
      table.insert(buf_list, 1, bufnr)
      break
    end
  end

  local win_width = vim.api.nvim_win_get_width(winid)
  local icon_str = group_icon_segment(group, lnum)
  -- Append the CURRENT file's icon right after the line-number segment (before
  -- the first tab's powerline lead).
  local ficon = current_file_icon(bufnr)
  if ficon ~= "" then
    icon_str = icon_str .. highlight("TabGroupIcon", " " .. ficon .. " ")
  end
  local icon_width = vim.fn.strdisplaywidth(icon_str:gsub("%%#.-#", ""):gsub("%%%*", ""))

  -- Build tab segments.
  local segments = {}
  for _, b in ipairs(buf_list) do
    local sel = (b == bufnr)
    local label = tab_label(b, sel)
    local sep = highlight(sel and "TabSelected" or "TabUnselected", " ")
    segments[#segments + 1] = { label = label, sep = sep, bufnr = b, sel = sel }
  end

  -- Trim RIGHTMOST non-selected tabs until everything fits (Emacs
  -- MRU-tabs.el `nbutlast` logic).  The current buffer is ALREADY leftmost,
  -- so trimming from the right always keeps it visible and renders strictly
  -- left-to-right (never shifts the bar rightward).
  local avail = win_width - icon_width
  local hidden = 0
  local function dispwidth(s)
    return vim.fn.strdisplaywidth(s:gsub("%%#.-#", ""):gsub("%%%*", ""))
  end
  local function total_w(segs)
    local w = 0
    for _, s in ipairs(segs) do
      w = w + dispwidth(s.label) + dispwidth(s.sep)
    end
    return w
  end
  while total_w(segments) + dispwidth(overflow_str(hidden + 1)) > avail
    and #segments > 1 do
    table.remove(segments) -- remove RIGHTMOST
    hidden = hidden + 1
  end

  -- Build flat output (left-to-right).
  local out = icon_str
  for i, s in ipairs(segments) do
    out = out .. s.label
    if i < #segments then
      out = out .. s.sep
    end
  end
  if #segments > 0 then
    out = out .. segments[#segments].sep
    -- Reset highlight so the trailing spaces after the last separ are invisible.
    out = out .. "%#TabEmpty#"
  end

  if hidden > 0 then
    out = out .. highlight("TabOverflow", overflow_str(hidden))
  end

  return out
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
    TabGroupSep      = { fg = "#2b2b2b", bg = "#ff4400" },
    TabGroupLnum     = { fg = "#2b2b2b", bg = "#ff4400", bold = true },
    TabSelected      = { fg = "#2b2b2b", bg = "#8c8c8c", bold = true },
    TabUnselected    = { fg = "#2b2b2b", bg = "#5c5c5c" },
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

  -- Track MRU on buffer enter.
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
      touch(vim.api.nvim_get_current_buf())
    end,
  })

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

return M
