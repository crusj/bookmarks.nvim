local config = {}

function config.setup()
	config.data = {
		keymap = {
			add = "\\z",
			list = "\\l",
		}
	}
end

function config.get_data()
	return config.data
end

return config
