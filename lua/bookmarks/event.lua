local e = {
    autocmd_cursorMoved = nil
}
local config = nil
local l = require("bookmarks.list")
local w = require("bookmarks.window")
local notify = require("notify")

function e.setup()
    config = require("bookmarks.config").get_data()
    e.key_bind()
    e.autocmd()
end

function e.key_bind()
    vim.keymap.set("n", config.keymap.add, ":lua require'bookmarks'.add_bookmarks()<cr>", { silent = true })
    vim.keymap.set("n", config.keymap.toggle, ":lua require'bookmarks'.toggle_bookmarks()<cr>", { silent = true })
end

function e.autocmd()
    vim.api.nvim_create_autocmd({ "VimLeave" }, {
        callback = l.persistent
    })

    vim.fn.jobstart({ "lua", "require('bookmarks.list').load_data()" })
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function()
            local start = os.clock()
            require("bookmarks.fix").fix_bookmarks()
            local spend = tostring(os.clock() - start)
            notify.notify(spend, vim.log.levels.WARN, {
                title = "spend",
            })
        end
    })

end

function e.create_autocmd_cursorMoved()
    if e.autocmd_cursorMoved == nil then
        e.autocmd_cursorMoved = vim.api.nvim_create_autocmd({ "CursorMoved" }, {
            callback = function()
                local t = vim.api.nvim_buf_get_option(0, "filetype")
                if t == "bookmarks" then
                    local line = vim.api.nvim_eval("line('.')")
                    local item = l.data[l.order_ids[line]]
                    if item ~= nil then
                        w.open_preview(item.filename, item.line)
                        w.open_detail_window(item)
                    else
                        w.open_preview(nil)
                        w.open_detail_window(nil)
                    end
                end
            end
        })
    end
end

function e.delete_autocmd_cursorMoved()
    if e.autocmd_cursorMoved ~= nil then
        vim.api.nvim_del_autocmd(e.autocmd_cursorMoved)
        e.autocmd_cursorMoved = nil
    end
end

return e
