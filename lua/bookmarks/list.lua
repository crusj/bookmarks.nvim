local md5 = require("bookmarks.md5")
local w = require("bookmarks.window")

local l = {
	data = {},
	order_ids = {},
	order = "time",
	is_windows = false,
	path_sep = "/",
	data_dir = nil,
	data_filename = nil,

	loaded_data = false
}

function l.setup()
	local os_name = vim.loop.os_uname().sysname
	l.is_windows = os_name == "Windows" or os_name == "Windows_NT"
	if l.is_windows then
		l.path_sep = "\\"
	end
end

function l.add(filename, line, description)
	l.load_data()

	local id = md5.sumhexa(string.format("%s:%s", filename, line))
	local now = os.time()
	if l.data[id] ~= nil then --update description
		if description ~= nil then
			l.data[id].description = description
			l.data[id].updated_at = now
		end
	else -- new
		l.data[id] = {
			filename = filename,
			id = id,
			line = line,
			description = description or "",
			updated_at = now,
			fre = 1
		}
	end
end

function l.delete(line)
	if l.order_ids[line] ~= nil then
		l.data[l.order_ids[line]] = nil
		l.refresh()
	end
end

function l.refresh(order)
	if order == true then
		if l.order == "time" then
			l.order = "fre"
		else
			l.order = "time"
		end
	end

	l.flush()
end

function l.toggle(order)
	-- close
	if w.bufbw ~= nil and vim.api.nvim_win_is_valid(w.bufbw) then
		vim.api.nvim_win_hide(w.bufbw)
		w.bufbw = nil

		return
	end

	l.load_data()
	w.open_list_window()
	l.flush()

end

function l.flush()
	l.load_data()

	local tmp_data = {}
	for _, item in pairs(l.data) do
		tmp_data[#tmp_data + 1] = item
	end

	if l.order == "time" then
		table.sort(tmp_data, function(e1, e2)
			return e1.updated_at > e2.updated_at
		end)
	else
		table.sort(tmp_data, function(e1, e2)
			return e1.fre > e2.fre
		end)
	end

	local lines = {}
	-- local cwd = vim.api.nvim_eval("getcwd()")


	l.order_ids = {}
	for _, item in ipairs(tmp_data) do
		local rep = math.floor(w.bw * 0.3)
		local icon = (require 'nvim-web-devicons'.get_icon(item.filename)) or ""
		lines[#lines + 1] = string.format("%s %s:%s [%s]",
			l.padding(item.description, rep),
			icon.. item.filename,
			item.line, item.fre)
		l.order_ids[#l.order_ids + 1] = item.id
	end

	vim.api.nvim_buf_set_option(w.bufb, "modifiable", true)
	-- empty
	vim.api.nvim_buf_set_lines(w.bufb, 0, -1, false, {})

	-- flush
	vim.api.nvim_buf_set_lines(w.bufb, 0, #lines, false, lines)
	vim.api.nvim_buf_set_option(w.bufb, "modifiable", false)
end

function l.padding(str, len)
	if #str > len then
		return string.sub(str, 0, len)
	else
		return str .. string.rep(" ", len - #str)
	end
end

function l.jump()
	local line = vim.api.nvim_eval("line('.')")
	local item = l.data[l.order_ids[line]]

	l.data[l.order_ids[line]].fre = l.data[l.order_ids[line]].fre + 1
	l.data[l.order_ids[line]].updated_at = os.time()

	vim.api.nvim_set_current_win(w.bufw)
	vim.cmd("e " .. item.filename)
	vim.cmd("execute  \"normal! " .. item.line .. "G;zz\"")
	vim.cmd("execute  \"normal! zz\"")

	vim.api.nvim_win_hide(w.bufbw)
	w.bufbw = nil
end

function l.load(data)
	l.data[data.id] = data
end

function l.persistent()
	local tpl = [[
require("bookmarks.list").load{
	_
}]]

	local str = ""
	for id, data in pairs(l.data) do
		local sub = ""
		for k, v in pairs(data) do
			if sub ~= "" then
				sub = string.format("%s\n%s", sub, string.rep(" ", 4))
			end
			if type(v) == "number" then
				sub = sub .. string.format("%s = %s,", k, v)
			else
				sub = sub .. string.format("%s = '%s',", k, v)
			end
		end
		if str == "" then
			str = string.format("%s%s", str, string.gsub(tpl, "_", sub))
		else
			str = string.format("%s\n%s", str, string.gsub(tpl, "_", sub))
		end
	end

	local fd = assert(io.open(l.data_filename, "w"))
	fd:write(str)
	fd:close()
	print("Persistent bookmarks finished")
end

function l.load_data()
	if l.loaded_data == false then
		local cwd = string.gsub(vim.api.nvim_eval("getcwd()"), l.path_sep, "_")

		l.data_dir = string.format("%s%sbookmarks", vim.fn.stdpath("data"), l.path_sep)
		if not vim.loop.fs_stat(l.data_dir) then
			assert(os.execute("mkdir " .. l.data_dir))
		end

		l.data_filename = string.format("%s%s%s", l.data_dir, l.path_sep, cwd)

		if vim.loop.fs_stat(l.data_filename) then
			dofile(l.data_filename)
			print("load bookmarks finished..")
		end

		l.loaded_data = true
	end
end

return l
