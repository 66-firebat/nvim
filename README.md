# Notes

- Blame a particular line in a file (must be tracked in a git repo)
`:lua require("gitsigns").blame_line()`

- Since the migration to the main branch, nvim-treesitter has been reconfigured. Parsers were initially loaded based on the filetype, but now this has been disabled due to popups on the UI. In order to install parsers, visit the plugin file and alter the .update() method to .install() accordingly AFTER the language has been inserted into the language table

- MdMath

MdMath has to be rebuilt after installing the necessary dependnecies (imagemagick, librsvg, nodejs includes npm) via the :MdMath build. DO NOT place document code notation (```) prior to mdmath notation or it will not render

- Snacks
	- Shows keymaps installed in Snacks picker. Snacks.picker.keymaps() utilizes the stored reference that Neovim designates for a function associated with a keymap. The debug.getinfo() function is used under the hood to identify the location in the neovim config filesystem where that function is defined.

	`:lua Snacks.picker.keymaps()`
	- Shows commands installed in Snacks picker
  `:lua Snacks.picker.commands()`

- nvim-treesitter
	- Nvim treesitters refactor to main requires a new lazy configuration.
	- https://github.com/nvim-lua/kickstart.nvim/pull/1748#issuecomment-3740311930
  - https://www.reddit.com/r/neovim/comments/1q2rnnl/i_just_installed_kickstart_and_getting_this_error/
	- Use :TSInstall <langauge> to manually install parsers for specific languages

- Add 'nowait' so it fires immediately even if other maps exist
`local <code>opts</code> = { noremap = true, silent = true, nowait = true }`

- Cut a line
`X (Capital x)`

- Wrap content with html tags (nvim-surround, prompt will appear to enter tag name)
`ysiw + t + "tag name"`

- Delete two words backwards (inclusive, the command without v is exclusive)
dv2b

- The flash.nvim plugin has been implemented to replace the f key with the flash jump plugin. Values are maintained in the extra.lua file

- In V-BLOCK mode, using o and O keys will move the cursor to the outer corners of the block, which is useful when attempting to expand the boundaries of the block

- The comma key is the partner to the semicolon key, and it can be used to move in the opposite direction of the search character. However, this configuration of neovim disables use of the comma and instead favors the flash movements

- <leader>sw will search for all instances of the word under the cursor</leader>, in VISUAL mode

- Setting a config function in lazy.nvim lua files will disable the opts table from registering it's values. Additionally, the setup require function should only be called once in order to avoid overwriting the M table with blank values
