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

-- calculate window size.
local function calculate_window_size()
    local ew = api.nvim_get_option("columns")
    local eh = api.nvim_get_option("lines")
    local width = math.floor(ew * config.width)
    local height = math.floor(eh * config.height)
    -- tags
    local tw = math.floor(width * config.tags_ratio)
    local th = height
    local trow = math.floor((eh - height) / 2)
    local tcol = math.floor((ew - width) / 2) - 2
    -- bookmarks
    local bw = math.floor(width * (1 - config.preview_ratio - config.tags_ratio))
    local bh = height
    local brow = trow
    local bcol = tw + tcol + 2
    -- preview
    local pw = math.floor(width - tw - bw)
    local ph = height
    local prow = trow
    local pcol = bcol + bw + 2

    return tw, th, trow, tcol, bw, bh, brow, bcol, pw, ph, prow, pcol
end

local function bookmarks_autocmd(buffer)
    data.event1 = api.nvim_create_autocmd({ "CursorMoved" }, {
        callback = function()
            local line = api.nvim_eval("line('.')")
            local item = data.bookmarks[data.bookmarks_order_ids[line]] or {}

            local bookmarks_len = 0
            if data.bookmarks_groupby_tags[data.current_tags] ~= nil then
                for _, _ in pairs(data.bookmarks_groupby_tags[data.current_tags]) do
                    bookmarks_len = bookmarks_len + 1
                end
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
            M.close_tags()
        end,
        buffer = buffer,
    })
end

local function bookmarks_preview_autocmd(buffer)
    data.event3 = api.nvim_create_autocmd({ "WinClosed" }, {
        callback = function()
            if data.bufb ~= nil and api.nvim_buf_is_valid(data.bufb) then
                M.close_bookmarks()
                M.close_tags()
            end
        end,
        buffer = buffer,
    })
end

local function tags_autocmd(buffer)
    data.event4 = api.nvim_create_autocmd({ "WinClosed" }, {
        callback = function()
            if data.bufb ~= nil and api.nvim_buf_is_valid(data.buft) then
                M.close_tags()
                M.close_preview()
                M.close_bookmarks()
            end
        end,
        buffer = buffer,
    })
    data.event5 = api.nvim_create_autocmd({ "CursorMoved" }, {
        callback = function()
            if data.bufb == nil or not api.nvim_buf_is_valid(data.bufb) then
                return
            end
            if not M.change_tags() then
                return
            end

            local line = 1
            local item = data.bookmarks[data.bookmarks_order_ids[line]] or {}

            local bookmarks_len = 0
            if data.bookmarks_groupby_tags[data.current_tags] ~= nil then
                for _, _ in pairs(data.bookmarks_groupby_tags[data.current_tags]) do
                    bookmarks_len = bookmarks_len + 1
                end
            end

            local cur_line = line
            if bookmarks_len == 0 then
                cur_line = 0
            end

            M.set_title(data.bufbb, string.format("Bookmarks[%d/%d]", cur_line, bookmarks_len), data.bw)
            M.preview_bookmark(item.filename, item.line)
        end,
        buffer = buffer
    })
end

function M.open_bookmarks()
    data.buff = api.nvim_get_current_buf()
    data.bufw = api.nvim_get_current_win()

    local _, _, _, _, w, h, wrow, wcol, _, _, _, _ = calculate_window_size()
    data.bw = w
    data.bh = h

    local options = {
        width = w,
        height = h,
        title = "",
        row = wrow,
        col = wcol,
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
    vim.keymap.set("n", "<2-LeftMouse>", require("bookmarks").jump, map_opts)
    vim.keymap.set("n", config.keymap.delete, require("bookmarks").delete, map_opts)
    vim.keymap.set("n", config.keymap.order, function() require("bookmarks.list").refresh(true) end, map_opts)

    api.nvim_win_set_option(data.bufbw, "cursorline", true)
    api.nvim_win_set_option(data.bufbw, "wrap", false)
    api.nvim_win_set_option(data.bufbw, "winhighlight", 'Normal:normal,CursorLine:' .. data.hl_cursorline_name)
    api.nvim_set_current_win(data.bufbw)
    bookmarks_autocmd(data.bufb)

    M.open_tags()
    vim.keymap.set(
        "n",
        "<c-j>",
        function()
            if api.nvim_win_is_valid(data.buftw) then
                api.nvim_set_current_win(data.buftw)
            end
        end,
        { silent = true, noremap = true, buffer = data.bufb }
    )
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
    M.close_tags()
end

-- open tags window
function M.open_tags()
    local w, h, wr, wc, _, _, _, _, _, _, _, _ = calculate_window_size()
    local options = {
        width = w,
        height = h,
        title = "Tags",
        row = wr,
        col = wc,
        relative = "editor",
        border_highlight = config.hl.border,
    }
    local pair = float.create_win(options)
    tags_autocmd(pair.buf)
    data.buft = pair.buf
    data.buftw = pair.win
    data.buftb = float.create_border(options).buf
    api.nvim_buf_set_option(pair.buf, 'filetype', 'btags')
    vim.keymap.set(
        "n",
        "<2-LeftMouse>",
        function()
            M.change_tags()
            api.nvim_set_current_win(data.bufbw)
        end,
        { silent = true, noremap = true, buffer = data.buft }
    )
    vim.keymap.set(
        "n",
        "<CR>",
        function()
            M.change_tags()
            api.nvim_set_current_win(data.bufbw)
        end,
        { silent = true, noremap = true, buffer = data.buft }
    )
    vim.keymap.set(
        "n",
        "<c-k>",
        function() api.nvim_set_current_win(data.bufbw) end,
        { silent = true, noremap = true, buffer = data.buft }
    )
    M.write_tags()
end

-- close tags window
function M.close_tags()
    if data.buft == nil then
        return
    end

    if api.nvim_buf_is_valid(data.buft) then
        api.nvim_buf_delete(data.buft, {})
    end

    data.buft = nil
    M.close_tags_border()
end

function M.close_tags_border()
    if data.buftb == nil then
        return
    end

    if api.nvim_buf_is_valid(data.buftb) then
        vim.cmd(string.format("bwipeout! %d", data.buftb))
    end

    data.buftb = nil
end

function M.write_tags()
    api.nvim_buf_set_option(data.buft, "modifiable", true)
    -- empty
    api.nvim_buf_set_lines(data.buft, 0, -1, false, {})
    -- flush
    local tags_list = {}
    for tags, _ in pairs(data.bookmarks_groupby_tags) do
        if tags ~= "ALL" then
            tags_list[#tags_list + 1] = tags
        end
    end
    table.sort(tags_list)

    local current_line = 1;
    data.tags = {}
    data.tags[#data.tags + 1] = "ALL"
    for i, value in pairs(tags_list) do
        if data.current_tags == value then
            current_line = i + 1
        end
        data.tags[#data.tags + 1] = value
    end
    local show_tags = {}
    for i, value in pairs(data.tags) do
        if i == current_line then
            show_tags[#show_tags + 1] = string.format("󰁕 %s", value)
        else
            show_tags[#show_tags + 1] = string.format("  %s", value)
        end
    end

    api.nvim_buf_set_lines(data.buft, 0, -1, false, {})
    api.nvim_buf_set_lines(data.buft, 0, #show_tags, false, show_tags)
    api.nvim_buf_set_option(data.buft, "modifiable", false)
    api.nvim_win_set_option(data.buftw, "winhighlight", 'Normal:normal,CursorLine:' .. data.hl_cursorline_name)
    api.nvim_win_set_option(data.buftw, "cursorline", true)
    api.nvim_win_set_cursor(data.buftw, { current_line, 0 })
end

function M.change_tags()
    local line = vim.fn.line('.')
    if data.current_tags == data.tags[line] then
        return false
    end

    data.current_tags = data.tags[line]
    M.write_tags()
    require("bookmarks.list").refresh(false)

    return true
end

function M.delete_tags(line)
    local tags = data.bookmarks[data.bookmarks_order_ids[line]].tags
    if tags ~= "" and tags ~= nil then
        if data.bookmarks_groupby_tags[tags] ~= nil then
            -- set nil
            if #data.bookmarks_groupby_tags[tags] == 1 then
                data.bookmarks_groupby_tags[tags] = nil
                data.current_tags = "ALL"
            else
                -- remove from tags list
                for i, each in pairs(data.bookmarks_groupby_tags[tags]) do
                    if each == data.bookmarks_order_ids[line] then
                        data.bookmarks_groupby_tags[tags][i] = nil
                    end
                end
            end
        end

        -- remove from ALL tags list.
        for i, each in pairs(data.bookmarks_groupby_tags["ALL"]) do
            if each == data.bookmarks_order_ids[line] then
                data.bookmarks_groupby_tags["ALL"][i] = nil
            end
        end
    end
    data.bookmarks[data.bookmarks_order_ids[line]] = nil
end

function M.regroup_tags(tags)
    if tags == nil or tags == "" then
        return
    end
    local new_tags_group = {}
    local all_tags_group = {}
    for _, each in pairs(data.bookmarks) do
        all_tags_group[#all_tags_group + 1] = each.id
        if each.tags == tags then
            new_tags_group[#new_tags_group + 1] = each.id
        end
    end
    data.bookmarks_groupby_tags[tags] = new_tags_group
    data.bookmarks_groupby_tags["ALL"] = all_tags_group
end

-- open preview window
function M.preview_bookmark(filename, lineNumber)
    local _, _, _, _, _, _, _, _, w, h, pr, pc = calculate_window_size()

    local title = "Nothing to preview"
    if filename ~= nil then
        local common_len = helper.get_str_common_len(vim.fn.getcwd(), filename)
        title = string.sub(filename, common_len + 1)
    end

    local options = {
        width = w,
        height = h,
        title = title,
        row = pr,
        col = pc,
        relative = "editor",
        border_highlight = config.hl.border,
        focusable = false,
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
        local lines, relative_line_number = helper.read_preview_content(filename, h, lineNumber)
        if lines == nil then
            return
        end

        data.filename = filename
        data.lineNumber = lineNumber
        api.nvim_buf_set_option(data.bufp, "modifiable", true)
        api.nvim_buf_set_lines(data.bufp, 0, -1, false, {})
        api.nvim_buf_set_lines(data.bufp, 0, #lines, false, lines)

        vim.schedule(function()
            local cuts = filename:split_b(".")
            local ext = cuts[#cuts]
            if #cuts > 1 and ext ~= "" then
                api.nvim_buf_set_option(data.bufp, "syntax", ext)
                vim.treesitter.start(data.bufp, ext)
            end
        end)

        local cw = api.nvim_get_current_win()
        api.nvim_win_set_option(data.bufpw, "cursorline", true)
        api.nvim_win_set_option(data.bufpw, "number", false)
        api.nvim_win_set_option(data.bufpw, "winhighlight", 'Normal:normal')

        api.nvim_set_current_win(data.bufpw)
        if relative_line_number <= h then
            api.nvim_win_set_cursor(data.bufpw, { relative_line_number, 0 })
        end

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
