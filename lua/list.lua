local w = require("window")
local api = vim.api

local M = {
    storage_dir = "", -- default vim.fn.stdpath("data").."/bookmarks",

    ns_id = api.nvim_create_namespace("bookmarks_marks"),
    marks = {},

    virt_text = "", -- Show virt text at the end of bookmarked lines, if it is empty, use the description of bookmarks instead.

    data = {
        bookmarks = {},                  -- filename description fre id line updated_at line_md5
        bookmarks_groupby_filename = {}, -- group bookmarks by filename
        pwd = nil,
        data_filename = nil,
        loaded_data = false,
        data_dir = nil,
        autocmd = 0,   -- cursormoved autocmd id
        filename = "", -- current bookmarks filename
    },
}

-- Restore bookmarks from disk file.
function M.setup()
    M.storage_dir = vim.fn.stdpath("data") .. "/bookmarks"

    -- vim.notify("load bookmarks data", "info")
    local currentPath = string.gsub(M.get_base_dir(), "/", "_")
    if M.data.pwd ~= nil and currentPath ~= M.data.pwd then -- maybe change session
        M.persistent()
        M.data.bookmarks = {}
        M.data.loaded_data = false
    end

    -- print(currentPath)

    if M.data.loaded_data == true then
        return
    end

    if not vim.loop.fs_stat(M.storage_dir) then
        assert(os.execute("mkdir " .. M.storage_dir))
    end

    -- local bookmarks
    local data_filename = string.format("%s%s%s", M.storage_dir, "/", currentPath):gsub("%c", "")
    -- print(data_filename)
    if vim.loop.fs_stat(data_filename) then
        dofile(data_filename)
    end


    M.data.pwd = currentPath
    M.data.loaded_data = true -- mark
    M.data.data_dir = M.storage_dir
    M.data.data_filename = data_filename
end

function M.add_bookmark()
    local line = vim.fn.line('.')
    local buf = api.nvim_get_current_buf()
    local rows = vim.fn.line("$")

    --  Open the bookmark description input box.
    local title = "Input description:"
    local bufs_pairs = w.open_add_win(title)

    -- Press the esc key to cancel add bookmark.
    vim.keymap.set("n", "<ESC>",
        function() w.close_add_win(bufs_pairs.pairs.buf, bufs_pairs.border_pairs.buf) end,
        { desc = "bookmarks close add win", silent = true, buffer = bufs_pairs.pairs.buf }
    )

    -- Press the enter key to confirm add bookmark.
    vim.keymap.set("i", "<CR>",
        function() M.handle_add(line, bufs_pairs.pairs.buf, bufs_pairs.border_pairs.buf, buf, rows) end,
        { desc = "bookmarks confirm bookmarks", silent = true, noremap = true, buffer = bufs_pairs.pairs.buf }
    )
end

function M.handle_add(line, buf1, buf2, buf, rows)
    -- Get buf's filename.
    local filename = api.nvim_buf_get_name(buf)
    if filename == nil or filename == "" then
        return
    end

    local input_line = vim.fn.line(".")

    -- Get bookmark's description.
    local description = api.nvim_buf_get_lines(buf1, input_line - 1, input_line, false)[1] or ""
    -- print(description)

    -- Close description input box.
    if description == "" then
        w.close_add_win(buf1, buf2)
        M.set_marks(buf, M.get_buf_bookmark_lines(0))
        vim.cmd("stopinsert")
        return
    end

    -- Save bookmark with description.
    -- Save bookmark as lua code.
    -- rows is the file's number..

    local id = string.format("%s:%s", filename, line)
    local now = os.time()

    if M.data.bookmarks[id] ~= nil then --update description
        if description ~= nil then
            M.data.bookmarks[id].description = description
            M.data.bookmarks[id].updated_at = now
        end
    else -- new
        M.data.bookmarks[id] = {
            filename = filename,
            line = line,
            rows = rows, -- for fix
            description = description or "",
            updated_at = now,
            is_new = true,
        }

        if M.data.bookmarks_groupby_filename[filename] == nil then
            M.data.bookmarks_groupby_filename[filename] = { id }
        else
            M.data.bookmarks_groupby_filename[filename][#M.data.bookmarks_groupby_filename[filename] + 1] = id
        end
    end

    -- Close description input box.
    w.close_add_win(buf1, buf2)
    M.set_marks(buf, M.get_buf_bookmark_lines(0))
    vim.cmd("stopinsert")
end

function M.get_buf_bookmark_lines(buf)
    local filename = api.nvim_buf_get_name(buf)
    local lines = {}
    local group = M.data.bookmarks_groupby_filename[filename]

    if group == nil then
        return lines
    end

    local tmp = {}
    for _, each in pairs(group) do
        if M.data.bookmarks[each] ~= nil and tmp[M.data.bookmarks[each].line] == nil then
            lines[#lines + 1] = M.data.bookmarks[each]
            tmp[M.data.bookmarks[each].line] = true
        end
    end

    return lines
end

-- Delete bookmark.
function M.delete()
    local line = vim.fn.line(".")
    local file_name = api.nvim_buf_get_name(0)
    local buf = api.nvim_get_current_buf()
    for k, v in pairs(M.data.bookmarks) do
        if v.line == line and file_name == v.filename then
            M.data.bookmarks[k] = nil
            M.set_marks(buf, M.get_buf_bookmark_lines(0))
            return
        end
    end
end

-- Write bookmarks into disk file for next load.
function M.persistent()
    local local_str = ""
    for id, bookmark in pairs(M.data.bookmarks) do
        local sub = M.fill_tpl(bookmark)
        if local_str == "" then
            local_str = string.format("%s%s", local_str, sub)
        else
            local_str = string.format("%s\n%s", local_str, sub)
        end
    end

    if M.data.data_filename == nil then -- lazy load,
        return
    end

    -- 1.local bookmarks
    local local_fd = assert(io.open(M.data.data_filename, "w"))
    local_fd:write(local_str)
    local_fd:close()
end

function M.fill_tpl(bookmark)
    local tpl = [[
require("list").load{
	_
}]]
    local sub = ""
    for k, v in pairs(bookmark) do
        if k ~= "is_new" then
            if sub ~= "" then
                sub = string.format("%s\n%s", sub, string.rep(" ", 4))
            end
            if type(v) == "number" or type(v) == "boolean" then
                sub = sub .. string.format("%s = %s,", k, v)
            else
                sub = sub .. string.format("%s = \"%s\",", k, v)
            end
        end
    end

    return string.gsub(tpl, "_", sub)
end

-- 获取书签存储根目录
function M.get_base_dir()
    -- 递归查找 .git 目录
    local function find_git_root(path)
        local git_path = path .. "/.git"
        local stat = vim.uv.fs_stat(git_path)
        if stat and stat.type == "directory" then
            return path
        else
            local parent_path = vim.fn.fnamemodify(path, ":h")
            if parent_path == path then
                return nil
            end
            return find_git_root(parent_path)
        end
    end

    local cwd = vim.uv.cwd()
    local git_root = find_git_root(cwd)
    if git_root then
        -- print(git_root)
        return git_root
    else
        -- print(cwd)
        return cwd
    end
end

-- 这个不能删，dotfile的时候要用
-- Dofile
function M.load(item, is_persistent)
    local id = string.format("%s:%s", item.filename, item.line)
    M.data.bookmarks[id] = item
    if is_persistent ~= nil and is_persistent == true then
        return
    end

    if M.data.bookmarks_groupby_filename[item.filename] == nil then
        M.data.bookmarks_groupby_filename[item.filename] = {}
    end
    M.data.bookmarks_groupby_filename[item.filename][#M.data.bookmarks_groupby_filename[item.filename] + 1] = id
end

function M.jump()
    local bookmarks = M.data.bookmarks

    local list = {}
    for _, bookmark in pairs(bookmarks) do
        table.insert(list, bookmark.description)
    end


    local fzf = require("fzf-lua")
    fzf.fzf_exec(list, {
        prompt = "Bookmarks> ",
        previewer = function()
            local previewer = require("fzf-lua.previewer.builtin")
            local path = require("fzf-lua.path")

            -- https://github.com/ibhagwan/fzf-lua/wiki/Advanced#neovim-builtin-preview
            -- Can this be any simpler? Do I need a custom previewer?
            local MyPreviewer = previewer.buffer_or_file:extend()

            function MyPreviewer:new(o, op, fzf_win)
                MyPreviewer.super.new(self, o, op, fzf_win)
                setmetatable(self, MyPreviewer)
                return self
            end

            function MyPreviewer:parse_entry(entry_str)
                if entry_str == "" then
                    return {}
                end
                for _, bookmark in pairs(bookmarks) do
                    if entry_str == bookmark.description then
                        local entry = path.entry_to_file(bookmark.filename .. ":" .. bookmark.line, self.opts)
                        return entry or {}
                    end
                end
            end

            return MyPreviewer
        end,
        actions = {
            ["default"] = function(selected)
                local entry = selected[1]
                if not entry then
                    return
                end

                for _, bookmark in pairs(bookmarks) do
                    if entry == bookmark.description then
                        vim.api.nvim_command("edit " .. bookmark.filename)
                        vim.api.nvim_win_set_cursor(0, { bookmark.line, 0 })
                    end
                end
            end,
        },
    })
end

-- Add virtural text for bookmarks.
function M.set_marks(buf, marks)
    local file_name = vim.api.nvim_buf_get_name(buf)
    local text = M.virt_text
    if M.marks[file_name] == nil then
        M.marks[file_name] = {}
    end

    -- clear old ext
    for _, id in ipairs(M.marks[file_name]) do
        api.nvim_buf_del_extmark(buf, M.ns_id, id)
    end

    vim.fn.sign_unplace("BookmarkSign", { buffer = buf })

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

        vim.fn.sign_place(0, "BookmarkSign", "BookmarkSign", buf, {
            lnum = mark.line,
        })
        ::continue::
    end
end

return M
