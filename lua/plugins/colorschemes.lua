return {
  {
    "sainnhe/gruvbox-material",
    enabled = true,
    priority = 1000,
    config = function()
      vim.g.gruvbox_material_transparent_background = 1
      vim.g.gruvbox_material_foreground = "mix"
      vim.g.gruvbox_material_background = "hard"
      vim.g.gruvbox_material_ui_contrast = "high"
      vim.g.gruvbox_material_float_style = "bright"
      vim.g.gruvbox_material_statusline_style = "mix" -- Options: "original", "material", "mix", "afterglow"
      vim.g.gruvbox_material_cursor = "auto"

      -- vim.g.gruvbox_material_colors_override = { bg0 = '#16181A' } -- #0e1010
      -- vim.g.gruvbox_material_better_performance = 1

      vim.cmd.colorscheme("gruvbox-material")

      -- Custom statusline highlights
      vim.api.nvim_set_hl(0, "StatusLine", {
        bg = "#2b2b2b", -- Darker background for inactive windows
        fg = "#ff6000", -- Light text
        bold = false
      })
      --
      vim.api.nvim_set_hl(0, "StatusLineNC", {
        bg = "#1C2021", -- Darker background for inactive windows
        fg = "#928374", -- Muted text
        bold = false
      })
      vim.api.nvim_set_hl(0, "StatusLineTerm", {
        bg = "#2b2b2b", -- Darker background for inactive windows
        fg = "#ff6000", -- Light text
        bold = false
      })
      vim.api.nvim_set_hl(0, "StatusLineTermNC", {
        bg = "#1C2021", -- Darker background for inactive windows
        fg = "#928374", -- Muted text
        bold = false
      })
      vim.api.nvim_set_hl(0, "WhichKeyNormal", {
        bg = "none", -- Darker background for inactive windows
        fg = "#ff6000", -- Muted text
        bold = false
      })
      vim.api.nvim_set_hl(0, "WhichKeyIconRed", {
        bg = "none", -- Darker background for inactive windows
        fg = "#ff6000", -- Muted text
        bold = false
      })
      vim.api.nvim_set_hl(0, "WhichKeyBorder", {
        bg = "none", -- Darker background for inactive windows
        fg = "#ff6000", -- Muted text
        bold = false
      })
      vim.api.nvim_set_hl(0, "Pmenu", {
        bg = "none", -- Darker background for inactive windows
        fg = "#ff6000", -- Muted text
        bold = false
      })
      vim.api.nvim_set_hl(0, "PmenuSel", {
        bg = "none", -- Darker background for inactive windows
        fg = "#ff6000", -- Muted text
        bold = false
      })
      vim.api.nvim_set_hl(0, "PmenuMatchSel", {
        bg = "none", -- Darker background for inactive windows
        fg = "#ff6000", -- Muted text
        bold = false
      })
      vim.api.nvim_set_hl(0, "PmenuMatch", {
        bg = "none", -- Darker background for inactive windows
        fg = "#ff6000", -- Muted text
        bold = false
      })
      vim.api.nvim_set_hl(0, "PmenuThumb", {
        bg = "none", -- Darker background for inactive windows
        fg = "#ff6000", -- Muted text
        bold = false
      })
      vim.api.nvim_set_hl(0, "PmenuSbar", {
        bg = "none", -- Darker background for inactive windows
        fg = "#ff6000", -- Muted text
        bold = false
      })
      vim.api.nvim_set_hl(0, "PmenuExtra", {
        bg = "none", -- Darker background for inactive windows
        fg = "#ff6000", -- Muted text
        bold = false
      })
      vim.api.nvim_set_hl(0, "WhichKeyTitle", {
        bg = "none", -- Darker background for inactive windows
        fg = "#ff6000", -- Muted text
        bold = false
      })
      vim.api.nvim_set_hl(0, "WhichKeyIconOrange", {
        bg = "none", -- Darker background for inactive windows
        fg = "#ff6000", -- Muted text
        bold = false
      })
      -- Changes the colors of text in the main window
      vim.api.nvim_set_hl(0, 'LineNr', { fg = '#ff6000', bg = 'none', blend = 5 })
      vim.api.nvim_set_hl(0, 'Normal', { fg = '#FF6000', bg = 'none' })
      -- vim.api.nvim_set_hl(0, 'CursorLine', { fg = 'none', bg = '#2b2b2b', blend = 5 })
      vim.api.nvim_set_hl(0, 'CursorLine', { fg = 'none', bg = 'none'})
      vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#ff6000', bg = 'none' })
      vim.api.nvim_set_hl(0, 'Visual', { fg = '#f4fd22', bg = '#2b2b2b'})
      vim.api.nvim_set_hl(0, 'MiniStatusLineModeNormal', { fg = '#ff6000', bg = '#80401a' })
      vim.api.nvim_set_hl(0, 'NoiceCmdLinePopupBorder', { fg = '#ff6000', bg = 'none' })
      vim.api.nvim_set_hl(0, 'SnacksPickerListCursorLine', { fg = '#ff6000', bg = '#80401a' })
      vim.api.nvim_set_hl(0, 'WhichKey', { fg = '#ff6000', bg = 'none' })
      vim.api.nvim_set_hl(0, 'SnacksPickerTitle', { fg = '#ff6000', bg = 'none' })
      vim.api.nvim_set_hl(0, 'FloatBorder', { fg = '#ff6000', bg = 'none' })
      vim.api.nvim_set_hl(0, 'VertSplit', { fg = '#80401a', bg = 'none' })
      vim.api.nvim_set_hl(0, 'Special', { fg = '#ff6000', bg = 'none' })
      vim.api.nvim_set_hl(0, 'SnacksPickerBoxBorder', { fg = '#ff6000', bg = 'none' })
      vim.api.nvim_set_hl(0, 'NoiceScrollbar', { fg = 'none', bg = 'white' })
      vim.api.nvim_set_hl(0, 'NoiceScrollbarThumb', { fg = 'none', bg = 'white' })
      vim.api.nvim_set_hl(0, 'PmenuSbar', { fg = 'none', bg = 'none' })
      vim.api.nvim_set_hl(0, 'PmenuThumb', { fg = 'none', bg = 'none' })
      vim.api.nvim_set_hl(0, 'MasonHighlightBlock', { fg = '#ff6000', bg = '#80401a' })
      vim.api.nvim_set_hl(0, 'MasonHighlightBlockBold', { fg = '#ff6000', bg = '#80401a' })
      vim.api.nvim_set_hl(0, 'MasonHeaderSecondary', { fg = '#ff6000', bg = '#80401a' })
      vim.api.nvim_set_hl(0, 'IblIndent', { fg = '#80401a' })
      vim.api.nvim_set_hl(0, 'SnacksPickerDirectory', { fg = '#ff6000', bg = 'none' })
      vim.api.nvim_set_hl(0, 'Comment', { fg = '#80401a', bg = 'none' })
      vim.api.nvim_set_hl(0, 'CursorColumn', { fg = 'none', bg = 'none' })
      vim.api.nvim_set_hl(0, 'Cursor', { fg = '#ff6000', bg = '#80401a' })
      vim.api.nvim_set_hl(0, 'Insert', { fg = '#ff6000', bg = '#80401a' })
      vim.api.nvim_set_hl(0, 'Whitespace', { fg = '#80401a', bg = 'none' })
      vim.api.nvim_set_hl(0, 'Title', { fg = '#ff6000', bg = 'none' })
      vim.api.nvim_set_hl(0, 'SignColumn', { fg = 'none', bg = 'none' })
      vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = 'none', bg = '#2b2b2b' })
      vim.api.nvim_set_hl(0, 'StatusColumnBorder', { fg = '#ff6000', bg = '#2b2b2b' })
      vim.api.nvim_set_hl(0, 'NoiceCursor', { fg = '#ff6000', bg = '#2b2b2b' })
      vim.api.nvim_set_hl(0, 'NoiceFormatConfirmDefault', { fg = '#ff6000', bg = '#2b2b2b' })
      vim.api.nvim_set_hl(0, 'SnacksPickerPrompt', { fg = '#ff6000', bg = '#2b2b2b' })
      vim.api.nvim_set_hl(0, 'SnacksPickerListCursorLine', { fg = '#2b2b2b', bg = '#80401a' })
      vim.api.nvim_set_hl(0, 'SnacksTitle', { fg = '#ff6000', bg = 'none' })
      vim.api.nvim_set_hl(0, 'SnacksPickerCol', { fg = '#ff6000', bg = 'none' })
      vim.api.nvim_set_hl(0, 'BarsBorder', { fg = '#ff6000', bg = 'none' })
      vim.api.nvim_set_hl(0, 'BarsCursorLineNr', { fg = '#2b2b2b', bg = '#ff6000' })
      vim.api.nvim_set_hl(0, 'Shadow10', { fg = '#2b2b2b', bg = '#e05806' })
      vim.api.nvim_set_hl(0, 'Shadow9', { fg = '#2b2b2b', bg = '#c4510c' })
      vim.api.nvim_set_hl(0, 'Shadow8', { fg = '#2b2b2b', bg = '#9d4714' })
      vim.api.nvim_set_hl(0, 'Shadow7', { fg = '#2b2b2b', bg = '#80401a' })
      vim.api.nvim_set_hl(0, 'Shadow6', { fg = '#2b2b2b', bg = '#643920' })
      vim.api.nvim_set_hl(0, 'Shadow5', { fg = '#2b2b2b', bg = '#4e3424' })
      vim.api.nvim_set_hl(0, 'Shadow4', { fg = '#2b2b2b', bg = '#473226' })
      vim.api.nvim_set_hl(0, 'Shadow3', { fg = '#2b2b2b', bg = '#413127' })
      vim.api.nvim_set_hl(0, 'Shadow2', { fg = '#2b2b2b', bg = '#3b2f28' })
      vim.api.nvim_set_hl(0, 'Shadow1', { fg = '#2b2b2b', bg = '#362e29' })
      vim.api.nvim_set_hl(0, 'Shadow0', { fg = '#2b2b2b', bg = 'none' })
      vim.api.nvim_set_hl(0, 'BorderShadow10', {fg = '#ff6000', bg = '#ff6000' })
      vim.api.nvim_set_hl(0, 'BorderShadow9', { fg = '#ff6000', bg = '#c4510c' })
      vim.api.nvim_set_hl(0, 'BorderShadow8', { fg = '#ff6000', bg = '#9d4714' })
      vim.api.nvim_set_hl(0, 'BorderShadow7', { fg = '#ff6000', bg = '#80401a' })
      vim.api.nvim_set_hl(0, 'BorderShadow6', { fg = '#ff6000', bg = '#643920' })
      vim.api.nvim_set_hl(0, 'BorderShadow5', { fg = '#ff6000', bg = '#4e3424' })
      vim.api.nvim_set_hl(0, 'BorderShadow4', { fg = '#ff6000', bg = '#473226' })
      vim.api.nvim_set_hl(0, 'BorderShadow3', { fg = '#ff6000', bg = '#413127' })
      vim.api.nvim_set_hl(0, 'BorderShadow2', { fg = '#ff6000', bg = '#3b2f28' })
      vim.api.nvim_set_hl(0, 'BorderShadow1', { fg = '#ff6000', bg = '#362e29' })
      vim.api.nvim_set_hl(0, 'BorderShadow0', { fg = '#ff6000', bg = 'none' })
      vim.api.nvim_set_hl(0, 'InlayHints', { bg = '#ff6000', fg = 'none' })
    end,
  },
  {
    'adibhanna/forest-night.nvim',
    priority = 1000,
    config = function()
      -- vim.cmd('colorscheme forest-night')
    end,
  },
  {
    "RRethy/base16-nvim",
    enabled = false,
    config = function()
      vim.cmd('colorscheme base16-ayu-mirage')

      -- Get the base16 colors after setting the colorscheme
      local colors = require('base16-colorscheme').colors

      -- Map base16 colors to catppuccin-like names for easier reference
      local ayu_colors = {
        -- Background colors
        base = colors.base00,     -- main background
        mantle = colors.base01,   -- darker background for floating windows
        surface0 = colors.base02, -- surface color
        surface1 = colors.base03, -- lighter surface
        surface2 = colors.base04, -- even lighter surface

        -- Text colors
        text = colors.base05,     -- main text
        subtext1 = colors.base04, -- dimmer text
        subtext0 = colors.base03, -- even dimmer text

        -- Overlay colors
        overlay0 = colors.base03,
        overlay1 = colors.base04,
        overlay2 = colors.base06,

        -- Accent colors
        red = colors.base08,    -- red accent
        peach = colors.base09,  -- orange/peach accent
        yellow = colors.base0A, -- yellow accent
        green = colors.base0B,  -- green accent
        teal = colors.base0C,   -- teal/cyan accent
        blue = colors.base0D,   -- blue accent
        mauve = colors.base0E,  -- purple/mauve accent
      }

      -- Apply all the custom highlight groups
      local highlights = {
        -- Completion menu styling
        Pmenu = { bg = ayu_colors.mantle, fg = ayu_colors.text },
        PmenuSel = { bg = ayu_colors.surface0, fg = ayu_colors.text },
        PmenuSbar = { bg = ayu_colors.surface0 },
        PmenuThumb = { bg = ayu_colors.surface2 },
        PmenuExtra = { bg = ayu_colors.mantle, fg = ayu_colors.subtext1 },

        -- Floating windows
        NormalFloat = { bg = ayu_colors.mantle },
        FloatBorder = { bg = ayu_colors.mantle, fg = ayu_colors.surface2 },
        FloatTitle = { bg = ayu_colors.mantle, fg = ayu_colors.text },

        -- Blink.cmp specific highlighting
        BlinkCmpMenu = { bg = ayu_colors.mantle, fg = ayu_colors.text },
        BlinkCmpMenuBorder = { bg = ayu_colors.mantle, fg = ayu_colors.surface2 },
        BlinkCmpMenuSelection = { bg = ayu_colors.surface0, fg = ayu_colors.text },
        BlinkCmpScrollBarThumb = { bg = ayu_colors.surface2 },
        BlinkCmpScrollBarGutter = { bg = ayu_colors.surface0 },
        BlinkCmpLabel = { bg = ayu_colors.mantle, fg = ayu_colors.text },
        BlinkCmpLabelDeprecated = { bg = ayu_colors.mantle, fg = ayu_colors.overlay0, strikethrough = true },
        BlinkCmpLabelDetail = { bg = ayu_colors.mantle, fg = ayu_colors.subtext1 },
        BlinkCmpLabelDescription = { bg = ayu_colors.mantle, fg = ayu_colors.subtext1 },
        BlinkCmpKind = { bg = ayu_colors.mantle, fg = ayu_colors.peach },
        BlinkCmpSource = { bg = ayu_colors.mantle, fg = ayu_colors.overlay1 },
        BlinkCmpGhostText = { fg = ayu_colors.overlay0, italic = true },
        BlinkCmpDoc = { bg = ayu_colors.mantle, fg = ayu_colors.text },
        BlinkCmpDocBorder = { bg = ayu_colors.mantle, fg = ayu_colors.surface2 },
        BlinkCmpDocSeparator = { bg = ayu_colors.mantle, fg = ayu_colors.surface1 },
        BlinkCmpDocCursorLine = { bg = ayu_colors.surface0 },
        BlinkCmpSignatureHelp = { bg = ayu_colors.mantle, fg = ayu_colors.text },
        BlinkCmpSignatureHelpBorder = { bg = ayu_colors.mantle, fg = ayu_colors.surface2 },
        BlinkCmpSignatureHelpActiveParameter = { bg = ayu_colors.surface0, fg = ayu_colors.peach, bold = true },

        -- Snacks.nvim picker NvChad style
        SnacksPicker = { bg = ayu_colors.base },
        SnacksPickerBorder = { fg = ayu_colors.surface0, bg = ayu_colors.base },
        SnacksPickerPreview = { bg = ayu_colors.base },
        SnacksPickerPreviewBorder = { fg = ayu_colors.base, bg = ayu_colors.base },
        SnacksPickerPreviewTitle = { fg = ayu_colors.base, bg = ayu_colors.green },
        SnacksPickerBoxBorder = { fg = ayu_colors.base, bg = ayu_colors.base },
        SnacksPickerInputBorder = { fg = ayu_colors.surface2, bg = ayu_colors.base },
        SnacksPickerInputSearch = { fg = ayu_colors.text, bg = ayu_colors.base },
        SnacksPickerList = { bg = ayu_colors.base },
        SnacksPickerListBorder = { fg = ayu_colors.base, bg = ayu_colors.base },
        SnacksPickerListTitle = { fg = ayu_colors.base, bg = ayu_colors.base },

        -- Additional picker elements
        SnacksPickerDir = { fg = ayu_colors.blue },
        SnacksPickerFile = { fg = ayu_colors.text },
        SnacksPickerMatch = { fg = ayu_colors.peach, bold = true },
        SnacksPickerCursor = { bg = ayu_colors.surface0, fg = ayu_colors.text },
        SnacksPickerSelected = { bg = ayu_colors.surface0, fg = ayu_colors.text },
        SnacksPickerIcon = { fg = ayu_colors.blue },
        SnacksPickerSource = { fg = ayu_colors.overlay1 },
        SnacksPickerCount = { fg = ayu_colors.overlay1 },
        SnacksPickerFooter = { fg = ayu_colors.overlay1 },
        SnacksPickerHeader = { fg = ayu_colors.text, bold = true },
        SnacksPickerSpecial = { fg = ayu_colors.peach },
        SnacksPickerIndent = { fg = ayu_colors.surface1 },
        SnacksPickerMulti = { fg = ayu_colors.peach },
        SnacksPickerTitle = { fg = ayu_colors.text, bold = true },
        SnacksPickerPrompt = { fg = ayu_colors.text },

        -- Snacks core components
        SnacksNotifierNormal = { bg = ayu_colors.mantle, fg = ayu_colors.text },
        SnacksNotifierBorder = { bg = ayu_colors.mantle, fg = ayu_colors.surface2 },
        SnacksNotifierTitle = { bg = ayu_colors.mantle, fg = ayu_colors.text, bold = true },
        SnacksNotifierIcon = { bg = ayu_colors.mantle, fg = ayu_colors.blue },
        SnacksNotifierIconInfo = { bg = ayu_colors.mantle, fg = ayu_colors.blue },
        SnacksNotifierIconWarn = { bg = ayu_colors.mantle, fg = ayu_colors.yellow },
        SnacksNotifierIconError = { bg = ayu_colors.mantle, fg = ayu_colors.red },

        -- Snacks Dashboard
        SnacksDashboardNormal = { bg = ayu_colors.base, fg = ayu_colors.text },
        SnacksDashboardDesc = { bg = ayu_colors.base, fg = ayu_colors.subtext1 },
        SnacksDashboardFile = { bg = ayu_colors.base, fg = ayu_colors.text },
        SnacksDashboardDir = { bg = ayu_colors.base, fg = ayu_colors.blue },
        SnacksDashboardFooter = { bg = ayu_colors.base, fg = ayu_colors.overlay1 },
        SnacksDashboardHeader = { bg = ayu_colors.base, fg = ayu_colors.text, bold = true },
        SnacksDashboardIcon = { bg = ayu_colors.base, fg = ayu_colors.blue },
        SnacksDashboardKey = { bg = ayu_colors.base, fg = ayu_colors.peach },
        SnacksDashboardTerminal = { bg = ayu_colors.base, fg = ayu_colors.text },
        SnacksDashboardSpecial = { bg = ayu_colors.base, fg = ayu_colors.peach },

        -- Snacks Terminal
        SnacksTerminalNormal = { bg = ayu_colors.mantle, fg = ayu_colors.text },
        SnacksTerminalBorder = { bg = ayu_colors.mantle, fg = ayu_colors.surface2 },
        SnacksTerminalTitle = { bg = ayu_colors.mantle, fg = ayu_colors.text, bold = true },

        -- Other UI elements
        CmpItemMenu = { fg = ayu_colors.surface2 },
        CursorLineNr = { fg = ayu_colors.text },
        GitSignsChange = { fg = ayu_colors.peach },
        LineNr = { fg = ayu_colors.overlay0 },
        LspInfoBorder = { link = "FloatBorder" },
        VertSplit = { bg = ayu_colors.base, fg = ayu_colors.surface0 },
        WhichKeyFloat = { bg = ayu_colors.mantle },
        YankHighlight = { bg = ayu_colors.surface2 },
        FidgetTask = { fg = ayu_colors.subtext1 },
        FidgetTitle = { fg = ayu_colors.peach },

        -- Indent guides
        IblIndent = { fg = ayu_colors.surface0 },
        IblScope = { fg = ayu_colors.overlay0 },

        -- Syntax highlighting
        Boolean = { fg = ayu_colors.mauve },
        Number = { fg = ayu_colors.mauve },
        Float = { fg = ayu_colors.mauve },

        PreProc = { fg = ayu_colors.mauve },
        PreCondit = { fg = ayu_colors.mauve },
        Include = { fg = ayu_colors.mauve },
        Define = { fg = ayu_colors.mauve },
        Conditional = { fg = ayu_colors.red },
        Repeat = { fg = ayu_colors.red },
        Keyword = { fg = ayu_colors.red },
        Typedef = { fg = ayu_colors.red },
        Exception = { fg = ayu_colors.red },
        Statement = { fg = ayu_colors.red },

        Error = { fg = ayu_colors.red },
        StorageClass = { fg = ayu_colors.peach },
        Tag = { fg = ayu_colors.peach },
        Label = { fg = ayu_colors.peach },
        Structure = { fg = ayu_colors.peach },
        Operator = { fg = ayu_colors.peach },
        Title = { fg = ayu_colors.peach },
        Special = { fg = ayu_colors.yellow },
        SpecialChar = { fg = ayu_colors.yellow },
        Type = { fg = ayu_colors.yellow, bold = true },
        Function = { fg = ayu_colors.green, bold = true },
        Delimiter = { fg = ayu_colors.subtext1 },
        Ignore = { fg = ayu_colors.subtext1 },
        Macro = { fg = ayu_colors.teal },

        -- Treesitter highlights
        TSAnnotation = { fg = ayu_colors.mauve },
        TSAttribute = { fg = ayu_colors.mauve },
        TSBoolean = { fg = ayu_colors.mauve },
        TSCharacter = { fg = ayu_colors.teal },
        TSCharacterSpecial = { link = "SpecialChar" },
        TSComment = { link = "Comment" },
        TSConditional = { fg = ayu_colors.red },
        TSConstBuiltin = { fg = ayu_colors.mauve },
        TSConstMacro = { fg = ayu_colors.mauve },
        TSConstant = { fg = ayu_colors.text },
        TSConstructor = { fg = ayu_colors.green },
        TSDebug = { link = "Debug" },
        TSDefine = { link = "Define" },
        TSEnvironment = { link = "Macro" },
        TSEnvironmentName = { link = "Type" },
        TSError = { link = "Error" },
        TSException = { fg = ayu_colors.red },
        TSField = { fg = ayu_colors.blue },
        TSFloat = { fg = ayu_colors.mauve },
        TSFuncBuiltin = { fg = ayu_colors.green },
        TSFuncMacro = { fg = ayu_colors.green },
        TSFunction = { fg = ayu_colors.green },
        TSFunctionCall = { fg = ayu_colors.green },
        TSInclude = { fg = ayu_colors.red },
        TSKeyword = { fg = ayu_colors.red },
        TSKeywordFunction = { fg = ayu_colors.red },
        TSKeywordOperator = { fg = ayu_colors.peach },
        TSKeywordReturn = { fg = ayu_colors.red },
        TSLabel = { fg = ayu_colors.peach },
        TSLiteral = { link = "String" },
        TSMath = { fg = ayu_colors.blue },
        TSMethod = { fg = ayu_colors.green },
        TSMethodCall = { fg = ayu_colors.green },
        TSNamespace = { fg = ayu_colors.yellow },
        TSNone = { fg = ayu_colors.text },
        TSNumber = { fg = ayu_colors.mauve },
        TSOperator = { fg = ayu_colors.peach },
        TSParameter = { fg = ayu_colors.text },
        TSParameterReference = { fg = ayu_colors.text },
        TSPreProc = { link = "PreProc" },
        TSProperty = { fg = ayu_colors.blue },
        TSPunctBracket = { fg = ayu_colors.text },
        TSPunctDelimiter = { link = "Delimiter" },
        TSPunctSpecial = { fg = ayu_colors.blue },
        TSRepeat = { fg = ayu_colors.red },
        TSStorageClass = { fg = ayu_colors.peach },
        TSStorageClassLifetime = { fg = ayu_colors.peach },
        TSStrike = { fg = ayu_colors.subtext1 },
        TSString = { fg = ayu_colors.teal },
        TSStringEscape = { fg = ayu_colors.green },
        TSStringRegex = { fg = ayu_colors.green },
        TSStringSpecial = { link = "SpecialChar" },
        TSSymbol = { fg = ayu_colors.text },
        TSTag = { fg = ayu_colors.peach },
        TSTagAttribute = { fg = ayu_colors.green },
        TSTagDelimiter = { fg = ayu_colors.green },
        TSText = { fg = ayu_colors.green },
        TSTextReference = { link = "Constant" },
        TSTitle = { link = "Title" },
        TSTodo = { link = "Todo" },
        TSType = { fg = ayu_colors.yellow, bold = true },
        TSTypeBuiltin = { fg = ayu_colors.yellow, bold = true },
        TSTypeDefinition = { fg = ayu_colors.yellow, bold = true },
        TSTypeQualifier = { fg = ayu_colors.peach, bold = true },
        TSURI = { fg = ayu_colors.blue },
        TSVariable = { fg = ayu_colors.text },
        TSVariableBuiltin = { fg = ayu_colors.mauve },
      }

      -- Apply all highlights
      for group, opts in pairs(highlights) do
        vim.api.nvim_set_hl(0, group, opts)
      end
    end
  },
--DISABLED(catppuccin unused; active cs=monoglow-z)   {
--DISABLED(catppuccin unused; active cs=monoglow-z)     "catppuccin/nvim",
--DISABLED(catppuccin unused; active cs=monoglow-z)     priority = 150,
--DISABLED(catppuccin unused; active cs=monoglow-z)     name = "catppuccin",
--DISABLED(catppuccin unused; active cs=monoglow-z)     config = function()
--DISABLED(catppuccin unused; active cs=monoglow-z)       require("catppuccin").setup({
--DISABLED(catppuccin unused; active cs=monoglow-z)         background = {
--DISABLED(catppuccin unused; active cs=monoglow-z)           light = "latte",
--DISABLED(catppuccin unused; active cs=monoglow-z)           dark = "mocha",
--DISABLED(catppuccin unused; active cs=monoglow-z)         },
--DISABLED(catppuccin unused; active cs=monoglow-z)         color_overrides = {
--DISABLED(catppuccin unused; active cs=monoglow-z)           latte = {
--DISABLED(catppuccin unused; active cs=monoglow-z)             rosewater = "#c14a4a",
--DISABLED(catppuccin unused; active cs=monoglow-z)             flamingo = "#c14a4a",
--DISABLED(catppuccin unused; active cs=monoglow-z)             red = "#c14a4a",
--DISABLED(catppuccin unused; active cs=monoglow-z)             maroon = "#c14a4a",
--DISABLED(catppuccin unused; active cs=monoglow-z)             pink = "#945e80",
--DISABLED(catppuccin unused; active cs=monoglow-z)             mauve = "#945e80",
--DISABLED(catppuccin unused; active cs=monoglow-z)             peach = "#c35e0a",
--DISABLED(catppuccin unused; active cs=monoglow-z)             yellow = "#b47109",
--DISABLED(catppuccin unused; active cs=monoglow-z)             green = "#6c782e",
--DISABLED(catppuccin unused; active cs=monoglow-z)             teal = "#4c7a5d",
--DISABLED(catppuccin unused; active cs=monoglow-z)             sky = "#4c7a5d",
--DISABLED(catppuccin unused; active cs=monoglow-z)             sapphire = "#4c7a5d",
--DISABLED(catppuccin unused; active cs=monoglow-z)             blue = "#45707a",
--DISABLED(catppuccin unused; active cs=monoglow-z)             lavender = "#45707a",
--DISABLED(catppuccin unused; active cs=monoglow-z)             text = "#654735",
--DISABLED(catppuccin unused; active cs=monoglow-z)             subtext1 = "#73503c",
--DISABLED(catppuccin unused; active cs=monoglow-z)             subtext0 = "#805942",
--DISABLED(catppuccin unused; active cs=monoglow-z)             overlay2 = "#8c6249",
--DISABLED(catppuccin unused; active cs=monoglow-z)             overlay1 = "#8c856d",
--DISABLED(catppuccin unused; active cs=monoglow-z)             overlay0 = "#a69d81",
--DISABLED(catppuccin unused; active cs=monoglow-z)             surface2 = "#bfb695",
--DISABLED(catppuccin unused; active cs=monoglow-z)             surface1 = "#d1c7a3",
--DISABLED(catppuccin unused; active cs=monoglow-z)             surface0 = "#e3dec3",
--DISABLED(catppuccin unused; active cs=monoglow-z)             base = "#f9f5d7",
--DISABLED(catppuccin unused; active cs=monoglow-z)             mantle = "#f0ebce",
--DISABLED(catppuccin unused; active cs=monoglow-z)             crust = "#e8e3c8",
--DISABLED(catppuccin unused; active cs=monoglow-z)           },
--DISABLED(catppuccin unused; active cs=monoglow-z)           mocha = {
--DISABLED(catppuccin unused; active cs=monoglow-z)             rosewater = "#ea6962",
--DISABLED(catppuccin unused; active cs=monoglow-z)             flamingo = "#ea6962",
--DISABLED(catppuccin unused; active cs=monoglow-z)             red = "#ea6962",
--DISABLED(catppuccin unused; active cs=monoglow-z)             maroon = "#ea6962",
--DISABLED(catppuccin unused; active cs=monoglow-z)             pink = "#d3869b",
--DISABLED(catppuccin unused; active cs=monoglow-z)             mauve = "#d3869b",
--DISABLED(catppuccin unused; active cs=monoglow-z)             peach = "#e78a4e",
--DISABLED(catppuccin unused; active cs=monoglow-z)             yellow = "#d8a657",
--DISABLED(catppuccin unused; active cs=monoglow-z)             green = "#a9b665",
--DISABLED(catppuccin unused; active cs=monoglow-z)             teal = "#89b482",
--DISABLED(catppuccin unused; active cs=monoglow-z)             sky = "#89b482",
--DISABLED(catppuccin unused; active cs=monoglow-z)             sapphire = "#89b482",
--DISABLED(catppuccin unused; active cs=monoglow-z)             blue = "#7daea3",
--DISABLED(catppuccin unused; active cs=monoglow-z)             lavender = "#7daea3",
--DISABLED(catppuccin unused; active cs=monoglow-z)             text = "#ebdbb2",
--DISABLED(catppuccin unused; active cs=monoglow-z)             subtext1 = "#d5c4a1",
--DISABLED(catppuccin unused; active cs=monoglow-z)             subtext0 = "#bdae93",
--DISABLED(catppuccin unused; active cs=monoglow-z)             overlay2 = "#a89984",
--DISABLED(catppuccin unused; active cs=monoglow-z)             overlay1 = "#928374",
--DISABLED(catppuccin unused; active cs=monoglow-z)             overlay0 = "#595959",
--DISABLED(catppuccin unused; active cs=monoglow-z)             surface2 = "#4d4d4d",
--DISABLED(catppuccin unused; active cs=monoglow-z)             surface1 = "#404040",
--DISABLED(catppuccin unused; active cs=monoglow-z)             surface0 = "#292929",
--DISABLED(catppuccin unused; active cs=monoglow-z)             base = "#1d2021",
--DISABLED(catppuccin unused; active cs=monoglow-z)             mantle = "#191b1c",
--DISABLED(catppuccin unused; active cs=monoglow-z)             crust = "#141617",
--DISABLED(catppuccin unused; active cs=monoglow-z)           },
--DISABLED(catppuccin unused; active cs=monoglow-z)         },
--DISABLED(catppuccin unused; active cs=monoglow-z)         transparent_background = false,
--DISABLED(catppuccin unused; active cs=monoglow-z)         show_end_of_buffer = false,
--DISABLED(catppuccin unused; active cs=monoglow-z)         integration_default = false,
--DISABLED(catppuccin unused; active cs=monoglow-z)         no_bold = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)         no_italic = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)         no_underline = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)         integrations = {
--DISABLED(catppuccin unused; active cs=monoglow-z)           blink_cmp = {
--DISABLED(catppuccin unused; active cs=monoglow-z)             style = 'bordered',
--DISABLED(catppuccin unused; active cs=monoglow-z)           },
--DISABLED(catppuccin unused; active cs=monoglow-z)           snacks = {
--DISABLED(catppuccin unused; active cs=monoglow-z)             enabled = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)             -- indent_scope_color = "lavender", -- catppuccin color (eg. `lavender`) Default: text
--DISABLED(catppuccin unused; active cs=monoglow-z)           },
--DISABLED(catppuccin unused; active cs=monoglow-z)           -- barbecue = { dim_dirname = true, bold_basename = true, dim_context = false, alt_background = false },
--DISABLED(catppuccin unused; active cs=monoglow-z)           -- cmp = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)           gitsigns = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)           -- hop = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)           -- illuminate = { enabled = true },
--DISABLED(catppuccin unused; active cs=monoglow-z)           native_lsp = { enabled = true, inlay_hints = { background = true } },
--DISABLED(catppuccin unused; active cs=monoglow-z)           -- neogit = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)           -- neotree = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)           semantic_tokens = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)           treesitter = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)           treesitter_context = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)           -- vimwiki = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)           which_key = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)           -- aerial = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)           fidget = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)           mason = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)           neotest = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)           dap_ui = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)           -- telescope = {
--DISABLED(catppuccin unused; active cs=monoglow-z)             --   enabled = true,
--DISABLED(catppuccin unused; active cs=monoglow-z)             --   style = "nvchad",
--DISABLED(catppuccin unused; active cs=monoglow-z)             -- },
--DISABLED(catppuccin unused; active cs=monoglow-z)           },
--DISABLED(catppuccin unused; active cs=monoglow-z)           highlight_overrides = {
--DISABLED(catppuccin unused; active cs=monoglow-z)             all = function(colors)
--DISABLED(catppuccin unused; active cs=monoglow-z)               return {
--DISABLED(catppuccin unused; active cs=monoglow-z)                 -- Completion menu styling
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Pmenu = { bg = colors.mantle, fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 PmenuSel = { bg = colors.surface0, fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 PmenuSbar = { bg = colors.surface0 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 PmenuThumb = { bg = colors.surface2 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 PmenuExtra = { bg = colors.mantle, fg = colors.subtext1 },
--DISABLED(catppuccin unused; active cs=monoglow-z) 
--DISABLED(catppuccin unused; active cs=monoglow-z)                 -- Floating windows
--DISABLED(catppuccin unused; active cs=monoglow-z)                 NormalFloat = { bg = colors.mantle },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 FloatBorder = { bg = colors.mantle, fg = colors.surface2 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 FloatTitle = { bg = colors.mantle, fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z) 
--DISABLED(catppuccin unused; active cs=monoglow-z)                 -- Blink.cmp specific highlighting
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpMenu = { bg = colors.mantle, fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpMenuBorder = { bg = colors.mantle, fg = colors.surface2 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpMenuSelection = { bg = colors.surface0, fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpScrollBarThumb = { bg = colors.surface2 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpScrollBarGutter = { bg = colors.surface0 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpLabel = { bg = colors.mantle, fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpLabelDeprecated = { bg = colors.mantle, fg = colors.overlay0, strikethrough = true },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpLabelDetail = { bg = colors.mantle, fg = colors.subtext1 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpLabelDescription = { bg = colors.mantle, fg = colors.subtext1 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpKind = { bg = colors.mantle, fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpSource = { bg = colors.mantle, fg = colors.overlay1 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpGhostText = { fg = colors.overlay0, italic = true },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpDoc = { bg = colors.mantle, fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpDocBorder = { bg = colors.mantle, fg = colors.surface2 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpDocSeparator = { bg = colors.mantle, fg = colors.surface1 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpDocCursorLine = { bg = colors.surface0 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpSignatureHelp = { bg = colors.mantle, fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpSignatureHelpBorder = { bg = colors.mantle, fg = colors.surface2 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 BlinkCmpSignatureHelpActiveParameter = { bg = colors.surface0, fg = colors.peach, bold = true },
--DISABLED(catppuccin unused; active cs=monoglow-z) 
--DISABLED(catppuccin unused; active cs=monoglow-z)                 -- Snacks.nvim picker NvChad style
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPicker = { bg = colors.base },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerBorder = { fg = colors.surface0, bg = colors.base },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerPreview = { bg = colors.base },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerPreviewBorder = { fg = colors.base, bg = colors.base },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerPreviewTitle = { fg = colors.base, bg = colors.green },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerBoxBorder = { fg = colors.base, bg = colors.base },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerInputBorder = { fg = colors.surface2, bg = colors.base },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerInputSearch = { fg = colors.text, bg = colors.base },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerList = { bg = colors.base },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerListBorder = { fg = colors.base, bg = colors.base },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerListTitle = { fg = colors.base, bg = colors.base },
--DISABLED(catppuccin unused; active cs=monoglow-z) 
--DISABLED(catppuccin unused; active cs=monoglow-z)                 -- Additional picker elements
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerDir = { fg = colors.blue },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerFile = { fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerMatch = { fg = colors.peach, bold = true },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerCursor = { bg = colors.surface0, fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerSelected = { bg = colors.surface0, fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerIcon = { fg = colors.blue },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerSource = { fg = colors.overlay1 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerCount = { fg = colors.overlay1 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerFooter = { fg = colors.overlay1 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerHeader = { fg = colors.text, bold = true },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerSpecial = { fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerIndent = { fg = colors.surface1 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerMulti = { fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerTitle = { fg = colors.text, bold = true },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksPickerPrompt = { fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z) 
--DISABLED(catppuccin unused; active cs=monoglow-z)                 -- Snacks core components
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksNotifierNormal = { bg = colors.mantle, fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksNotifierBorder = { bg = colors.mantle, fg = colors.surface2 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksNotifierTitle = { bg = colors.mantle, fg = colors.text, bold = true },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksNotifierIcon = { bg = colors.mantle, fg = colors.blue },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksNotifierIconInfo = { bg = colors.mantle, fg = colors.blue },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksNotifierIconWarn = { bg = colors.mantle, fg = colors.yellow },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksNotifierIconError = { bg = colors.mantle, fg = colors.red },
--DISABLED(catppuccin unused; active cs=monoglow-z) 
--DISABLED(catppuccin unused; active cs=monoglow-z)                 -- Snacks Dashboard
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksDashboardNormal = { bg = colors.base, fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksDashboardDesc = { bg = colors.base, fg = colors.subtext1 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksDashboardFile = { bg = colors.base, fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksDashboardDir = { bg = colors.base, fg = colors.blue },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksDashboardFooter = { bg = colors.base, fg = colors.overlay1 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksDashboardHeader = { bg = colors.base, fg = colors.text, bold = true },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksDashboardIcon = { bg = colors.base, fg = colors.blue },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksDashboardKey = { bg = colors.base, fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksDashboardTerminal = { bg = colors.base, fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksDashboardSpecial = { bg = colors.base, fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z) 
--DISABLED(catppuccin unused; active cs=monoglow-z)                 -- Snacks Terminal
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksTerminalNormal = { bg = colors.mantle, fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksTerminalBorder = { bg = colors.mantle, fg = colors.surface2 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SnacksTerminalTitle = { bg = colors.mantle, fg = colors.text, bold = true },
--DISABLED(catppuccin unused; active cs=monoglow-z) 
--DISABLED(catppuccin unused; active cs=monoglow-z)                 CmpItemMenu = { fg = colors.surface2 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 CursorLineNr = { fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 GitSignsChange = { fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 LineNr = { fg = colors.overlay0 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 LspInfoBorder = { link = "FloatBorder" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 VertSplit = { bg = colors.base, fg = colors.surface0 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 WhichKeyFloat = { bg = colors.mantle },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 YankHighlight = { bg = colors.surface2 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 FidgetTask = { fg = colors.subtext1 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 FidgetTitle = { fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z) 
--DISABLED(catppuccin unused; active cs=monoglow-z)                 IblIndent = { fg = colors.surface0 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 IblScope = { fg = colors.overlay0 },
--DISABLED(catppuccin unused; active cs=monoglow-z) 
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Boolean = { fg = colors.mauve },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Number = { fg = colors.mauve },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Float = { fg = colors.mauve },
--DISABLED(catppuccin unused; active cs=monoglow-z) 
--DISABLED(catppuccin unused; active cs=monoglow-z)                 PreProc = { fg = colors.mauve },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 PreCondit = { fg = colors.mauve },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Include = { fg = colors.mauve },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Define = { fg = colors.mauve },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Conditional = { fg = colors.red },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Repeat = { fg = colors.red },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Keyword = { fg = colors.red },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Typedef = { fg = colors.red },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Exception = { fg = colors.red },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Statement = { fg = colors.red },
--DISABLED(catppuccin unused; active cs=monoglow-z) 
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Error = { fg = colors.red },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 StorageClass = { fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Tag = { fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Label = { fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Structure = { fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Operator = { fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Title = { fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Special = { fg = colors.yellow },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 SpecialChar = { fg = colors.yellow },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Type = { fg = colors.yellow, style = { "bold" } },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Function = { fg = colors.green, style = { "bold" } },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Delimiter = { fg = colors.subtext1 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Ignore = { fg = colors.subtext1 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 Macro = { fg = colors.teal },
--DISABLED(catppuccin unused; active cs=monoglow-z) 
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSAnnotation = { fg = colors.mauve },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSAttribute = { fg = colors.mauve },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSBoolean = { fg = colors.mauve },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSCharacter = { fg = colors.teal },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSCharacterSpecial = { link = "SpecialChar" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSComment = { link = "Comment" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSConditional = { fg = colors.red },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSConstBuiltin = { fg = colors.mauve },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSConstMacro = { fg = colors.mauve },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSConstant = { fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSConstructor = { fg = colors.green },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSDebug = { link = "Debug" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSDefine = { link = "Define" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSEnvironment = { link = "Macro" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSEnvironmentName = { link = "Type" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSError = { link = "Error" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSException = { fg = colors.red },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSField = { fg = colors.blue },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSFloat = { fg = colors.mauve },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSFuncBuiltin = { fg = colors.green },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSFuncMacro = { fg = colors.green },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSFunction = { fg = colors.green },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSFunctionCall = { fg = colors.green },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSInclude = { fg = colors.red },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSKeyword = { fg = colors.red },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSKeywordFunction = { fg = colors.red },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSKeywordOperator = { fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSKeywordReturn = { fg = colors.red },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSLabel = { fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSLiteral = { link = "String" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSMath = { fg = colors.blue },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSMethod = { fg = colors.green },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSMethodCall = { fg = colors.green },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSNamespace = { fg = colors.yellow },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSNone = { fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSNumber = { fg = colors.mauve },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSOperator = { fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSParameter = { fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSParameterReference = { fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSPreProc = { link = "PreProc" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSProperty = { fg = colors.blue },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSPunctBracket = { fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSPunctDelimiter = { link = "Delimiter" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSPunctSpecial = { fg = colors.blue },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSRepeat = { fg = colors.red },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSStorageClass = { fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSStorageClassLifetime = { fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSStrike = { fg = colors.subtext1 },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSString = { fg = colors.teal },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSStringEscape = { fg = colors.green },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSStringRegex = { fg = colors.green },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSStringSpecial = { link = "SpecialChar" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSSymbol = { fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSTag = { fg = colors.peach },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSTagAttribute = { fg = colors.green },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSTagDelimiter = { fg = colors.green },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSText = { fg = colors.green },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSTextReference = { link = "Constant" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSTitle = { link = "Title" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSTodo = { link = "Todo" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSType = { fg = colors.yellow, style = { "bold" } },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSTypeBuiltin = { fg = colors.yellow, style = { "bold" } },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSTypeDefinition = { fg = colors.yellow, style = { "bold" } },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSTypeQualifier = { fg = colors.peach, style = { "bold" } },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSURI = { fg = colors.blue },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSVariable = { fg = colors.text },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 TSVariableBuiltin = { fg = colors.mauve },
--DISABLED(catppuccin unused; active cs=monoglow-z) 
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@annotation"] = { link = "TSAnnotation" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@attribute"] = { link = "TSAttribute" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@boolean"] = { link = "TSBoolean" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@character"] = { link = "TSCharacter" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@character.special"] = { link = "TSCharacterSpecial" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@comment"] = { link = "TSComment" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@conceal"] = { link = "Grey" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@conditional"] = { link = "TSConditional" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@constant"] = { link = "TSConstant" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@constant.builtin"] = { link = "TSConstBuiltin" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@constant.macro"] = { link = "TSConstMacro" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@constructor"] = { link = "TSConstructor" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@debug"] = { link = "TSDebug" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@define"] = { link = "TSDefine" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@error"] = { link = "TSError" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@exception"] = { link = "TSException" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@field"] = { link = "TSField" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@float"] = { link = "TSFloat" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@function"] = { link = "TSFunction" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@function.builtin"] = { link = "TSFuncBuiltin" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@function.call"] = { link = "TSFunctionCall" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@function.macro"] = { link = "TSFuncMacro" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@include"] = { link = "TSInclude" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@keyword"] = { link = "TSKeyword" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@keyword.function"] = { link = "TSKeywordFunction" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@keyword.operator"] = { link = "TSKeywordOperator" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@keyword.return"] = { link = "TSKeywordReturn" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@label"] = { link = "TSLabel" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@math"] = { link = "TSMath" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@method"] = { link = "TSMethod" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@method.call"] = { link = "TSMethodCall" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@namespace"] = { link = "TSNamespace" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@none"] = { link = "TSNone" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@number"] = { link = "TSNumber" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@operator"] = { link = "TSOperator" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@parameter"] = { link = "TSParameter" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@parameter.reference"] = { link = "TSParameterReference" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@preproc"] = { link = "TSPreProc" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@property"] = { link = "TSProperty" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@punctuation.bracket"] = { link = "TSPunctBracket" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@punctuation.delimiter"] = { link = "TSPunctDelimiter" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@punctuation.special"] = { link = "TSPunctSpecial" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@repeat"] = { link = "TSRepeat" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@storageclass"] = { link = "TSStorageClass" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@storageclass.lifetime"] = { link = "TSStorageClassLifetime" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@strike"] = { link = "TSStrike" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@string"] = { link = "TSString" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@string.escape"] = { link = "TSStringEscape" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@string.regex"] = { link = "TSStringRegex" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@string.special"] = { link = "TSStringSpecial" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@symbol"] = { link = "TSSymbol" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@tag"] = { link = "TSTag" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@tag.attribute"] = { link = "TSTagAttribute" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@tag.delimiter"] = { link = "TSTagDelimiter" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text"] = { link = "TSText" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.danger"] = { link = "TSDanger" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.diff.add"] = { link = "diffAdded" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.diff.delete"] = { link = "diffRemoved" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.emphasis"] = { link = "TSEmphasis" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.environment"] = { link = "TSEnvironment" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.environment.name"] = { link = "TSEnvironmentName" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.literal"] = { link = "TSLiteral" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.math"] = { link = "TSMath" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.note"] = { link = "TSNote" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.reference"] = { link = "TSTextReference" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.strike"] = { link = "TSStrike" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.strong"] = { link = "TSStrong" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.title"] = { link = "TSTitle" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.todo"] = { link = "TSTodo" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.todo.checked"] = { link = "Green" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.todo.unchecked"] = { link = "Ignore" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.underline"] = { link = "TSUnderline" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.uri"] = { link = "TSURI" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@text.warning"] = { link = "TSWarning" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@todo"] = { link = "TSTodo" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@type"] = { link = "TSType" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@type.builtin"] = { link = "TSTypeBuiltin" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@type.definition"] = { link = "TSTypeDefinition" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@type.qualifier"] = { link = "TSTypeQualifier" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@uri"] = { link = "TSURI" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@variable"] = { link = "TSVariable" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@variable.builtin"] = { link = "TSVariableBuiltin" },
--DISABLED(catppuccin unused; active cs=monoglow-z) 
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.class"] = { link = "TSType" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.comment"] = { link = "TSComment" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.decorator"] = { link = "TSFunction" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.enum"] = { link = "TSType" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.enumMember"] = { link = "TSProperty" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.events"] = { link = "TSLabel" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.function"] = { link = "TSFunction" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.interface"] = { link = "TSType" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.keyword"] = { link = "TSKeyword" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.macro"] = { link = "TSConstMacro" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.method"] = { link = "TSMethod" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.modifier"] = { link = "TSTypeQualifier" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.namespace"] = { link = "TSNamespace" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.number"] = { link = "TSNumber" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.operator"] = { link = "TSOperator" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.parameter"] = { link = "TSParameter" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.property"] = { link = "TSProperty" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.regexp"] = { link = "TSStringRegex" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.string"] = { link = "TSString" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.struct"] = { link = "TSType" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.type"] = { link = "TSType" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.typeParameter"] = { link = "TSTypeDefinition" },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 ["@lsp.type.variable"] = { link = "TSVariable" },
--DISABLED(catppuccin unused; active cs=monoglow-z)               }
--DISABLED(catppuccin unused; active cs=monoglow-z)             end,
--DISABLED(catppuccin unused; active cs=monoglow-z)             latte = function(colors)
--DISABLED(catppuccin unused; active cs=monoglow-z)               return {
--DISABLED(catppuccin unused; active cs=monoglow-z)                 IblIndent = { fg = colors.mantle },
--DISABLED(catppuccin unused; active cs=monoglow-z)                 IblScope = { fg = colors.surface1 },
--DISABLED(catppuccin unused; active cs=monoglow-z) 
--DISABLED(catppuccin unused; active cs=monoglow-z)                 LineNr = { fg = colors.surface1 },
--DISABLED(catppuccin unused; active cs=monoglow-z)               }
--DISABLED(catppuccin unused; active cs=monoglow-z)             end,
--DISABLED(catppuccin unused; active cs=monoglow-z)           },
--DISABLED(catppuccin unused; active cs=monoglow-z)         })
--DISABLED(catppuccin unused; active cs=monoglow-z)         -- vim.api.nvim_set_hl(0, "NavicIconsOperator", { default = true, bg = "none", fg = "#eedaad" })
--DISABLED(catppuccin unused; active cs=monoglow-z)         -- vim.api.nvim_set_hl(0, "NavicText", { default = true, bg = "none", fg = "#eedaad" })
--DISABLED(catppuccin unused; active cs=monoglow-z)         -- vim.api.nvim_set_hl(0, "NavicSeparator", { default = true, bg = "none", fg = "#eedaad" })
--DISABLED(catppuccin unused; active cs=monoglow-z) 
--DISABLED(catppuccin unused; active cs=monoglow-z)         -- vim.api.nvim_command("colorscheme catppuccin")
--DISABLED(catppuccin unused; active cs=monoglow-z)       end,
--DISABLED(catppuccin unused; active cs=monoglow-z)     },
  }
