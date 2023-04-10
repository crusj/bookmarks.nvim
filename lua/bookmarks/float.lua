local api = vim.api
local M = {}

local border_chars = {
    TOP_LEFT = "┌",
    TOP_RIGHT = "┐",
    MID_HORIZONTAL = "─",
    MID_VERTICAL = "│",
    BOTTOM_LEFT = "└",
    BOTTOM_RIGHT = "┘",
}

local default_opts = {
    relative = "editor",
    width = 80,
    height = 40,
    row = 5,
    col = 10,
    title = "test-title",
    options = {},
    border = true,
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
            .. string.rep(border_chars.MID_HORIZONTAL, math.floor(width / 2 - len / 2))
            .. " "
            .. str
            .. " "
        local remaining = width - (len + math.floor(width / 2 - len / 2))
        returnString = returnString .. string.rep(border_chars.MID_HORIZONTAL, remaining)
    else
        returnString = returnString .. string.rep(border_chars.MID_HORIZONTAL, width)
    end

    return border_chars.TOP_LEFT .. returnString .. border_chars.TOP_RIGHT
end

function M.fill_border_data(buf, width, height, title)
    local topLine = M.createTopLine(title, width)
    local border_lines = {
        topLine
    }

    local middle_line = border_chars.MID_VERTICAL
        .. string.rep(" ", width)
        .. border_chars.MID_VERTICAL
    for _ = 1, height do
        table.insert(border_lines, middle_line)
    end
    table.insert(
        border_lines,
        border_chars.BOTTOM_LEFT
        .. string.rep(border_chars.MID_HORIZONTAL, width)
        .. border_chars.BOTTOM_RIGHT
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
    opts.width = opts.width or default_opts.width
    opts.height = opts.height or default_opts.height
    opts.title = opts.title or default_opts.title
    opts.row = opts.row or default_opts.row
    opts.col = opts.col or default_opts.col
    opts.relative = opts.relative or "editor"
    if opts.border == nil then
        opts.border = default_opts.border
    end

    -- buf
    local win_buf_pair = create_win(
        opts.row,
        opts.col,
        opts.width,
        opts.height,
        opts.relative,
        true,
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

return M
