local b = {}
local c = require("config")
local e = require("event")

function b.setup(user_config)
	c.setup()
	e.setup()
end

function b.add_bookmarks()
	local filename = vim.api.nvim_buf_get_name(0)
	local line = vim.api.nvim_eval("line('.')")

	--Description
	vim.ui.input({
		prompt = "Description:",
		default = "",
	}, function(input)
		print(input)
	end)
end

function b.delete_bookmarks()

end

function b.list_bookmarks(order)

end

return b
