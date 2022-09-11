require("bookmarks.split")

local c = require("bookmarks.config")
local e = require("bookmarks.event")
local l = require("bookmarks.list")
local w = require("bookmarks.window")
local md5 = require("bookmarks.md5")
local data = require("bookmarks.data")

local M = {}

function M.setup(user_config)
    c.setup(user_config)
    l.setup()
    e.setup()
    w.setup()
end

-- add bookmark
function M.add_bookmarks()
    local line = vim.fn.line('.')
    l.add_bookmark(line, vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1], vim.api.nvim_buf_get_name(0),
        vim.fn.line("$"))
end

-- open or close bookmarks window
function M.toggle_bookmarks()
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
function M.jump()
    l.jump(vim.fn.line("."))
end

-- delete bookmarks
function M.delete()
    l.delete(vim.fn.line('.'))
end

return M
