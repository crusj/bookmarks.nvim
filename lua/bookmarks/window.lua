local w = {
	bufb = nil,
	bufbw = nil,
	bw = 0, -- bookmarks window width
	bh = 0, -- bookmarks window height

	buff = nil,
	bufw = nil,

	previeww = nil,
}

local config = nil

function w.setup()
	config = require("bookmarks.config").get_data()
end

function w.open_list_window()
	w.buff = vim.api.nvim_get_current_buf()
	w.bufw = vim.api.nvim_get_current_win()

	if w.bufb == nil then
		w.bufb = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_keymap(w.bufb, "n", config.keymap.jump, ":lua require'bookmarks'.jump()<cr>", {})
		vim.api.nvim_buf_set_keymap(w.bufb, "n", config.keymap.delete, ":lua require'bookmarks'.delete()<cr>", {})
		vim.api.nvim_buf_set_keymap(w.bufb, "n", config.keymap.order, ":lua require'bookmarks.list'.refresh(true)<cr>", {})
	end

	local cw = vim.api.nvim_win_get_width(0)
	local ch = vim.api.nvim_win_get_height(0)

	w.bw = math.floor(cw * 0.75)
	w.bh = math.floor(ch * 0.75)
	w.bufbw = vim.api.nvim_open_win(w.bufb, true, {
		relative = "win",
		width = w.bw,
		height = w.bh,
		row = math.floor((ch - w.bh) / 2),
		col = math.floor((cw - w.bw) / 2),
		border = "double",
	})

	vim.api.nvim_win_set_option(w.bufbw, "number", true)
	vim.api.nvim_win_set_option(w.bufbw, "relativenumber", false)
	vim.api.nvim_win_set_option(w.bufbw, "scl", "no")
	vim.api.nvim_win_set_option(w.bufbw, "cursorline", true)

	vim.api.nvim_win_set_buf(w.bufbw, w.bufb)
end

return w
