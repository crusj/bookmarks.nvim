local config = {
	data = nil
}

function config.setup()
	config.data = {
		keymap = {
			toggle = "<tab><tab>",
			add = "\\z",
			jump = "<CR>",
			delete = "\\dd",
			order = "<space><space>",
		}
	}
end

function config.get_data()
	return config.data
end

return config
