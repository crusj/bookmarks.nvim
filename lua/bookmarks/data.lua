local M = {
    bookmarks = {},                  -- filename description fre id line updated_at line_md5
    bookmarks_groupby_filename = {}, -- group bookmarks by filename
    bookmarks_order_ids = {},
    bookmarks_groupby_tags = {},     -- group bookmarks by tags
    bookmarks_order = "time",
    current_tags = "ALL",            -- current  tags
    tags = {},

    cwd = nil,
    data_filename = nil,
    loaded_data = false,
    data_dir = nil,

    bufbb = nil, -- bookmarks border buffer
    bufb = nil,
    bufbw = nil,

    bw = 0,       -- bookmarks window width
    bh = 0,       -- bookmarks window height
    tw = 0,       -- tags window width
    th = 0,       -- tags window height

    buft = nil,   -- tags buffer
    buftw = nil,  -- tags window
    bufbt = nil,  -- tags border buffer
    bufbtw = nil, -- tags border window

    buff = nil,
    bufw = nil,

    bufbp = nil,    -- preview border buffer
    bufbpw = nil,   -- preview border buffer window

    bufp = nil,     -- preview buffer
    bufpw = nil,    -- preview window
    autocmd = 0,    -- cursormoved autocmd id
    filename = "",  -- current bookmarks filename
    lineNumber = 0, -- current bookmarks line number

    bufd = nil,     -- detail buffer
    detailw = nil,  -- detail window

    hl_cursorline_name = "hl_bookmarks_csl",

    event1 = nil,
    event2 = nil,
    event3 = nil,
    event4 = nil,
    event5 = nil,

    last_win = nil,
    last_buf = nil,
}

return M
