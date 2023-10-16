local M = {
    bookmarks = {}, -- filename description fre id line updated_at line_md5
    bookmarks_order_ids = {},
    bookmarks_order = "time",
    current_tags = "ALL", -- current  tags

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

function M.get_by_filename(filename)
    local ret = {}
    for _, v in pairs(M.bookmarks) do
        if v.filename == filename then
            ret[#ret + 1] = v
        end
    end
    return ret
end

function M.get_by_tags(tags)
    local ret = {}
    if tags == "ALL" then
        return M.bookmarks
    end

    for _, v in pairs(M.bookmarks) do
        if v.tags == tags then
            ret[#ret + 1] = v
        end
    end
    return ret
end

function M.get_tags()
    local ret = {}
    local tags_map = {}
    for _, v in pairs(M.bookmarks) do
        if v.tags ~= "" and tags_map[v.tags] == nil then
            ret[#ret + 1] = v.tags
            tags_map[v.tags] = true
        end
    end
    return ret
end

return M
