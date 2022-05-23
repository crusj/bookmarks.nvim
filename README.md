# bookmarks.nvim
Remember file locations and sort by time and frequency.
## Description

This plugin is used to mark any position of the file and jump to it. It can add notes when marking and persist the mark to the file when nvim exits for the next load. 

Each time you jump from a bookmark, the update time of the current bookmark will be updated and the usage frequency will be increased by one. You can sort bookmarks by time or frequency when browsing the bookmark list.

The data file is based on the **cwd** of each project for separate storage.

Support switching between multiple sessions.

The storage location is under```echo stdpath("data")```,mac is ```~/.local/share/nvim/bookmarks/```.

The storage data is lua code and load with ```dofile```:

```lua
require("bookmarks.list").load{
    filename = '/Users/crusj/Project/bookmarks.nvim/README.md',
    description = 'readme',
    fre = 3,
    id = '429b65925c650553dfcc8576231837a2',
    line = 2,
    updated_at = 1651588531,
}
require("bookmarks.list").load{
    filename = '/Users/crusj/Project/bookmarks.nvim/lua/bookmarks/config.lua',
    description = 'keymap',
    fre = 11,
    id = 'a22afa41979db45c6a8215cb7df6304f',
    line = 6,
    updated_at = 1651588572,
}
require("bookmarks.list").load{
    filename = '/Users/crusj/Project/bookmarks.nvim/lua/bookmarks/event.lua',
    description = 'add keymap',
    fre = 5,
    id = 'a2e79c4b86b533f43fe3aa5a545a5073',
    line = 10,
    updated_at = 1651580490,
}
```

## screenshots

### bookmarks list

<img src="https://github.com/crusj/bookmarks.nvim/blob/main/screenshots/shot1.png" width="750">
		

## Install

### Requirment

**Neovim >= 0.7**

**File icon**

```lua
use 'kyazdani42/nvim-web-devicons'
```
### Install

**packer**

```lua
use 'crusj/bookmarks.nvim'
```

```lua
require("bookmarks").setup()

```


## Usage

### Default config

```lua
require("bookmarks").setup({
	keymap = {
		toggle = "<tab><tab>", -- toggle bookmarks
		add = "\\z", -- add bookmarks
		jump = "<CR>", -- jump from bookmarks
		delete = "dd", -- delete bookmarks
		order = "<space><space>", -- order bookmarks by frequency or updated_time
	},
	hl_cursorline = "guibg=Gray guifg=White" -- hl bookmarsk window cursorline
})
```
