# Todo
- Redesign Oil bash relocation script to allow for ability to <leader>cd into a terminal buffer at the site of the current directory location 
- Test out terminal cycling keys. It may be pragmatic to set up one-shot keys to cycle terminals 

# Notes
- Resetting Neovim
	- Neovim has a number of potential complications when attempting to reset the neovim state. The ~/.cache/nvim directory caches LuaJIT compilations of neovim plugins, and may need to be manually removed in order to force neovim to refresh and recompile its plugins
	- We noticed an issue with snack image renderer (when opening explorer/picker), when invoking treesitter parsers. The solution was to update the snacks plugin from the Lazy deashboard.

- Blame a particular line in a file (must be tracked in a git repo)
`:lua require("gitsigns").blame_line()`

- Since the migration to the main branch, nvim-treesitter has been reconfigured. Parsers were initially loaded based on the filetype, but now this has been disabled due to popups on the UI. In order to install parsers, visit the plugin file and alter the .update() method to .install() accordingly AFTER the language has been inserted into the language table

- Keymap peculiarities:
	- If a keymap such as <leader>t also is in the space of another keymap such as <leader>th, the user will need to press ENTER after the former in order to execute the keymap that anticipates a followup
	- The keymap to open oil from within a neovim text buffer and from a neovim terminal buffer are different. The latter requires "nvim .", and the <nvim> command can be substituted with the custom "nv" command to allow for oil buffer relocations

- MdMath

MdMath has to be rebuilt after installing the necessary dependnecies (imagemagick, librsvg, nodejs includes npm) via the :MdMath build. DO NOT place document code notation (```) prior to mdmath notation or it will not render

- Snacks
	- Shows keymaps installed in Snacks picker. Snacks.picker.keymaps() utilizes the stored reference that Neovim designates for a function associated with a keymap. The debug.getinfo() function is used under the hood to identify the location in the neovim config filesystem where that function is defined.

	`:lua Snacks.picker.keymaps()`
	- Shows commands installed in Snacks picker
  `:lua Snacks.picker.commands()`

- Text manipulation:
	- Designates the <C-j> and <C-h> lateral movements in visual mode (not in normal mode)
	- Not sure where this comes from, but in insert mode, <C-h/j> appears to delete words in the direction of the movement

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


- oil buffer write function:

```
-- required function for opening directories in terminal from oil
local function save_cwd_to_file()
	local cwd = require("oil").get_current_dir()
	local file = io.open(os.getenv("TMPDIR") .. "/.nvim_last_dir", "w")
	if file then
		file:write(cwd)
		file:close()
	end
	vim.cmd("qa")
end

-- Open directory in terminal from oil buffer
map('n', '<leader>cd', save_cwd_to_file, { desc = '[oil]: open directory' })
```

- Spelling
	- Disctionary is located @ ~/.local/share/nvim/site/spell/en.utf-8.add

- Folding
- Default folding behavior is defined in the nvim-treesitter plugin
