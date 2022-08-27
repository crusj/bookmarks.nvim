local b = {}
local c = require("bookmarks.config")
local e = require("bookmarks.event")
local l = require("bookmarks.list")
local w = require("bookmarks.window")
require("bookmarks.split")

function b.setup(user_config)
    c.setup(user_config)
    l.setup()
    e.setup()
    w.setup()
end

-- add bookmarks
function b.add_bookmarks()
    local filename = vim.api.nvim_buf_get_name(0)
    local line = vim.api.nvim_eval("line('.')")

    local description = ""
    --Description
    vim.ui.input({
        prompt = "Description: ",
        default = "",
    }, function(input)
        if input ~= nil then
            description = input
        end
    end)

    if description ~= "" then
        l.add(filename, line, description)
    end
end

-- open or close bookmarks window
function b.toggle_bookmarks()
    if w.bufbw ~= nil and vim.api.nvim_win_is_valid(w.bufbw) then
        -- close bookmarks
        w.close_bw()

        -- close preview window
        w.close_previeww()
        -- close detail window
        w.close_detail_window()
        -- delete autocmd
        e.delete_autocmd_cursorMoved()

        return
    end

    -- open bookmarks
    e.create_autocmd_cursorMoved()
    l.load_data()
    w.open_list_window()
    l.flush()
end

-- jump to file from bookmarks
function b.jump()
    l.jump(vim.fn.line("."))

    w.close_bw()
    w.close_previeww()
    w.close_detail_window()
    e.delete_autocmd_cursorMoved()

end

-- delete bookmarks
function b.delete()
    local line = vim.api.nvim_eval("line('.')")
    l.delete(line)
end

return b
