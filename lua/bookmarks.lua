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
    local description = ""
    -- get description, default empty string
    vim.ui.input({
        prompt = "Description: ",
        default = "",
    }, function(input)
        if input ~= nil then
            description = input
        end
    end)

    local line = vim.fn.line('.')
    -- add bookmark only description is not empty
    if description ~= "" then
        l.add(vim.api.nvim_buf_get_name(0), line, md5.sumhexa(vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]),
            description, vim.fn.line("$"))
    end
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
    w.close_bookmarks()

end

-- delete bookmarks
function b.delete()
    local line = vim.api.nvim_eval("line('.')")
    l.delete(line)
end

return b
