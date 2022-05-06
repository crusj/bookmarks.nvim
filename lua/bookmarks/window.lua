local w = {
	bufb = nil,
	bufbw = nil,
	bw = 0, -- bookmarks window width
	bh = 0, -- bookmarks window height

	buff = nil,
	bufw = nil,

	previeww = nil,
	hl_cursorline_name = "hl_bookmarks_csl"
}

local config = nil

function w.setup()
	config = require("bookmarks.config").get_data()
	vim.cmd(string.format("highlight hl_bookmarks_csl %s", config.hl_cursorline))
end

function w.open_list_window()
	w.buff = vim.api.nvim_get_current_buf()
	w.bufw = vim.api.nvim_get_current_win()

	if w.bufb == nil then
		w.bufb = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_option(w.bufb, 'filetype', 'bookmarks')
		vim.api.nvim_buf_set_keymap(w.bufb, "n", config.keymap.jump, ":lua require'bookmarks'.jump()<cr>", { silent = true })
		vim.api.nvim_buf_set_keymap(w.bufb, "n", config.keymap.delete, ":lua require'bookmarks'.delete()<cr>", { silent = true })
		vim.api.nvim_buf_set_keymap(w.bufb, "n", config.keymap.order, ":lua require'bookmarks.list'.refresh(true)<cr>", { silent = true })
	end

	local ew = vim.api.nvim_get_option("columns")
	local eh = vim.api.nvim_get_option("lines")


	w.bw = math.floor(ew * 0.6)
	w.bh = math.floor(eh * 0.7)
	w.bufbw = vim.api.nvim_open_win(w.bufb, true, {
		relative = "editor",
		width = w.bw,
		height = w.bh,
		row = math.floor((eh - w.bh) / 2),
		col = math.floor((ew - w.bw) / 2),
		border = "double",
	})

	vim.api.nvim_win_set_option(w.bufbw, "number", true)
	vim.api.nvim_win_set_option(w.bufbw, "relativenumber", false)
	vim.api.nvim_win_set_option(w.bufbw, "scl", "no")
	vim.api.nvim_win_set_option(w.bufbw, "cursorline", true)
	vim.api.nvim_win_set_option(w.bufbw, "wrap", false)
	vim.api.nvim_win_set_option(w.bufbw, "winhighlight", "CursorLine:"..w.hl_cursorline_name)

	vim.api.nvim_win_set_buf(w.bufbw, w.bufb)
end

return w
