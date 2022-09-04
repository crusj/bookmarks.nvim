local config = nil
local l = require("bookmarks.list")
local w = require("bookmarks.window")
-- local notify = require("notify")

local M = {}

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
    vim.api.nvim_create_autocmd({ "VimLeave" }, {
        callback = l.persistent
    })

    vim.fn.jobstart({ "lua", "require('bookmarks.list').load_data()" })
    if config.fix_enable then
        vim.api.nvim_create_autocmd({ "BufWritePost" }, {
            callback = function()
                -- local start = os.clock()
                require("bookmarks.fix").fix_bookmarks()
                -- local spend = tostring(os.clock() - start)
                -- notify.notify(spend, vim.log.levels.WARN, {
                --     title = "spend",
                -- })
            end
        })
    end
end

return M
