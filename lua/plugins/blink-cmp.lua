return {
  {
    "saghen/blink.cmp",
    dependencies = {
      "rafamadriz/friendly-snippets",
      -- Add the copilot source
      "giuxtaposition/blink-cmp-copilot",
    },
    version = "*",
    opts = {
      -- 'default' for mappings similar to built-in completion
      -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
      keymap = { preset = "super-tab" },

      completion = {
        ghost_text = {
          enabled = true,
          -- Optional: show ghost text even when the menu is closed
          show_without_menu = true,
        },
      },

      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
      },

      sources = {
        default = { "lsp", "path", "snippets", "buffer", "copilot" },
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-cmp-copilot",
            score_offset = 100, -- Show copilot at the top
            async = true,
          },
        },
      },
    },
  },

  -- Adjust your copilot.lua config to not interfere with blink
  {
    "zbirenbaum/copilot.lua",
    opts = {
      suggestion = { enabled = false }, -- Disable ghost text
      panel = {
        enabled = true, -- Must be true to use the :Copilot panel command
        auto_refresh = true, -- Updates the panel as you type in the main buffer
      },
    },
  },
}
