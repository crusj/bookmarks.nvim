local b = {}
local c = require("bookmarks.config")
local e = require("bookmarks.event")
local l = require("bookmarks.list")
local w = require("bookmarks.window")
local md5 = require("bookmarks.md5")
local data = require("bookmarks.data")
require("bookmarks.split")


function b.setup(user_config)
    c.setup(user_config)
    l.setup()
    e.setup()
    w.setup()
end

-- add bookmark
function b.add_bookmarks()
    local line = vim.fn.line('.')
    l.add_bookmark(line, vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1], vim.api.nvim_buf_get_name(0),
        vim.fn.line("$"))
end

-- open or close bookmarks window
function b.toggle_bookmarks()
    if data.bufbw ~= nil and vim.api.nvim_win_is_valid(data.bufbw) then
        w.close_bookmarks()
        return
    end

    -- open bookmarks
    l.load_data()
    w.open_bookmarks()
    l.flush()
end

-- jump to file from bookmarks
function b.jump()
    l.jump(vim.fn.line("."))
end

-- delete bookmarks
function b.delete()
    l.delete(vim.fn.line('.'))
end

return b
