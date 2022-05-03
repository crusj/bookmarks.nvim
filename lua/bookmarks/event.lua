local e = {}
local config = nil

function e.setup()
	config = require("bookmarks.config").get_data()
	e.key_bind()
end

function e.key_bind()
	vim.keymap.set("n",config.keymap.add, ":lua require'bookmarks'.add_bookmarks()<cr>",{})
	vim.keymap.set("n",config.keymap.toggle, ":lua require'bookmarks'.toggle_bookmarks()<cr>",{})
end

return e
