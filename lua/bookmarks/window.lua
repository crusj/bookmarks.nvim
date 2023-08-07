local helper = require("bookmarks.helper")
local float = require("bookmarks.float")
local data = require("bookmarks.data")
local api = vim.api

local M = {}
local config = nil

function M.setup()
    config = require("bookmarks.config").get_data()
    vim.cmd(string.format("highlight hl_bookmarks_csl %s", config.hl.cursorline))
    float.setup()
end

local function bookmarks_autocmd(buffer)
    data.event1 = api.nvim_create_autocmd({ "CursorMoved" }, {
        callback = function()
            local line = api.nvim_eval("line('.')")
            local item = data.bookmarks[data.bookmarks_order_ids[line]] or {}

            local bookmarks_len = 0
            for _, _ in pairs(data.bookmarks) do
                bookmarks_len = bookmarks_len + 1
            end

            local cur_line = line
            if bookmarks_len == 0 then
                cur_line = 0
            end

            M.set_title(data.bufbb, string.format("Bookmarks[%d/%d]", cur_line, bookmarks_len), data.bw)
            M.preview_bookmark(item.filename, item.line)
        end,
        buffer = buffer,
    })

    data.event2 = api.nvim_create_autocmd({ "WinClosed" }, {
        callback = function()
            M.close_bookmarks()
        end,
        buffer = buffer,
    })
end

local function bookmarks_preview_autocmd(buffer)
    data.event3 = api.nvim_create_autocmd({ "WinClosed" }, {
        callback = function()
            if data.bufb ~= nil and api.nvim_buf_is_valid(data.bufb) then
                M.close_bookmarks()
            end
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
        title = "",
        row = math.floor((eh - height) / 2),
        col = math.floor((ew - width) / 2),
        relative = "editor",
        border_highlight = config.hl.border,
    }

    local pair = float.create_win(options)
    data.bufb = pair.buf
    data.bufbw = pair.win

    data.bufbb = float.create_border(options).buf

    api.nvim_buf_set_option(data.bufb, 'filetype', 'bookmarks')
    local map_opts = { buffer = data.bufb, silent = true }
    vim.keymap.set("n", config.keymap.jump, require("bookmarks").jump, map_opts)
    vim.keymap.set("n", config.keymap.delete, require("bookmarks").delete, map_opts)
    vim.keymap.set("n", config.keymap.order, function() require("bookmarks.list").refresh(true) end, map_opts)

    api.nvim_win_set_option(data.bufbw, "cursorline", true)
    api.nvim_win_set_option(data.bufbw, "wrap", false)
    api.nvim_win_set_option(data.bufbw, "winhighlight", 'Normal:normal,CursorLine:' .. data.hl_cursorline_name)
    api.nvim_set_current_win(data.bufbw)

    bookmarks_autocmd(data.bufb)
end

function M.set_title(b, title, width)
    api.nvim_buf_set_lines(b, 0, 1, false, { float.createTopLine(title, width) })
end

function M.close_bookmarks()
    -- delete CursorMoved event
    if data.event1 ~= nil then
        api.nvim_del_autocmd(data.event1)
        data.event1 = nil
    end
    -- delete BufWinLeave event
    if data.event2 ~= nil then
        api.nvim_del_autocmd(data.event2)
        data.event2 = nil
    end

    if data.bufb ~= nil and api.nvim_buf_is_valid(data.bufb) then
        api.nvim_buf_delete(data.bufb, {})
        data.bufb = nil
    end

    if data.bufbw ~= nil and api.nvim_win_is_valid(data.bufbw) then
        api.nvim_win_close(data.bufbw, true)
        data.bufbw = nil
    end

    if data.bufbb ~= nil and api.nvim_buf_is_valid(data.bufbb) then
        vim.cmd(string.format("bwipeout! %d", data.bufbb))
        data.bufbb = nil
    end

    M.close_preview()
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
        relative = "editor",
        border_highlight = config.hl.border,
    }

    if data.bufp == nil then
        local pair = float.create_win(options)
        data.bufp = pair.buf
        data.bufpw = pair.win
        bookmarks_preview_autocmd(data.bufp)

        local border_pair = float.create_border(options)
        data.bufbp = border_pair.buf
        data.bufbpw = border_pair.win
    end

    M.set_title(data.bufbp, options.title, options.width)

    if filename ~= nil then
        local lines = helper.read_all_file(filename)
        if lines == nil then
            return
        end

        data.filename = filename
        data.lineNumber = lineNumber
        api.nvim_buf_set_option(data.bufp, "modifiable", true)
        api.nvim_buf_set_lines(data.bufp, 0, -1, false, {})
        api.nvim_buf_set_lines(data.bufp, 0, #lines, false, lines)
        if config.preview_ext_enable then
            local cuts = filename:split_b(".")
            local ext = cuts[#cuts]
            if #cuts > 1 and ext ~= "" then
                api.nvim_buf_set_option(data.bufp, "filetype", ext)
            end
        end

        local cw = api.nvim_get_current_win()

        api.nvim_win_set_option(data.bufpw, "cursorline", true)
        api.nvim_win_set_option(data.bufpw, "number", true)
        api.nvim_win_set_option(data.bufpw, "winhighlight", 'Normal:normal')

        api.nvim_set_current_win(data.bufpw)
        if lineNumber <= vim.fn.line("$") then
            api.nvim_win_set_cursor(data.bufpw, { lineNumber, 0 })
        end

        vim.fn.execute("normal! zz")

        api.nvim_set_current_win(cw)
    else
        -- clear preview
        api.nvim_buf_set_option(data.bufp, "modifiable", true)
        api.nvim_buf_set_lines(data.bufp, 0, -1, false, {})
        api.nvim_buf_set_option(data.bufp, "modifiable", false)
    end
end

function M.close_preview()
    if data.bufp == nil then
        return
    end

    if api.nvim_buf_is_valid(data.bufp) then
        api.nvim_buf_delete(data.bufp, {})
        M.close_preview_border()
    end

    data.bufp = nil
end

function M.close_preview_border()
    if data.bufbp == nil then
        return
    end

    if api.nvim_buf_is_valid(data.bufbp) then
        vim.cmd(string.format("bwipeout! %d", data.bufbp))
    end

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
        relative = "editor",
        border_highlight = config.hl.border,
    }

    local pairs = float.create_win(options)
    local border_pairs = float.create_border(options)
    api.nvim_set_current_win(pairs.win)
    api.nvim_win_set_option(pairs.win, 'winhighlight', 'Normal:normal')
    api.nvim_buf_set_option(pairs.buf, 'filetype', 'bookmarks_input')
    vim.cmd("startinsert")

    return {
        pairs = pairs,
        border_pairs = border_pairs
    }
end

function M.close_add_win(buf1, buf2)
    vim.cmd(string.format("bwipeout! %d", buf1))
    vim.cmd(string.format("bwipeout! %d", buf2))
end

return M
