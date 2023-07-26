local c = require("bookmarks.config")
local e = require("bookmarks.event")
local l = require("bookmarks.list")
local w = require("bookmarks.window")
local data = require("bookmarks.data")
local api = vim.api

-- Check module telescope is exists.
if pcall(require, "telescope") then
    require("telescope._extensions.bookmarks")
end

local M = {}

function M.setup(user_config)
    require("bookmarks.split")
    require("bookmarks.install")
    c.setup(user_config)
    l.setup()
    e.setup()
    w.setup()
end

-- Add bookmark.
function M.add_bookmarks()
    l.add_bookmark(vim.fn.line('.'), api.nvim_get_current_buf(), vim.fn.line("$"))
end

-- Open bookmarks window.
function M.open_bookmarks()
    data.last_win = vim.api.nvim_get_current_win()
    data.last_buf = vim.api.nvim_get_current_buf()

    -- open bookmarks
    l.load_data()
    w.open_bookmarks()
    l.flush()
end

-- Close bookmarks window.
function M.close_bookmarks()
    w.close_bookmarks()
    l.restore()
end

-- Toggle bookmarks window.
function M.toggle_bookmarks()
    if data.bufbw ~= nil and vim.api.nvim_win_is_valid(data.bufbw) then
        M.close_bookmarks()
    else
        M.open_bookmarks()
    end
end

-- Jump to the corresponding bookmark's location.
function M.jump()
    l.jump(vim.fn.line("."))
end

-- Delete bookmarks.
function M.delete()
    l.delete(vim.fn.line('.'))
end

return M
