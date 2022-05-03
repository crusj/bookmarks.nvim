local e = {}
local config = nil

function e.setup()
	config = require("config").get_data()
	e.key_bind()
end

function e.key_bind()
	vim.keymap.set(config.keymap.add,":lua require'bookmarks'.add()<cr>")
end

return e
