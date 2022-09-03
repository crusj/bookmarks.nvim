local config = {
	data = nil
}

function config.setup(user_config)
	config.data = {
		keymap = {
			toggle = "<tab><tab>", -- toggle bookmarks
			add = "\\z", -- add bookmarks
			jump = "<CR>", -- jump from bookmarks
			delete = "dd", -- delete bookmarks
			order = "<space><space>", -- order bookmarks by frequency or updated_time
	 	},
		width = 0.8, -- bookmarks window width:  (0, 1]
		height = 0.7, -- bookmarks window height: (0, 1]
        preview_ratio = 0.45, -- bookmarks preview window ratio (0.1]
        preview_ext_enable = false, -- if true, preview buf will add file ext, preview window may be highlighed(treesitter), but may be slower
        fix_enable = false,
		hl_cursorline = "guibg=Gray guifg=White" -- hl bookmarsk window cursorline
	}

	if user_config == nil or type(user_config) ~= "table" then
		return
	end

	for dk, dv in pairs(config.data) do
		if type(dv) ~= "table" then
			if user_config[dk] ~= nil then
				config.data[dk] = user_config[dk]
			end
		else
			for fk, fv in pairs(dv) do
				if user_config[dk] ~= nil and user_config[dk][fk] ~= nil then
					config.data[dk][fk] = user_config[dk][fk]
				end
			end
		end
	end
end

function config.get_data()
	return config.data
end

return config
