local data = require("bookmarks.data")
local helper = require("bookmarks.helper")
local api = vim.api

local function fix_bookmarks()
    local filename = api.nvim_buf_get_name(0)
    -- find bookmarks
    if data.bookmarks_groupby_filename[filename] == nil then
        return
    end

    local bookmarks = {};
    for _, id in pairs(data.bookmarks_groupby_filename[filename]) do
        bookmarks[#bookmarks + 1] = data.bookmarks[id];
    end

    local fixed_bookmarks = helper.get_lib().fix(filename, bookmarks)
    if #fixed_bookmarks == 0 then
        data.bookmarks = {};
        data.bookmarks_groupby_filename = {};
        return
    end

    data.bookmarks = {};
    data.bookmarks_groupby_filename[filename] = {}
    for _, bookmark in pairs(fixed_bookmarks) do
        data.bookmarks[bookmark.id] = bookmark
        data.bookmarks_groupby_filename[bookmark.filename][#data.bookmarks_groupby_filename[bookmark.filename] + 1] =
            bookmark.id
    end
end

return {
    fix_bookmarks = fix_bookmarks
}
