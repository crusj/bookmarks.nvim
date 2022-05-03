local config = {
	data = nil
}

function config.setup()
	config.data = {
		keymap = {
			add = "\\z",
			toggle = "\\l",
			jump = "<CR>",
			delete = "\\dd",
			order = "<space><space>"
		}
	}
end

function config.get_data()
	return config.data
end

return config
