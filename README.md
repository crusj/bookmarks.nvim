# bookmarks.nvim
Remember file locations and sort by time and frequency.

## Description

This plugin is used to mark any position of the file and jump to it. It can add notes when marking and persist the mark to the file when nvim exits for the next load.

Each time you jump from a bookmark, the update time of the current bookmark will be updated and the usage frequency will be increased by one. You can sort bookmarks by time or frequency when browsing the bookmark list.

The data file is based on the **cwd** of each project for separate storage.

Support switching between multiple sessions.

Show virt text at the end of bookmarked lines.

The storage location is under```echo stdpath("data")```, mac is ```~/.local/share/nvim/bookmarks/```.

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
<img src="https://github.com/crusj/bookmarks.nvim/blob/main/screenshots/shot2.png" width="750">


## Install

### Requirment

* **Neovim >= 0.7**

**packer**

```lua
{
    'crusj/bookmarks.nvim',
    branch = 'main',
    requires = { 'kyazdani42/nvim-web-devicons' },
    config = function()
        require("bookmarks").setup()
       	require("telescope").load_extension("bookmarks")
    end
}
```
**lazy**

```lua
{
    'crusj/bookmarks.nvim',
    keys = {
        { "<tab><tab>", mode = { "n" } },
    },
    branch = 'main',
    dependencies = { 'nvim-web-devicons' },
    config = function()
        require("bookmarks").setup()
        require("telescope").load_extension("bookmarks")
    end
}


```

## Telescope

Command:
`Telescope bookmarks`


## Usage

### Default config

```lua
require("bookmarks").setup({
    storage_dir = "",  -- Default path: vim.fn.stdpath("data").."/bookmarks,  if not the default directory, should be absolute path",
    mappings_enabled = true, -- If the value is false, only valid for global keymaps: toggle、add、delete_on_virt、show_desc
    keymap = {
        toggle = "<tab><tab>", -- Toggle bookmarks(global keymap)
        close = "q", -- close bookmarks (buf keymap)
        add = "\\z", -- Add bookmarks(global keymap)
        add_global = "\\g" -- Add global bookmarks(global keymap), global bookmarks will appear in all projects. Identified with the symbol '󰯾'
        jump = "<CR>", -- Jump from bookmarks(buf keymap)
        delete = "dd", -- Delete bookmarks(buf keymap)
        order = "<space><space>", -- Order bookmarks by frequency or updated_time(buf keymap)
        delete_on_virt = "\\dd", -- Delete bookmark at virt text line(global keymap)
        show_desc = "\\sd", -- show bookmark desc(global keymap)
        focus_tags = "<c-j>",      -- focus tags window
        focus_bookmarks = "<c-k>", -- focus bookmarks window
        toogle_focus = "<S-Tab>", -- toggle window focus (tags-window <-> bookmarks-window)
    },
    width = 0.8, -- Bookmarks window width:  (0, 1]
    height = 0.7, -- Bookmarks window height: (0, 1]
    preview_ratio = 0.45, -- Bookmarks preview window ratio (0, 1]
    tags_ratio = 0.1, -- Bookmarks tags window ratio
    fix_enable = false, -- If true, when saving the current file, if the bookmark line number of the current file changes, try to fix it.

    virt_text = "", -- Show virt text at the end of bookmarked lines, if it is empty, use the description of bookmarks instead.
    sign_icon = "󰃃",                                           -- if it is not empty, show icon in signColumn.
    virt_pattern = { "*.go", "*.lua", "*.sh", "*.php", "*.rs" }, -- Show virt text only on matched pattern
    virt_ignore_pattern = {}, -- Ignore showing virt text on matched pattern, this works after virt_pattern
    border_style = "single", -- border style: "single", "double", "rounded" 
    hl = {
        border = "TelescopeBorder", -- border highlight
        cursorline = "guibg=Gray guifg=White", -- cursorline highlight
    },
    datetime_format = "%Y-%m-%d %H:%M:%S", -- os.date
    -- •	%Y: Four-digit year
    -- •	%m: Two-digit month (01 to 12)
    -- •	%d: Two-digit day (01 to 31)
    -- •	%H: Hour in 24-hour format (00 to 23)
    -- •	%I: Hour in 12-hour format (01 to 12)
    -- •	%M: Two-digit minute (00 to 59)
    -- •	%S: Two-digit second (00 to 59)
    -- •	%p: AM/PM indicator
})
```

### Steps
* Move the cursor to the line of the file that needs to be bookmarked.
* Press `\\z` in normal mode, and input a description in the pop-up shortcut window.
* Press enter in insert mode to add, or press esc in normal mode to cancel adding bookmarks.
* Press `<tab><tab>` to open or close the bookmark list window.
* Move the cursor in the bookmark list window, press `enter` to jump to the file line where the bookmark is located.
* Press `<space><space>` in the bookmark list window to switch sorting rules.
* Press `dd` in the bookmark list to delete a bookmark.

## Global keymaps

| Desc                              | Func                                     |
| --------------------------------- | ---------------------------------------- |
| Add local bookmarks               | require'bookmarks'.add_bookmarks(false)  |
| Add global bookmarks              | require'bookmarks'.add_bookmarks(true)   |
| Toggle bookmarks                  | require'bookmarks'.toggle_bookmarks()    |
| Delete bookmark at virt text line | require'bookmarks.list'.delete_on_virt() |
| Show bookmark desc                | require'bookmarks.list'.show_desc()      |


## Highlights

| Highlight               | Purpose                                |
| ----------------------- | -------------------------------------- |
| bookmarks_virt_text     | Highlight of the virt_text             |

## Tags
Tags is now supported to categorize bookmarks. You can add tags to your bookmarks by using semicolons when you add them.

<img src="https://github.com/crusj/bookmarks.nvim/blob/main/screenshots/shot3.png" width="750">

By default, ALL bookmarks are marked as ALL tags.

You can use the shortcut key `<S-Tab>` to switch the focus between the Tags and Bookmarks windows, or use the shortcut keys `<c-j>` and `<c-k>` to navigate through the Tags and Bookmarks windows.
> Of course, you can change these default shortcut keys through the configuration settings if you so choose.

## Issue

Bookmark are realized by storing the file name and line number where the bookmark is added.<br>
If the buf changes, the line number where the bookmark content is located may not match the real situation, the bookmark still points to the old one.
Some time ago, I recorded the hash value of the line text where the bookmark is located. When the buf is saved, it will traverse all the bookmarks of the current buf, relative to the change of the total number of lines in the buf, look up or down for the line content equal to the bookmark hash value, and update the bookmark position, which works somewhat, but often fails. The fix_enable option is set to false by defalut.<br>
I'm thinking of a better way to do it. 🤔<br>
Ideas welcome. 🥳

## Issue(imperfect)
* A `feature/fix` branch is now available to attempt to automatically correct bookmark positions when saving files if bookmark positions change, this is still experimental.
* ~~I am now trying to write some extensions using rust in the `feature/fix` branch, so you need to use `curl https://sh.rustup.rs -sSf | sh` to install `cargo`.~~
* ~~In addition, in macOS system, you need to add some additional configuration in `~/.cargo/config`~~
```toml
[target.x86_64-apple-darwin]
rustflags = [
  "-C", "link-arg=-undefined",
  "-C", "link-arg=dynamic_lookup",
]

[target.aarch64-apple-darwin]
rustflags = [
  "-C", "link-arg=-undefined",
  "-C", "link-arg=dynamic_lookup",
]
```
* ~~If you are not a lazy plugin manager(build.lua), you need to execute `require "bookmarks.install"`~~
* For convenience, I uploaded the compiled so file.
* Currently tested are darwin(intel and silicon) and linux(x86-64).


## 🤩🤩
[![Star History Chart](https://api.star-history.com/svg?repos=crusj/bookmarks.nvim&type=Date)](https://api.star-history.com/svg?repos=crusj/bookmarks.nvim&type=Date)

