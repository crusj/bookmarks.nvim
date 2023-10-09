local api = vim.api
local M = {
    ns_id = api.nvim_create_namespace("bookmarks_marks"),
    marks = {},
}

-- Add virtural text for bookmarks.
function M.set_marks(buf, marks)
    local file_name = vim.api.nvim_buf_get_name(buf)
    local pattern = require("bookmarks.config").data.virt_pattern
    local cuts = file_name:split_b(".")

    if #cuts > 1 then
        local ext = cuts[#cuts]
        local is_match = false
        for _, p in ipairs(pattern) do
            if string.sub(p, 3) == ext then
                is_match = true
                break
            end
        end
        if is_match == false then
            return
        end
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
    for _, mark in ipairs(marks) do
        if mark.line > vim.fn.line("$") then
            goto continue
        end

        local virt_text = text
        if virt_text == "" then
            virt_text = "🔖 " .. mark.description
        end
        local ext_id = api.nvim_buf_set_extmark(buf, M.ns_id, mark.line - 1, -1, {
            virt_text = { { virt_text, "bookmarks_virt_text" } },
            virt_text_pos = "eol",
            hl_group = "bookmarks_virt_text_hl",
        })
        M.marks[file_name][#M.marks[file_name] + 1] = ext_id
        ::continue::
    end
end

return M
