local config = nil
local l = require("bookmarks.list")
local w = require("bookmarks.window")
local m = require("bookmarks.marks")
-- local notify = require("notify")

local M = {}
local api = vim.api

function M.setup()
    config = require("bookmarks.config").get_data()
    M.key_bind()
    M.autocmd()
end

function M.key_bind()
    vim.keymap.set("n", config.keymap.add, ":lua require'bookmarks'.add_bookmarks()<cr>", { silent = true })
    vim.keymap.set("n", config.keymap.toggle, ":lua require'bookmarks'.toggle_bookmarks()<cr>", { silent = true })
end

function M.autocmd()
    api.nvim_create_autocmd({ "VimLeave" }, {
        callback = l.persistent
    })

    require('bookmarks.list').load_data()
    api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function()
            if config.fix_enable then
                require("bookmarks.fix").fix_bookmarks()
            end
            local buf = api.nvim_get_current_buf()
            m.set_marks(buf, l.get_buf_bookmark_lines(buf))
        end
    })

    api.nvim_create_autocmd({ "BufWinEnter" }, {
        pattern = config.virt_pattern,
        callback = function()
            local buf = api.nvim_get_current_buf()
            m.set_marks(buf, l.get_buf_bookmark_lines(buf))
        end
    })
end

return M
