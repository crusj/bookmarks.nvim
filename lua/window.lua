local M = {
    hl = {
        border = "TelescopeBorder",            -- border highlight
        cursorline = "guibg=Gray guifg=White", -- cursorline highlight
    },
    border_chars = {
        TOP_LEFT = "╭",
        TOP_RIGHT = "╮",
        MID_HORIZONTAL = "─",
        MID_VERTICAL = "│",
        BOTTOM_LEFT = "╰",
        BOTTOM_RIGHT = "╯",
    },
    default_opts = {
        relative = "editor",
        width = 80,
        height = 40,
        row = 5,
        col = 10,
        title = "test-title",
        options = {},
        border = true,
    },
}

function M.createTopLine(str, width)
    local len
    if str == nil then
        len = 2
    else
        len = #str + 2
    end

    local returnString = ""
    if len ~= 2 then
        returnString = returnString
            .. string.rep(M.border_chars.MID_HORIZONTAL, math.floor(width / 2 - len / 2))
            .. " "
            .. str
            .. " "
        local remaining = width - (len + math.floor(width / 2 - len / 2))
        returnString = returnString .. string.rep(M.border_chars.MID_HORIZONTAL, remaining)
    else
        returnString = returnString .. string.rep(M.border_chars.MID_HORIZONTAL, width)
    end

    return M.border_chars.TOP_LEFT .. returnString .. M.border_chars.TOP_RIGHT
end

function M.fill_border_data(buf, width, height, title)
    local topLine = M.createTopLine(title, width)
    local border_lines = {
        topLine
    }

    local middle_line = M.border_chars.MID_VERTICAL
        .. string.rep(" ", width)
        .. M.border_chars.MID_VERTICAL
    for _ = 1, height do
        table.insert(border_lines, middle_line)
    end
    table.insert(
        border_lines,
        M.border_chars.BOTTOM_LEFT
        .. string.rep(M.border_chars.MID_HORIZONTAL, width)
        .. M.border_chars.BOTTOM_RIGHT
    )

    api.nvim_buf_set_lines(buf, 0, -1, false, border_lines)
end

local function create_win(row, col, width, height, relative, focusable, zindex)
    local buf = api.nvim_create_buf(false, true)
    local options = {
        style = "minimal",
        relative = relative,
        width = width,
        height = height,
        row = row,
        col = col,
        focusable = focusable,
        zindex = zindex,
    }
    local win = api.nvim_open_win(buf, false, options)

    return {
        buf = buf,
        win = win,
    }
end

function M.create_win(opts)
    opts.width = opts.width or M.default_opts.width
    opts.height = opts.height or M.default_opts.height
    opts.title = opts.title or M.default_opts.title
    opts.row = opts.row or M.default_opts.row
    opts.col = opts.col or M.default_opts.col
    opts.relative = opts.relative or "editor"

    if opts.focusable == nil then
        opts.focusable = true
    end
    if opts.border == nil then
        opts.border = M.default_opts.border
    end

    -- buf
    local win_buf_pair = create_win(
        opts.row,
        opts.col,
        opts.width,
        opts.height,
        opts.relative,
        opts.focusable,
        256
    )

    return win_buf_pair
end

function M.create_border(opts)
    local border_win_buf_pair = create_win(opts.row - 1,
        opts.col - 1,
        opts.width + 2,
        opts.height + 2,
        opts.relative,
        false,
        255
    )

    opts.border_highlight = opts.border_highlight or "Normal"
    api.nvim_buf_set_option(border_win_buf_pair.buf, "bufhidden", "hide")
    local border_buf = border_win_buf_pair.buf
    M.fill_border_data(
        border_buf,
        opts.width,
        opts.height,
        opts.title
    )

    api.nvim_win_set_option(
        border_win_buf_pair.win,
        "winhighlight",
        "Normal:" .. opts.border_highlight
    )

    return border_win_buf_pair
end

local focus_manager = (function()
    --- @alias WinType string
    --- @alias WinId integer
    local current_type = nil --- @type WinType | nil
    local win_types = {}     --- @type WinType[]
    local wins = {}          --- @type table<WinType, WinId>

    local function toogle()
        local next_type = nil
        for i, type in ipairs(win_types) do
            if type == current_type then
                local next_i = i + 1
                if next_i > #win_types then next_i = 1 end
                next_type = win_types[next_i]
                break
            end
        end

        if next_type == nil then next_type = win_types[1] end

        local next_win = wins[next_type]
        if next_win == nil then
            local msg = string.format("%s window not found", next_type)
            vim.notify(msg, vim.log.levels.INFO, { title = "bookmarks.nvim" })
            return
        end

        current_type = next_type
        api.nvim_set_current_win(next_win)
    end

    return {
        toogle = toogle,
        update_current = function(type) current_type = type end,
        set = function(type, win) wins[type] = win end,
        register = function(type)
            local exist = vim.tbl_contains(win_types, type)
            if not exist then table.insert(win_types, type) end
        end,
    }
end)()


function M.setup()
    vim.cmd(string.format("highlight hl_bookmarks_csl %s", M.hl.cursorline))
    focus_manager.register("bookmarks")
end

function M.open_add_win(title)
    local ew = api.nvim_get_option("columns")
    local eh = api.nvim_get_option("lines")
    local width, height = 100, 1
    local options = {
        width = width,
        height = height,
        title = title,
        row = math.floor((eh - height) / 2),
        col = math.floor((ew - width) / 2),
        relative = "editor",
        border_highlight = M.hl.border,
    }

    local pairs = M.create_win(options)
    local border_pairs = M.create_border(options)
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
