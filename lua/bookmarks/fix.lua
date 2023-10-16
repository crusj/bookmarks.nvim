local data = require("bookmarks.data")
local helper = require("bookmarks.helper")
local api = vim.api

local function fix_bookmarks()
    local filename = api.nvim_buf_get_name(0)
    -- find bookmarks
    local gf = data.get_by_filename(filename)
    if gf == nil or #gf == 0 then
        return
    end

    -- remove
    for i, v in pairs(data.bookmarks) do
        if v.filename == filename then
            data.bookmarks[i] = nil
        end
    end

    local fixed_bookmarks = helper.get_lib().fix(filename, gf)
    if #fixed_bookmarks == 0 then
        return
    end

    for _, bookmark in pairs(fixed_bookmarks) do
        data.bookmarks[#data.bookmarks + 1] = bookmark
    end
end

return {
    fix_bookmarks = fix_bookmarks
}
