local b = {}
local c = require("bookmarks.config")
local e = require("bookmarks.event")
local l = require("bookmarks.list")
local w = require("bookmarks.window")

function b.setup(user_config)
	c.setup(user_config)
	l.setup()
	e.setup()
	w.setup()
end

function b.add_bookmarks()
	local filename = vim.api.nvim_buf_get_name(0)
	local line = vim.api.nvim_eval("line('.')")

	local description = ""
	--Description
	vim.ui.input({
		prompt = "Description: ",
		default = "",
	}, function(input)
		if input ~= nil then
			description = input
		end
	end)

	l.add(filename,line,description)
end

function b.toggle_bookmarks()
	l.toggle()
end

function b.jump()
	l.jump()
end

function b.delete()
	local line = vim.api.nvim_eval("line('.')")
	l.delete(line)
end

return b
