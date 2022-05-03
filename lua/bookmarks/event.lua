local e = {}
local config = nil
local l = require("bookmarks.list")

function e.setup()
	config = require("bookmarks.config").get_data()
	e.key_bind()
	e.autocmd()
end

function e.key_bind()
	vim.keymap.set("n", config.keymap.add, ":lua require'bookmarks'.add_bookmarks()<cr>", { silent = true })
	vim.keymap.set("n", config.keymap.toggle, ":lua require'bookmarks'.toggle_bookmarks()<cr>", { silent = true })
end

function e.autocmd()
	vim.api.nvim_create_autocmd({ "VimLeave" }, {
		callback = l.persistent
	})
end

return e
