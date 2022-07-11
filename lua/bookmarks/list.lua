local md5 = require("bookmarks.md5")
local w = require("bookmarks.window")

local l = {
    data = {},
    order_ids = {},
    order = "time",
    is_windows = false,
    path_sep = "/",
    data_dir = nil,
    data_filename = nil,

    loaded_data = false,

    cwd = nil,
}

function l.setup()
    local os_name = vim.loop.os_uname().sysname
    l.is_windows = os_name == "Windows" or os_name == "Windows_NT"
    if l.is_windows then
        l.path_sep = "\\"
    end
end

function l.add(filename, line, description)
    l.load_data()

    local id = md5.sumhexa(string.format("%s:%s", filename, line))
    local now = os.time()
    if l.data[id] ~= nil then --update description
        if description ~= nil then
            l.data[id].description = description
            l.data[id].updated_at = now
        end
    else -- new
        l.data[id] = {
            filename = filename,
            id = id,
            line = line,
            description = description or "",
            updated_at = now,
            fre = 1
        }
    end
end

function l.delete(line)
    if l.order_ids[line] ~= nil then
        l.data[ l.order_ids[line] ] = nil
        l.refresh()
    end
end

function l.refresh(order)
    if order == true then
        if l.order == "time" then
            l.order = "fre"
        else
            l.order = "time"
        end
    end

    l.flush()
end

function l.flush()
    local tmp_data = {}
    for _, item in pairs(l.data) do
        tmp_data[#tmp_data + 1] = item
    end

    if l.order == "time" then
        table.sort(tmp_data, function(e1, e2)
            return e1.updated_at > e2.updated_at
        end)
    else
        table.sort(tmp_data, function(e1, e2)
            return e1.fre > e2.fre
        end)
    end

    l.order_ids = {}
    local lines = {}
    for _, item in ipairs(tmp_data) do
        local s = item.filename:split("/")
        local rep = math.floor(w.bw * 0.4)
        local icon = (require 'nvim-web-devicons'.get_icon(item.filename)) or ""

        local tmp = item.fre
        if l.order == "time" then
            tmp = os.date("%Y-%m-%d %H:%M:%S",item.updated_at)
        end

        lines[#lines + 1] = string.format("%s %s [%s]", l.padding(item.description, rep), icon .. " " .. s[#s], tmp)
        l.order_ids[#l.order_ids + 1] = item.id
    end

    vim.api.nvim_buf_set_option(w.bufb, "modifiable", true)
    -- empty
    vim.api.nvim_buf_set_lines(w.bufb, 0, -1, false, {})

    -- flush
    vim.api.nvim_buf_set_lines(w.bufb, 0, #lines, false, lines)
    vim.api.nvim_buf_set_option(w.bufb, "modifiable", false)
end

function l.padding(str, len)
    local tmp = l.characters(str, 2)
    if tmp > len then
        return string.sub(str, 0, len)
    else
        return str .. string.rep(" ", len - tmp)
    end
end

function l.jump(line)
    local item = l.data[ l.order_ids[line] ]

    l.data[ l.order_ids[line] ].fre = l.data[ l.order_ids[line] ].fre + 1
    l.data[ l.order_ids[line] ].updated_at = os.time()

    local fn = function(cmd)
        vim.cmd(cmd .. item.filename)
        vim.cmd("execute  \"normal! " .. item.line .. "G;zz\"")
        vim.cmd("execute  \"normal! zz\"")
    end

    local pre_buf_name = vim.api.nvim_buf_get_name(w.buff)
    if vim.loop.fs_stat(pre_buf_name) then
        vim.api.nvim_set_current_win(w.bufw)
        fn("e ")

        return
    else
        for _, id in pairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(id)
            if vim.loop.fs_stat(vim.api.nvim_buf_get_name(buf)) then
                vim.api.nvim_set_current_win(id)
                fn("e ")
                return
            end
        end
        fn("vs ")
    end
end

function l.load(data)
    l.data[data.id] = data
end

function l.persistent()
    local tpl = [[
require("bookmarks.list").load{
	_
}]]

    local str = ""
    for id, data in pairs(l.data) do
        local sub = ""
        for k, v in pairs(data) do
            if sub ~= "" then
                sub = string.format("%s\n%s", sub, string.rep(" ", 4))
            end
            if type(v) == "number" then
                sub = sub .. string.format("%s = %s,", k, v)
            else
                sub = sub .. string.format("%s = '%s',", k, v)
            end
        end
        if str == "" then
            str = string.format("%s%s", str, string.gsub(tpl, "_", sub))
        else
            str = string.format("%s\n%s", str, string.gsub(tpl, "_", sub))
        end
    end

    if l.data_filename == nil then -- lazy load,
        return
    end

    local fd = assert(io.open(l.data_filename, "w"))
    fd:write(str)
    fd:close()
end

function l.load_data()
    local cwd = string.gsub(vim.api.nvim_eval("getcwd()"), l.path_sep, "_")
    if l.cwd ~= nil and cwd ~= l.cwd then -- maybe change session
        l.persistent()
        l.data = {}
        l.loaded_data = false
    end

    if l.loaded_data == true then
        return
    end

    local data_dir = string.format("%s%sbookmarks", vim.fn.stdpath("data"), l.path_sep)
    if not vim.loop.fs_stat(data_dir) then
        assert(os.execute("mkdir " .. data_dir))
    end

    local data_filename = string.format("%s%s%s", data_dir, l.path_sep, cwd)
    if vim.loop.fs_stat(data_filename) then
        dofile(data_filename)
    end

    l.cwd = cwd
    l.loaded_data = true
    l.data_dir = data_dir
    l.data_filename = data_filename
end

function l.characters(utf8Str, aChineseCharBytes)
    aChineseCharBytes = aChineseCharBytes or 2
    local i = 1
    local characterSum = 0
    while (i <= #utf8Str) do -- 编码的关系
        local bytes4Character = l.bytes4Character(string.byte(utf8Str, i))
        characterSum = characterSum + (bytes4Character > aChineseCharBytes and aChineseCharBytes or bytes4Character)
        i = i + bytes4Character
    end

    return characterSum
end

function l.bytes4Character(theByte)
    local seperate = { 0, 0xc0, 0xe0, 0xf0 }
    for i = #seperate, 1, -1 do
        if theByte >= seperate[i] then return i end
    end
    return 1
end

return l
