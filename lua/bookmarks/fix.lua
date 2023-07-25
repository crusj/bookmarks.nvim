local runtimepath = vim.o.runtimepath;
vim.o.runtimepath = runtimepath .. ";/Users/crusj/Project/bookmark"
local lib = require("bookmark")

local data = require("bookmarks.data")
local api = vim.api

local function fix_bookmarks()
    local rows = vim.fn.line("$")
    local filename = api.nvim_buf_get_name(0)

    -- find bookmarks
    if data.bookmarks_groupby_filename[filename] == nil then
        return
    end

    for _, id in pairs(data.bookmarks_groupby_filename[filename]) do
        local b = data.bookmarks[id]
        if b == nil then
            return
        end

        if b.line > rows then
            b.line = rows
        end

        local text = api.nvim_buf_get_lines(0, b.line - 1, b.line, true)[1]
        if text == nil then
            goto continue
        end


        -- not change
        if lib.get_md5(text) == b.line_md5 then
            goto continue
        end

        if b.rows == nil then
            b.rows = rows
        end

        local changed_rows = math.abs(rows - b.rows)
        if changed_rows == 0 then -- try fix
            changed_rows = 5
        end

        -- up search
        local up_line = b.line
        for i = 1, changed_rows do
            up_line = up_line - 1
            if up_line < 0 then
                break
            end

            local text = api.nvim_buf_get_lines(0, up_line - 1, up_line, true)[1]
            if text ~= nil and lib.get_md5(text) == b.line_md5 then
                data.bookmarks[id].line = up_line
                data.bookmarks[id].rows = rows
                goto continue
            end
        end

        -- down search
        local down_line = b.line
        for i = 1, changed_rows do
            down_line = down_line + 1
            if down_line > rows then
                break
            end

            local text = api.nvim_buf_get_lines(0, down_line - 1, down_line, true)[1]
            if text ~= nil and lib.get_md5(text) == b.line_md5 then
                data.bookmarks[id].line = down_line
                data.bookmarks[id].rows = rows
                goto continue
            end
        end

        ::continue::
    end
end

return {
    fix_bookmarks = fix_bookmarks
}
