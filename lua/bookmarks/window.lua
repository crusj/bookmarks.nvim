local helper = require("bookmarks.helper")
local float = require("bookmarks.float")
local data = require("bookmarks.data")
local api = vim.api

local M = {}

local config = nil

function M.setup()
    config = require("bookmarks.config").get_data()
    vim.cmd(string.format("highlight hl_bookmarks_csl %s", config.hl_cursorline))
end

local function bookmarks_autocmd(buffer)
    data.event1 = api.nvim_create_autocmd({ "CursorMoved" }, {
        callback = function()
            local line = api.nvim_eval("line('.')")
            local item = data.bookmarks[data.bookmarks_order_ids[line]] or {}

            M.preview_bookmark(item.filename, item.line)
        end,
        buffer = buffer,
    })
end

function M.open_bookmarks()
    data.buff = api.nvim_get_current_buf()
    data.bufw = api.nvim_get_current_win()

    local ew = api.nvim_get_option("columns")
    local eh = api.nvim_get_option("lines")


    local width = math.floor(ew * config.width)
    local height = math.floor(eh * config.height)

    data.bw = math.floor(width * (1 - config.preview_ratio))
    data.bh = height

    local options = {
        width = data.bw,
        height = data.bh,
        title = "Bookmarks",
        row = math.floor((eh - height) / 2),
        col = math.floor((ew - width) / 2),
        relative = "editor"
    }

    local pair = float.create_win(options)
    data.bufb = pair.buf
    data.bufbw = pair.win

    data.bufbb = float.create_border(options).buf

    api.nvim_buf_set_option(data.bufb, 'filetype', 'bookmarks')
    api.nvim_buf_set_keymap(data.bufb, "n", config.keymap.jump, ":lua require'bookmarks'.jump()<cr>",
        { silent = true })
    api.nvim_buf_set_keymap(data.bufb, "n", config.keymap.delete, ":lua require'bookmarks'.delete()<cr>",
        { silent = true })
    api.nvim_buf_set_keymap(data.bufb, "n", config.keymap.order, ":lua require'bookmarks.list'.refresh(true)<cr>",
        { silent = true })

    api.nvim_win_set_option(data.bufbw, "cursorline", true)
    api.nvim_win_set_option(data.bufbw, "wrap", false)
    api.nvim_win_set_option(data.bufbw, "winhighlight", "CursorLine:" .. data.hl_cursorline_name)
    api.nvim_set_current_win(data.bufbw)

    bookmarks_autocmd(data.bufb)
end

function M.close_bookmarks()
    api.nvim_del_autocmd(data.event1)
    vim.cmd(string.format("bwipeout! %s", data.bufb))
    vim.cmd(string.format("bwipeout! %s", data.bufbb))
    M.close_preview()
    M.close_preview_border()
end

-- open preview window
function M.preview_bookmark(filename, lineNumber)
    local ew = api.nvim_get_option("columns")
    local eh = api.nvim_get_option("lines")

    local width = math.floor(ew * config.width)
    local height = math.floor(eh * config.height)
    local pw = math.floor(ew * config.width - data.bw)

    local title = "Nothing to preview"
    if filename ~= nil then
        local common_len = helper.get_str_common_len(vim.fn.getcwd(), filename)
        title = string.sub(filename, common_len + 1)
    end

    local options = {
        width = pw,
        height = height,
        title = title,
        row = math.floor((eh - height) / 2 + height - data.bh),
        col = math.floor((ew - width) / 2 + data.bw + 2),
        relative = "editor"
    }

    if data.bufp == nil then
        local pair = float.create_win(options)
        data.bufp = pair.buf
        data.bufpw = pair.win

        local border_pair = float.create_border(options)
        data.bufbp = border_pair.buf
        data.bufbpw = border_pair.win
    end


    api.nvim_buf_set_lines(data.bufbp, 0, 1, false, { float.createTopLine(options.title, options.width) })

    if filename ~= nil then
        local lines = helper.read_all_file(filename)
        data.filename = filename
        data.lineNumber = lineNumber
        api.nvim_buf_set_option(data.bufp, "modifiable", true)
        api.nvim_buf_set_lines(data.bufp, 0, -1, false, {})
        api.nvim_buf_set_lines(data.bufp, 0, #lines, false, lines)
        if config.preview_ext_enable then
            local cuts = filename:split_b(".")
            local ext = cuts[#cuts]
            api.nvim_buf_set_option(data.bufp, "filetype", ext)
        end

        local cw = api.nvim_get_current_win()

        api.nvim_win_set_cursor(data.bufpw, { lineNumber, 0 })
        api.nvim_win_set_option(data.bufpw, "cursorline", true)
        api.nvim_win_set_option(data.bufpw, "number", true)
        api.nvim_set_current_win(data.bufpw)
        vim.fn.execute("normal! zz")

        api.nvim_set_current_win(cw)

        api.nvim_buf_set_option(data.bufp, "modifiable", false)
    end
end

function M.close_preview()
    vim.cmd(string.format("bwipeout! %s", data.bufp))
    M.close_preview_border()
    data.bufp = nil
end

function M.close_preview_border()
    if data.bufbp == nil then
        return
    end

    vim.cmd(string.format("bwipeout! %s", data.bufbp))
    data.bufbp = nil
end

function M.open_add_win(line)
    local ew = api.nvim_get_option("columns")
    local eh = api.nvim_get_option("lines")
    local width, height = 100, 1
    local options = {
        width = width,
        height = height,
        title = "Input description",
        row = math.floor((eh - height) / 2),
        col = math.floor((ew - width) / 2),
        relative = "editor"
    }

    local pairs = float.create_win(options)
    local border_pairs = float.create_border(options)
    api.nvim_set_current_win(pairs.win)
    vim.cmd("startinsert")

    return {
        pairs = pairs,
        border_pairs = border_pairs
    }
end

function M.close_add_win(buf1, buf2)
    vim.cmd(string.format("bwipeout! %s", buf1))
    vim.cmd(string.format("bwipeout! %s", buf2))
end

return M
