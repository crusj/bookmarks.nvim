local e = {
    autocmd_cursorMoved = nil
}
local config = nil
local l = require("bookmarks.list")
local w = require("bookmarks.window")

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
