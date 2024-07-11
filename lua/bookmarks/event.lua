local config = nil
local l = require("bookmarks.list")
local m = require("bookmarks.marks")

local M = {}
local api = vim.api

function M.setup()
    config = require("bookmarks.config").get_data()
    if config == nil then
        return
    end

    if config.mappings_enabled then
        M.key_bind()
    end

    M.autocmd()
end

-- global keymaps.
function M.key_bind()
    -- check nil
    if config == nil then
        return
    end

    -- add local bookmarks
    vim.keymap.set("n", config.keymap.add, function() require("bookmarks").add_bookmarks(false) end,
        { desc = "bookmarks add", silent = true })
    -- add global bookmarks
    vim.keymap.set("n", config.keymap.add_global, function() require("bookmarks").add_bookmarks(true) end,
        { desc = "bookmarks add global", silent = true })
    -- toggle bookmarks window
    vim.keymap.set("n", config.keymap.toggle, function() require("bookmarks").toggle_bookmarks() end,
        { desc = "bookmarks toggle", silent = true })
    -- delete bookmarks
    vim.keymap.set("n", config.keymap.delete_on_virt, function() require("bookmarks.list").delete_on_virt() end,
        { desc = "bookmarks delete", silent = true })
    -- show bookmarks description.
    vim.keymap.set("n", config.keymap.show_desc, function() require("bookmarks.list").show_desc() end,
        { desc = "bookmarks show desc", silent = true })
end

--
function M.autocmd()
    api.nvim_create_autocmd({ "VimLeave" }, {
        callback = l.persistent
    })

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
