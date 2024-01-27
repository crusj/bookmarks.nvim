local api = vim.api
local M = {
    ns_id = api.nvim_create_namespace("bookmarks_marks"),
    marks = {},
}

-- Add virtural text for bookmarks.
function M.set_marks(buf, marks)
    local file_name = vim.api.nvim_buf_get_name(buf)
    local pattern = require("bookmarks.config").data.virt_pattern
    local ignore_pattern = require("bookmarks.config").data.virt_ignore_pattern
    local cuts = file_name:split_b(".")

    if #cuts > 1 then
        local ext = cuts[#cuts]
        local is_match = false
        for _, p in ipairs(pattern) do
            local suffix = string.sub(p, 3)
            if p == '*' or suffix == '*' or suffix == ext then
                is_match = true
                break
            end
        end
        for _, p in ipairs(ignore_pattern) do
            local suffix = string.sub(p, 3)
            if p == '*' or suffix == '*' or suffix == ext then
                is_match = false
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
    M.delete_sign(buf)

    -- set new old ext
    for _, mark in ipairs(marks) do
        if mark.line > vim.fn.line("$") then
            goto continue
        end

        local virt_text = text
        if virt_text == "" then
            virt_text = mark.description
        end
        local ext_id = api.nvim_buf_set_extmark(buf, M.ns_id, mark.line - 1, -1, {
            virt_text = { { virt_text, "bookmarks_virt_text_hl" } },
            virt_text_pos = "eol",
            hl_group = "bookmarks_virt_text_hl",
            hl_mode = "combine"
        })
        M.marks[file_name][#M.marks[file_name] + 1] = ext_id

        if require("bookmarks.config").data.sign_icon ~= "" then
            M.set_sign(buf, mark.line)
        end
        ::continue::
    end
end

function M.set_sign(pb, line)
    vim.fn.sign_place(0, "BookmarkSign", "BookmarkSign", pb, {
        lnum = line,
    })
end

function M.delete_sign(pb)
    vim.fn.sign_unplace("BookmarkSign", { buffer = pb })
end

return M
