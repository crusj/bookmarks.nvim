local api = vim.api
local M = {
    ns_id = api.nvim_create_namespace("bookmarks_marks"),
    marks = {},
}

function M.set_marks(buf, lines)
    local file_name = vim.api.nvim_buf_get_name(buf)
    local pattern = require("bookmarks.config").data.virt_pattern
    local cuts = file_name:split_b(".")
    local t = cuts[#cuts]
    local is_match = false

    for _, p in ipairs(pattern) do
        if string.sub(p, 3) == t then
            is_match = true
            break
        end
    end
    if is_match == false then
        return
    end

    local text = require("bookmarks.config").data.virt_text

    if M.marks[file_name] == nil then
        M.marks[file_name] = {}
    end


    -- clear old ext
    for _, id in ipairs(M.marks[file_name]) do
        api.nvim_buf_del_extmark(buf, M.ns_id, id)
    end

    -- set new old ext
    for _, line in ipairs(lines) do
        local ext_id = api.nvim_buf_set_extmark(buf, M.ns_id, line - 1, -1, {
            virt_text = { { text } },
            virt_text_pos = "eol",
            hl_mode = "combine",
        })
        M.marks[file_name][#M.marks[file_name] + 1] = ext_id
    end
end

return M
