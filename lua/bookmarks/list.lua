local md5 = require("bookmarks.md5")
local w = require("bookmarks.window")
local data = require("bookmarks.data")
local m = require("bookmarks.marks")
local utf8 = require("bookmarks.utf8")
local api = vim.api
local config

local M = {}

function M.setup()
    config = require "bookmarks.config".get_data()
    M.load_data()
end

function M.add_bookmark(line, buf, rows, is_global)
    --  Open the bookmark description input box.
    local title = "Input description: [Tag:]Desc"
    if is_global then
        title = "Global Input description: [Tag:]Desc"
    end
    local bufs_pairs = w.open_add_win(title)

    -- Press the esc key to cancel add bookmark.
    vim.keymap.set("n", "<ESC>",
        function() w.close_add_win(bufs_pairs.pairs.buf, bufs_pairs.border_pairs.buf) end,
        { desc = "bookmarks close add win", silent = true, buffer = bufs_pairs.pairs.buf }
    )

    -- Press the enter key to confirm add bookmark.
    vim.keymap.set("i", "<CR>",
        function() M.handle_add(line, bufs_pairs.pairs.buf, bufs_pairs.border_pairs.buf, buf, rows, is_global) end,
        { desc = "bookmarks confirm bookmarks", silent = true, noremap = true, buffer = bufs_pairs.pairs.buf }
    )
end

function M.handle_add(line, buf1, buf2, buf, rows, is_global)
    -- Get buf's filename.
    local filename = api.nvim_buf_get_name(buf)
    if filename == nil or filename == "" then
        return
    end

    local input_line = vim.fn.line(".")
    -- Get bookmark's description.
    local description = api.nvim_buf_get_lines(buf1, input_line - 1, input_line, false)[1] or ""
    if description ~= "" then
        local content = api.nvim_buf_get_lines(buf, line - 1, line, true)[1]
        -- Save bookmark with description.
        M.add(filename, line, md5.sumhexa(content),
            description, rows, is_global)
    end

    -- Close description input box.
    w.close_add_win(buf1, buf2)
    m.set_marks(buf, M.get_buf_bookmark_lines(0))
    vim.cmd("stopinsert")
end

-- Save bookmark as lua code.
-- rows is the file's number..
function M.add(filename, line, line_md5, description, rows, is_global)
    local id = md5.sumhexa(string.format("%s:%s", filename, line))
    local now = os.time()
    local cuts = description:split_b(":")
    local tags = ""
    if #cuts > 1 then
        tags = cuts[1]
        description = string.sub(description, #tags + 2)
    end

    if data.bookmarks[id] ~= nil then --update description
        if description ~= nil then
            data.bookmarks[id].description = description
            data.bookmarks[id].updated_at = now
            data.bookmarks[id].tags = tags
        end
    else -- new
        data.bookmarks[id] = {
            filename = filename,
            id = id,
            tags = tags,
            line = line,
            description = description or "",
            updated_at = now,
            fre = 1,
            rows = rows,         -- for fix
            line_md5 = line_md5, -- for fix
            is_global = is_global,
        }

        if data.bookmarks_groupby_filename[filename] == nil then
            data.bookmarks_groupby_filename[filename] = { id }
        else
            data.bookmarks_groupby_filename[filename][#data.bookmarks_groupby_filename[filename] + 1] = id
        end

        if data.bookmarks_groupby_tags["ALL"] == nil then
            data.bookmarks_groupby_tags["ALL"] = {}
        end
        data.bookmarks_groupby_tags["ALL"][#data.bookmarks_groupby_tags["ALL"] + 1] = id

        if tags ~= "" then
            if data.bookmarks_groupby_tags[tags] == nil then
                data.bookmarks_groupby_tags[tags] = { id }
            else
                data.bookmarks_groupby_tags[tags][#data.bookmarks_groupby_tags[tags] + 1] = id
            end
        end
    end
end

function M.get_buf_bookmark_lines(buf)
    local filename = api.nvim_buf_get_name(buf)
    local lines = {}
    local group = data.bookmarks_groupby_filename[filename]

    if group == nil then
        return lines
    end

    local tmp = {}
    for _, each in pairs(group) do
        if data.bookmarks[each] ~= nil and tmp[data.bookmarks[each].line] == nil then
            lines[#lines + 1] = data.bookmarks[each]
            tmp[data.bookmarks[each].line] = true
        end
    end

    return lines
end

-- Delete bookmark.
function M.delete(line)
    if data.bookmarks_order_ids[line] ~= nil then
        w.delete_tags(line)
        w.write_tags()
        M.refresh()
    end
end

-- Delete bookmark.
function M.delete_on_virt()
    local line = vim.fn.line(".")
    local file_name = api.nvim_buf_get_name(0)
    local buf = api.nvim_get_current_buf()
    for k, v in pairs(data.bookmarks) do
        if v.line == line and file_name == v.filename then
            data.bookmarks[k] = nil
            w.regroup_tags(v.tags)
            m.set_marks(buf, M.get_buf_bookmark_lines(0))
            return
        end
    end
end

-- Update bookmarks list by time or frequery.
function M.refresh(order)
    if order == true then
        if data.bookmarks_order == "time" then
            data.bookmarks_order = "fre"
        else
            data.bookmarks_order = "time"
        end
    end

    M.flush()
end

-- Write the saved bookmark list to the bookmark window for display.
function M.flush()
    -- order
    local tmp_data = {}
    if data.bookmarks_groupby_tags[data.current_tags] ~= nil then
        for _, item in pairs(data.bookmarks_groupby_tags[data.current_tags]) do
            tmp_data[#tmp_data + 1] = data.bookmarks[item]
        end
    end

    -- sort list by time or frequery.
    if data.bookmarks_order == "time" then
        table.sort(tmp_data, function(e1, e2)
            return e1.updated_at > e2.updated_at
        end)
    else
        table.sort(tmp_data, function(e1, e2)
            return e1.fre > e2.fre
        end)
    end

    data.bookmarks_order_ids = {}
    local lines = {}
    for _, item in ipairs(tmp_data) do
        if item.filename == nil or item.filename == "" then
            goto continue
        end

        local s = item.filename:split_b("/")
        local rep1 = math.floor(data.bw * 0.3)
        local rep2 = math.floor(data.bw * 0.5)

        local icon = (require 'nvim-web-devicons'.get_icon(item.filename)) or ""

        local tmp = item.fre
        if data.bookmarks_order == "time" then
            tmp = os.date("%Y-%m-%d %H:%M:%S", item.updated_at)
            rep2 = math.floor(data.bw * 0.4)
        end


        local description = item.description
        if item.is_global ~= nil and item.is_global == true then -- global description
            description = string.format("󰯾 %s", description)
        end

        lines[#lines + 1] = string.format("%s %s [%s]",
            M.padding(string.format("%s|%s", M.padding(tostring(item.line), 3), description), rep1),
            M.padding(icon .. " " .. s[#s], rep2), tmp)
        data.bookmarks_order_ids[#data.bookmarks_order_ids + 1] = item.id
        ::continue::
    end

    api.nvim_buf_set_option(data.bufb, "modifiable", true)
    -- empty
    api.nvim_buf_set_lines(data.bufb, 0, -1, false, {})
    -- flush
    api.nvim_buf_set_lines(data.bufb, 0, #lines, false, lines)
    api.nvim_win_set_cursor(data.bufbw, { 1, 0 })
    api.nvim_buf_set_option(data.bufb, "modifiable", false)
end

-- Ui: Align bookmarks display
function M.padding(str, len)
    local tmp = ""
    local total_len = 0
    for _, codepoint in utf8.codes(str) do
        local char = codepoint
        if string.len(char) == 1 or char == "…" then
            total_len = total_len + 1
        else
            total_len = total_len + 2
        end
    end
    if total_len > len then
        local show_len = len - 1
        local i = 0
        for _, codepoint in utf8.codes(str) do
            if i >= show_len then
                break
            end
            local char = codepoint
            if string.len(char) == 1 then
                tmp = tmp .. char
                i = i + 1
            else
                if i + 2 > show_len then
                    break
                end
                i = i + 2
                tmp = tmp .. char
            end
        end
        return tmp .. string.rep("…", len - i)
    else
        return str .. string.rep(" ", len - total_len)
    end
end

-- Jump hook.
function M.telescope_jump_update(id)
    data.bookmarks[id].fre = data.bookmarks[id].fre + 1
    data.bookmarks[id].updated_at = os.time()
end

-- Bookmark jump.
function M.jump(line)
    local item = data.bookmarks[data.bookmarks_order_ids[line]]

    if item == nil then
        w.close_bookmarks()
        M.restore()
        return
    end

    data.bookmarks[data.bookmarks_order_ids[line]].fre = data.bookmarks[data.bookmarks_order_ids[line]].fre + 1
    data.bookmarks[data.bookmarks_order_ids[line]].updated_at = os.time()

    local fn = function(cmd)
        vim.cmd(cmd .. item.filename)
        vim.cmd("execute  \"normal! " .. item.line .. "G;zz\"")
        vim.cmd("execute  \"normal! zz\"")
    end

    local is_default_buf = function(str)
        local parts = {}
        for part in string.gmatch(str, "%S+") do
            table.insert(parts, part)
        end
        local last = parts[#parts]
        if last == '[1]' then
            return true
        else
            return false
        end
    end

    local pre_buf_name = api.nvim_buf_get_name(data.buff)
    if vim.loop.fs_stat(pre_buf_name) then
        api.nvim_set_current_win(data.bufw)
        fn("e ")
        goto continue
        return
    else
        for _, id in pairs(api.nvim_list_wins()) do
            local buf = api.nvim_win_get_buf(id)
            if vim.loop.fs_stat(api.nvim_buf_get_name(buf)) or is_default_buf(api.nvim_buf_get_name(buf)) then
                api.nvim_set_current_win(id)
                fn("e ")
                goto continue
                return
            end
        end
        fn("vs ")
    end

    ::continue::
    w.close_bookmarks()
end

function M.restore()
    if data.last_win ~= nil and vim.api.nvim_win_is_valid(data.last_win) then
        vim.api.nvim_set_current_win(data.last_win)
    end

    -- refresh virtual marks
    if data.last_buf ~= nil and vim.api.nvim_buf_is_valid(data.last_buf) then
        m.set_marks(data.last_buf, M.get_buf_bookmark_lines(data.last_buf))
    end
end

-- Write bookmarks into disk file for next load.
function M.persistent()
    local tpl = [[
require("bookmarks.list").load{
	_
}]]

    local local_str = ""
    local global_str = ""
    for id, data in pairs(data.bookmarks) do
        local sub = ""
        for k, v in pairs(data) do
            if sub ~= "" then
                sub = string.format("%s\n%s", sub, string.rep(" ", 4))
            end
            if type(v) == "number" or type(v) == "boolean" then
                sub = sub .. string.format("%s = %s,", k, v)
            else
                -- issue #37
                if config.sep_path == "\\" and k == "filename" then
                    v = string.gsub(v, "[\\]", "\\\\")
                end
                sub = sub .. string.format("%s = \"%s\",", k, v)
            end
        end

        if data["is_global"] ~= nil and data["is_global"] == true then -- global bookmarks
            if global_str == "" then
                global_str = string.format("%s%s", global_str, string.gsub(tpl, "_", sub))
            else
                global_str = string.format("%s\n%s", global_str, string.gsub(tpl, "_", sub))
            end
        else
            if local_str == "" then
                local_str = string.format("%s%s", local_str, string.gsub(tpl, "_", sub))
            else
                local_str = string.format("%s\n%s", local_str, string.gsub(tpl, "_", sub))
            end
        end
    end

    if data.data_filename == nil then -- lazy load,
        return
    end

    -- local bookmarks
    local local_fd = assert(io.open(data.data_filename, "w"))
    local_fd:write(local_str)
    local_fd:close()

    -- global bookmarks
    local global_file_name = config.storage_dir .. config.sep_path .. "bookmarks_global"
    local global_fd = assert(io.open(global_file_name, "w"))
    global_fd:write(global_str)
    global_fd:close()
end

-- Restore bookmarks from disk file.
function M.load_data()
    -- vim.notify("load bookmarks data", "info")
    -- windows issue #37
    local cwd
    if config.sep_path == "\\" then
        cwd = string.gsub(api.nvim_eval("getcwd()"), "[\\:]", "_")
    else
        cwd = string.gsub(api.nvim_eval("getcwd()"), config.sep_path, "_")
    end
    if data.cwd ~= nil and cwd ~= data.cwd then -- maybe change session
        M.persistent()
        data.bookmarks = {}
        data.loaded_data = false
    end

    if data.loaded_data == true then
        return
    end

    if not vim.loop.fs_stat(config.storage_dir) then
        assert(os.execute("mkdir " .. config.storage_dir))
    end

    -- local bookmarks
    local data_filename = string.format("%s%s%s", config.storage_dir, config.sep_path, cwd)
    if vim.loop.fs_stat(data_filename) then
        dofile(data_filename)
    end

    -- global bookmarks
    local global_data_filename = config.storage_dir .. config.sep_path .. "bookmarks_global"
    if vim.loop.fs_stat(global_data_filename) then
        dofile(global_data_filename)
    end

    data.cwd = cwd
    data.loaded_data = true -- mark
    data.data_dir = config.storage_dir
    data.data_filename = data_filename
end

-- Print bookmark descripiton.
function M.show_desc()
    local line = vim.fn.line(".")
    local filename = api.nvim_buf_get_name(0)
    local group = data.bookmarks_groupby_filename[filename]
    if group == nil then
        return
    end

    for _, each in pairs(group) do
        local bm = data.bookmarks[each]
        if bm ~= nil and bm.line == line then
            print(os.date("%Y-%m-%d %H:%M:%S", bm.updated_at), bm.description)
            return
        end
    end
end

-- Dofile
function M.load(item)
    data.bookmarks[item.id] = item

    if data.bookmarks_groupby_filename[item.filename] == nil then
        data.bookmarks_groupby_filename[item.filename] = {}
    end
    data.bookmarks_groupby_filename[item.filename][#data.bookmarks_groupby_filename[item.filename] + 1] = item.id

    if data.bookmarks_groupby_tags["ALL"] == nil then
        data.bookmarks_groupby_tags["ALL"] = {}
    end
    data.bookmarks_groupby_tags["ALL"][#data.bookmarks_groupby_tags["ALL"] + 1] = item.id

    if item.tags ~= nil and item.tags ~= "" then
        if data.bookmarks_groupby_tags[item.tags] == nil then
            data.bookmarks_groupby_tags[item.tags] = {}
        end
        data.bookmarks_groupby_tags[item.tags][#data.bookmarks_groupby_tags[item.tags] + 1] = item.id
    end
end

-- Character alignment.
function M.characters(utf8Str, aChineseCharBytes)
    aChineseCharBytes = aChineseCharBytes or 2
    local i = 1
    local characterSum = 0
    while (i <= #utf8Str) do -- 编码的关系
        local bytes4Character = M.bytes4Character(string.byte(utf8Str, i))
        characterSum = characterSum + (bytes4Character > aChineseCharBytes and aChineseCharBytes or bytes4Character)
        i = i + bytes4Character
    end

    return characterSum
end

-- Character alignment.
function M.bytes4Character(theByte)
    local seperate = { 0, 0xc0, 0xe0, 0xf0 }
    for i = #seperate, 1, -1 do
        if theByte >= seperate[i] then return i end
    end
    return 1
end

return M
